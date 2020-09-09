/// Copyright (c) 2020 Razeware LLC
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

public class KooberAppDependencyContainer {

  // MARK: - Properties

  // Long-lived dependencies
  let sharedUserSessionRepository: UserSessionRepository
  let sharedMainViewModel: MainViewModel

  // MARK: - Methods
  public init() {
    func makeUserSessionRepository() -> UserSessionRepository {
      let dataStore = makeUserSessionDataStore()
      let remoteAPI = makeAuthRemoteAPI()
      return KooberUserSessionRepository(dataStore: dataStore,
                                         remoteAPI: remoteAPI)
    }

    func makeUserSessionDataStore() -> UserSessionDataStore {
      #if USER_SESSION_DATASTORE_FILEBASED
      return FileUserSessionDataStore()

      #else
      let coder = makeUserSessionCoder()
      return KeychainUserSessionDataStore(userSessionCoder: coder)
      #endif
    }

    func makeUserSessionCoder() -> UserSessionCoding {
      return UserSessionPropertyListCoder()
    }

    func makeAuthRemoteAPI() -> AuthRemoteAPI {
      return FakeAuthRemoteAPI()
    }

    // Because `MainViewModel` is a concrete type
    //  and because `MainViewModel`'s initializer has no parameters,
    //  you don't need this inline factory method,
    //  you can also initialize the `sharedMainViewModel` property
    //  on the declaration line like this:
    //  `let sharedMainViewModel = MainViewModel()`.
    //  Which option to use is a style preference.
    func makeMainViewModel() -> MainViewModel {
      return MainViewModel()
    }

    self.sharedUserSessionRepository = makeUserSessionRepository()
    self.sharedMainViewModel = makeMainViewModel()
  }

  // Main
  // Factories needed to create a MainViewController.

  public func makeMainViewController() -> MainViewController {
    let launchViewController = makeLaunchViewController()

    let onboardingViewControllerFactory = {
      return self.makeOnboardingViewController()
    }

    let signedInViewControllerFactory = { (userSession: UserSession) in
      return self.makeSignedInViewController(session: userSession)
    }

    return MainViewController(viewModel: sharedMainViewModel,
                              launchViewController: launchViewController,
                              onboardingViewControllerFactory: onboardingViewControllerFactory,
                              signedInViewControllerFactory: signedInViewControllerFactory)
  }

  // Launching

  public func makeLaunchViewController() -> LaunchViewController {
    return LaunchViewController(launchViewModelFactory: self)
  }

  public func makeLaunchViewModel() -> LaunchViewModel {
    return LaunchViewModel(userSessionRepository: sharedUserSessionRepository,
                           notSignedInResponder: sharedMainViewModel,
                           signedInResponder: sharedMainViewModel)
  }

  // Onboarding (signed-out)
  // Factories needed to create an OnboardingViewController.

  public func makeOnboardingViewController() -> OnboardingViewController {
    let dependencyContainer = KooberOnboardingDependencyContainer(appDependencyContainer: self)
    return dependencyContainer.makeOnboardingViewController()
  }

  // Signed-in

  public func makeSignedInViewController(session: UserSession) -> SignedInViewController {
    let dependencyContainer = makeSignedInDependencyContainer(session: session)
    return dependencyContainer.makeSignedInViewController()
  }

  public func makeSignedInDependencyContainer(session: UserSession) -> KooberSignedInDependencyContainer  {
    return KooberSignedInDependencyContainer(userSession: session, appDependencyContainer: self)
  }
}

extension KooberAppDependencyContainer: LaunchViewModelFactory {}
