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
import KooberUIKit
import PromiseKit
import KooberKit
import Combine

public class OnboardingViewController: NiblessNavigationController {
  
  // MARK: - Properties
  // View Model
  let viewModel: OnboardingViewModel
  var subscriptions = Set<AnyCancellable>()

  // Child View Controllers
  let welcomeViewController: WelcomeViewController
  let signInViewController: SignInViewController
  let signUpViewController: SignUpViewController

  // MARK: - Methods
  init(viewModel: OnboardingViewModel,
       welcomeViewController: WelcomeViewController,
       signInViewController: SignInViewController,
       signUpViewController: SignUpViewController) {
    self.viewModel = viewModel
    self.welcomeViewController = welcomeViewController
    self.signInViewController = signInViewController
    self.signUpViewController = signUpViewController
    super.init()
    self.delegate = self
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    let navigationActionPublisher = viewModel.$navigationAction.eraseToAnyPublisher()
    subscribe(to: navigationActionPublisher)
  }

  func subscribe(to publisher: AnyPublisher<OnboardingNavigationAction, Never>) {
    publisher
      .receive(on: DispatchQueue.main)
      .removeDuplicates()
      .sink { [weak self] action in
        guard let strongSelf = self else { return }
        strongSelf.respond(to: action)
      }.store(in: &subscriptions)
  }

  func respond(to navigationAction: OnboardingNavigationAction) {
    switch navigationAction {
    case .present(let view):
      present(view: view)
    case .presented:
      break
    }
  }

  func present(view: OnboardingView) {
    switch view {
    case .welcome:
      presentWelcome()
    case .signin:
      presentSignIn()
    case .signup:
      presentSignUp()
    }
  }

  func presentWelcome() {
    pushViewController(welcomeViewController, animated: false)
  }

  func presentSignIn() {
    pushViewController(signInViewController, animated: true)
  }

  func presentSignUp() {
    pushViewController(signUpViewController, animated: true)
  }
}

// MARK: - Navigation Bar Presentation
extension OnboardingViewController {

  func hideOrShowNavigationBarIfNeeded(for view: OnboardingView, animated: Bool) {
    if view.hidesNavigationBar() {
      hideNavigationBar(animated: animated)
    } else {
      showNavigationBar(animated: animated)
    }
  }

  func hideNavigationBar(animated: Bool) {
    if animated {
      transitionCoordinator?.animate(alongsideTransition: { context in
        self.setNavigationBarHidden(true, animated: animated)
      })
    } else {
      setNavigationBarHidden(true, animated: false)
    }
  }

  func showNavigationBar(animated: Bool) {
    if self.isNavigationBarHidden {
      self.setNavigationBarHidden(false, animated: animated)
    }
  }
}

// MARK: - UINavigationControllerDelegate
extension OnboardingViewController: UINavigationControllerDelegate {

  public func navigationController(_ navigationController: UINavigationController,
                                   willShow viewController: UIViewController,
                                   animated: Bool) {
    guard let viewToBeShown = onboardingView(associatedWith: viewController) else { return }
    hideOrShowNavigationBarIfNeeded(for: viewToBeShown, animated: animated)
  }

  public func navigationController(_ navigationController: UINavigationController,
                                   didShow viewController: UIViewController,
                                   animated: Bool) {
    guard let shownView = onboardingView(associatedWith: viewController) else { return }
    viewModel.uiPresented(onboardingView: shownView)
  }
}

extension OnboardingViewController {
  
  func onboardingView(associatedWith viewController: UIViewController) -> OnboardingView? {
    switch viewController {
    case is WelcomeViewController:
      return .welcome
    case is SignInViewController:
      return .signin
    case is SignUpViewController:
      return .signup
    default:
      assertionFailure("Encountered unexpected child view controller type in OnboardingViewController")
      return nil
    }
  }
}
