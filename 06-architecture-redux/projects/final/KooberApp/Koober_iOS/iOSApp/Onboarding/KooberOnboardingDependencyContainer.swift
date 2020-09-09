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
import Combine
import ReSwift

public class KooberOnboardingDependencyContainer {

  // MARK: - Properties

  // From parent container
  let appRunningGetters: AppRunningGetters
  let actionDispatcher: ActionDispatcher
  let stateStore: Store<AppState>

  let onboardingGetters: OnboardingGetters

  // MARK: - Methods
  init(appContainer: KooberAppDependencyContainer) {
    self.appRunningGetters = appContainer.appRunningGetters
    self.actionDispatcher = appContainer.stateStore
    self.stateStore = appContainer.stateStore
    self.onboardingGetters = OnboardingGetters(getOnboardingState: appRunningGetters.getOnboardingState)
  }

  // Onboarding
  public func makeOnboardingViewController() -> OnboardingViewController {
    let statePublisher = makeOnboardingStatePublisher()
    let userInteractions = makeOnboardingUserInteractions()
    let welcomeViewController = makeWelcomeViewController()
    let signInViewController = makeSignInViewController()
    let signUpViewController = makeSignUpViewController()
    return OnboardingViewController(statePublisher: statePublisher,
                                    userInteractions: userInteractions,
                                    welcomeViewController: welcomeViewController,
                                    signInViewController: signInViewController,
                                    signUpViewController: signUpViewController)
  }

  public func makeOnboardingStatePublisher() -> AnyPublisher<OnboardingState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.appRunningGetters.getOnboardingState)
        }
    return statePublisher
  }

  public func makeOnboardingUserInteractions() -> OnboardingUserInteractions {
    return ReduxOnboardingUserInteractions(actionDispatcher: actionDispatcher)
  }

  // Welcome
  public func makeWelcomeViewController() -> WelcomeViewController {
    let userInteractions = makeWelcomeUserInteractions()
    return WelcomeViewController(userInteractions: userInteractions)
  }

  public func makeWelcomeUserInteractions() -> WelcomeUserInteractions {
    return ReduxWelcomeUserInteractions(actionDispatcher: actionDispatcher)
  }

  // Sign In
  public func makeSignInViewController() -> SignInViewController {
    let statePublisher = makeSignInViewControllerStatePublisher()
    let userInteractions = makeSignInUserInteractions()
    return SignInViewController(state: statePublisher,
                                userInteractions: userInteractions)
  }

  public func makeSignInViewControllerStatePublisher() -> AnyPublisher<SignInViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.onboardingGetters.getSignInViewControllerState)
        }
    return statePublisher
  }

  public func makeSignInUserInteractions() -> SignInUserInteractions {
    let authRemoteAPI = makeAuthRemoteAPI()
    return ReduxSignInUserInteractions(actionDispatcher: actionDispatcher,
                                       remoteAPI: authRemoteAPI)
  }

  // Sign Up
  public func makeSignUpViewController() -> SignUpViewController {
    let statePublisher = makeSignUpViewControllerStatePublisher()
    let userInteractions = makeSignUpUserInteractions()
    return SignUpViewController(statePublisher: statePublisher,
                                userInteractions: userInteractions)
  }

  public func makeSignUpViewControllerStatePublisher() -> AnyPublisher<SignUpViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.onboardingGetters.getSignUpViewControllerState)
        }
    return statePublisher
  }

  public func makeSignUpUserInteractions() -> SignUpUserInteractions {
    let authRemoteAPI = makeAuthRemoteAPI()
    return ReduxSignUpUserInteractions(actionDispatcher: actionDispatcher,
                                       remoteAPI: authRemoteAPI)
  }

  // Shared
  public func makeAuthRemoteAPI() -> AuthRemoteAPI {
    return FakeAuthRemoteAPI()
  }
}
