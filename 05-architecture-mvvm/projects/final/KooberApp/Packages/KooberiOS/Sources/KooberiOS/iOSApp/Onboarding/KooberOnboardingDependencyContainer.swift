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

public class KooberOnboardingDependencyContainer {

  // MARK: - Properties

  // From parent container
  let sharedUserSessionRepository: UserSessionRepository
  let sharedMainViewModel: MainViewModel

  // Long-lived dependencies
  let sharedOnboardingViewModel: OnboardingViewModel

  // MARK: - Methods
  init(appDependencyContainer: KooberAppDependencyContainer) {
    func makeOnboardingViewModel() -> OnboardingViewModel {
      return OnboardingViewModel()
    }

    self.sharedUserSessionRepository = appDependencyContainer.sharedUserSessionRepository
    self.sharedMainViewModel = appDependencyContainer.sharedMainViewModel

    self.sharedOnboardingViewModel = makeOnboardingViewModel()
  }

  // On-boarding (signed-out)
  // Factories needed to create an OnboardingViewController.
  public func makeOnboardingViewController() -> OnboardingViewController {
    let welcomeViewController = makeWelcomeViewController()
    let signInViewController = makeSignInViewController()
    let signUpViewController = makeSignUpViewController()
    return OnboardingViewController(viewModel: sharedOnboardingViewModel,
                                    welcomeViewController: welcomeViewController,
                                    signInViewController: signInViewController,
                                    signUpViewController: signUpViewController)
  }

  // Welcome
  public func makeWelcomeViewController() -> WelcomeViewController {
    return WelcomeViewController(welcomeViewModelFactory: self)
  }

  public func makeWelcomeViewModel() -> WelcomeViewModel {
    return WelcomeViewModel(goToSignUpNavigator: sharedOnboardingViewModel,
                            goToSignInNavigator: sharedOnboardingViewModel)
  }

  // Sign In
  public func makeSignInViewController() -> SignInViewController {
    return SignInViewController(viewModelFactory: self)
  }

  public func makeSignInViewModel() -> SignInViewModel {
    return SignInViewModel(userSessionRepository: sharedUserSessionRepository,
                           signedInResponder: sharedMainViewModel)
  }

  // Sign Up
  public func makeSignUpViewController() -> SignUpViewController {
    return SignUpViewController(viewModelFactory: self)
  }

  public func makeSignUpViewModel() -> SignUpViewModel {
    return SignUpViewModel(userSessionRepository: sharedUserSessionRepository,
                           signedInResponder: sharedMainViewModel)
  }
}

extension KooberOnboardingDependencyContainer: WelcomeViewModelFactory, SignInViewModelFactory, SignUpViewModelFactory {}
