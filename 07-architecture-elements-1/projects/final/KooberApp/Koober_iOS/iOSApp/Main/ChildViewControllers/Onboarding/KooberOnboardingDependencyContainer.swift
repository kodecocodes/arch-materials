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
    let observer = ObserverForOnboarding(onboardingState: statePublisher)
    let welcomeViewController = makeWelcomeViewController()
    let signInViewController = makeSignInViewController()
    let signUpViewController = makeSignUpViewController()
    let navigatedBackToWelcomeUseCaseFactory = self

    let onboardingViewController =
      OnboardingViewController(
        observer: observer,
        welcomeViewController: welcomeViewController,
        signInViewController: signInViewController,
        signUpViewController: signUpViewController,
        navigatedBackToWelcomeUseCaseFactory: navigatedBackToWelcomeUseCaseFactory
      )
    observer.eventResponder = onboardingViewController

    return onboardingViewController
  }

  public func makeOnboardingStatePublisher() -> AnyPublisher<OnboardingState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.appRunningGetters.getOnboardingState)
        }
    return statePublisher
  }

  // Welcome
  public func makeWelcomeViewController() -> WelcomeViewController {
    let userInterface = WelcomeRootView()
    let goToSignInUseCaseFactory = self
    let goToSignUpUseCaseFactory = self

    let welcomeViewController =
      WelcomeViewController(
        userInterface: userInterface,
        goToSignInUseCaseFactory: goToSignInUseCaseFactory,
        goToSignUpUseCaseFactory: goToSignUpUseCaseFactory
      )
    userInterface.ixResponder = welcomeViewController

    return welcomeViewController
  }

  public func makeSignInViewController() -> SignInViewController {
    // User interface element
    let userInterface = SignInRootView()
    
    // Observer element
    let statePublisher = makeSignInViewControllerStatePublisher()
    let observer = ObserverForSignIn(signInState: statePublisher)
    
    // Use case element
    let signInUseCaseFactory = self
    let finishedPresentingErrorUseCaseFactory = self.makeFinishedPresentingSignInErrorUseCase

    let signInViewController =
      SignInViewController(
        userInterface: userInterface,
        observer: observer,
        signInUseCaseFactory: signInUseCaseFactory,
        finishedPresentingErrorUseCaseFactory: finishedPresentingErrorUseCaseFactory
      )
    
    // Wire responders
    userInterface.ixResponder = signInViewController
    observer.eventResponder = signInViewController

    return signInViewController
  }

  public func makeSignInViewControllerStatePublisher() -> AnyPublisher<SignInViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.onboardingGetters.getSignInViewControllerState)
        }
    return statePublisher
  }

  public func makeFinishedPresentingSignInErrorUseCase(
    errorMessage: ErrorMessage
  ) -> UseCase {
    let actionDispatcher = self.actionDispatcher

    let useCase =
      FinishedPresentingErrorUseCaseFactories
        .makeFinishedPresentingSignInErrorUseCase(
          errorMessage: errorMessage,
          actionDispatcher: actionDispatcher
        )
    return useCase
  }

  // Sign Up
  public func makeSignUpViewController() -> SignUpViewController {
    let userInterface = SignUpRootView()
    let statePublisher = makeSignUpViewControllerStatePublisher()
    let observer = ObserverForSignUp(signInState: statePublisher)
    let signUpUseCaseFactory = self
    let finishedPresentingErrorUseCaseFactory = self.makeFinishedPresentingSignUpErrorUseCase

    let signUpViewController =
      SignUpViewController(
        observer: observer,
        userInterface: userInterface,
        signUpUseCaseFactory: signUpUseCaseFactory,
        finishedPresentingErrorUseCaseFactory: finishedPresentingErrorUseCaseFactory
      )
    userInterface.ixResponder = signUpViewController
    observer.eventResponder = signUpViewController
    
    return signUpViewController
  }

  public func makeSignUpViewControllerStatePublisher() -> AnyPublisher<SignUpViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.onboardingGetters.getSignUpViewControllerState)
        }
    return statePublisher
  }

  public func makeFinishedPresentingSignUpErrorUseCase(errorMessage: ErrorMessage) -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase =
      FinishedPresentingErrorUseCaseFactories
        .makeFinishedPresentingSignUpErrorUseCase(
          errorMessage: errorMessage,
          actionDispatcher: actionDispatcher
        )
    return useCase
  }

  // Shared
  public func makeAuthRemoteAPI() -> AuthRemoteAPI {
    return FakeAuthRemoteAPI()
  }
}

extension KooberOnboardingDependencyContainer: NavigatedBackToWelcomeUseCaseFactory {

  public func makeNavigatedBackToWelcomeUseCase() -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase = NavigatedBackToWelcomeUseCase(actionDispatcher: actionDispatcher)
    return useCase
  }
}

extension KooberOnboardingDependencyContainer: GoToSignInUseCaseFactory {

  public func makeGoToSignInUseCase() -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase = GoToSignInUseCase(actionDispatcher: actionDispatcher)
    return useCase
  }
}

extension KooberOnboardingDependencyContainer: GoToSignUpUseCaseFactory {

  public func makeGoToSignUpUseCase() -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase = GoToSignUpUseCase(actionDispatcher: actionDispatcher)
    return useCase
  }
}

extension KooberOnboardingDependencyContainer: SignInUseCaseFactory {

  public func makeSignInUseCase(
    username: String,
    password: Secret
  ) -> UseCase {
    let authRemoteAPI = self.makeAuthRemoteAPI()
    let actionDispatcher = self.actionDispatcher

    let useCase = SignInUseCase(username: username,
                                password: password,
                                remoteAPI: authRemoteAPI,
                                actionDispatcher: actionDispatcher)
    return useCase
  }
}

extension KooberOnboardingDependencyContainer: SignUpUseCaseFactory {

  public func makeSignUpUseCase(newAccount: NewAccount) -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let authRemoteAPI = makeAuthRemoteAPI()
    let useCase = SignUpUseCase(newAccount: newAccount,
                                remoteAPI: authRemoteAPI,
                                actionDispatcher: actionDispatcher)
    return useCase
  }
}
