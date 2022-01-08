/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import KooberKit
import ReSwift
import Combine

public class KooberAppDependencyContainer {

  // MARK: - Properties
  let userSessionDataStore: UserSessionDataStore
  let stateStore: Store<AppState> = {
    return Store(reducer: Reducers.appReducer,
                 state: .launching(LaunchViewControllerState()),
                 middleware: []) // printActionMiddleware
  }()
  let entryPointGetters = EntryPointGetters()
  let appRunningGetters: AppRunningGetters
  let userSessionStatePersister: UserSessionStatePersister

  // MARK: - Methods
  public init() {
    func makeUserSessionDataStore() -> UserSessionDataStore {
      let userSessionCoder: UserSessionCoding = UserSessionPropertyListCoder()
      return KeychainUserSessionDataStore(userSessionCoder: userSessionCoder)
    }
    self.userSessionDataStore = makeUserSessionDataStore()
    self.appRunningGetters = AppRunningGetters(getAppRunningState: entryPointGetters.getAppRunningState)
    self.userSessionStatePersister = ReduxUserSessionStatePersister(reduxStore: stateStore)
  }

  // Main
  public func makeMainViewController() -> MainViewController {
    let statePublisher = makeAppStatePublisher()
    let launchViewController = makeLaunchViewController()
    let onboardingViewControllerFactory = {
      // `self` is the app dependency container which lives as long
      //  as the app's process. `self` does not hold on to the
      //  view controller created in this closure.
      //  Therefore, it's ok to capture strong `self` here.
      return self.makeOnboardingViewController()
    }
    let signedInViewControllerFactory = { (userSession: UserSession) in
      // `self` is the app dependency container which lives as long
      //  as the app's process. `self` does not hold on to the
      //  view controller created in this closure.
      //  Therefore, it's ok to capture strong `self` here.
      return self.makeSignedInViewController(session: userSession)
    }
    return MainViewController(statePublisher: statePublisher,
                              launchViewController: launchViewController,
                              onboardingViewControllerFactory: onboardingViewControllerFactory,
                              signedInViewControllerFactory: signedInViewControllerFactory)
  }

  public func makeAppStatePublisher() -> AnyPublisher<AppState, Never> {
    return stateStore.publisher()
  }

  // Launching
  public func makeLaunchViewController() -> LaunchViewController {
    let userInteractions = makeLaunchingUserInteractions()
    let statePublisher = makeLaunchViewControllerStatePublisher()
    return LaunchViewController(statePublisher: statePublisher,
                                userInteractions: userInteractions)
  }

  public func makeLaunchingUserInteractions() -> LaunchingUserInteractions {
    let actionDispatcher: ActionDispatcher = stateStore
    return ReduxLaunchingUserInteractions(actionDispatcher: actionDispatcher,
                                          userSessionDataStore: userSessionDataStore,
                                          userSessionStatePersister: userSessionStatePersister)
  }

  public func makeLaunchViewControllerStatePublisher() -> AnyPublisher<LaunchViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.entryPointGetters.getLaunchViewControllerState)
        }
    return statePublisher
  }

  // Onboarding (signed-out)
  public func makeOnboardingViewController() -> OnboardingViewController {
    let dependencyContainer = KooberOnboardingDependencyContainer(appContainer: self)
    return dependencyContainer.makeOnboardingViewController()
  }

  // Signed-in
  public func makeSignedInViewController(session: UserSession) -> SignedInViewController {
    let dependencyContainer = makeSignedInContainer(session: session)
    return dependencyContainer.makeSignedInViewController()
  }

  public func makeSignedInContainer(session: UserSession) -> KooberSignedInDependencyContainer  {
    return KooberSignedInDependencyContainer(userSession: session, appContainer: self)
  }
}
