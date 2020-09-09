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

public class MainViewController: NiblessViewController {

  // MARK: - Properties
  // Child View Controllers
  let launchViewController: LaunchViewController
  var signedInViewController: SignedInViewController?
  var onboardingViewController: OnboardingViewController?

  // State
  let statePublisher: AnyPublisher<AppState, Never>
  var subscriptions = Set<AnyCancellable>()

  // Factories
  let makeOnboardingViewController: () -> OnboardingViewController
  let makeSignedInViewController: (UserSession) -> SignedInViewController

  // MARK: - Methods
  public init(statePublisher: AnyPublisher<AppState, Never>,
              launchViewController: LaunchViewController,
              onboardingViewControllerFactory: @escaping () -> OnboardingViewController,
              signedInViewControllerFactory: @escaping (UserSession) -> SignedInViewController) {
    self.statePublisher = statePublisher
    self.launchViewController = launchViewController
    self.makeOnboardingViewController = onboardingViewControllerFactory
    self.makeSignedInViewController = signedInViewControllerFactory
    super.init()
  }

  func observeState() {
    statePublisher
      .receive(on: DispatchQueue.main)
      .map(MainViewControllerState.mainViewControllerState(fromAppState:))
      .removeDuplicates()
      .sink { [weak self] viewControllerState in
        self?.present(viewControllerState)
      }
      .store(in: &subscriptions)
  }

  func present(_ state: MainViewControllerState) {
    switch state {
    case .launching:
      presentLaunching()
    case .onboarding:
      if onboardingViewController?.presentingViewController == nil {
        if presentedViewController.exists {
          // Dismiss profile modal when signing out.
          dismiss(animated: true) { [weak self] in
            self?.presentOnboarding()
          }
        } else {
          presentOnboarding()
        }
      }
    case .signedIn(let userSession):
      presentSignedIn(userSession: userSession)
    }
  }

  public func presentLaunching() {
    addFullScreen(childViewController: launchViewController)
  }

  public func presentOnboarding() {
    let onboardingViewController = makeOnboardingViewController()
    onboardingViewController.modalPresentationStyle = .fullScreen
    present(onboardingViewController, animated: true) { [weak self] in
      guard let self = self else {
        return
      }

      self.remove(childViewController: self.launchViewController)
      if let signedInViewController = self.signedInViewController {
        self.remove(childViewController: signedInViewController)
        self.signedInViewController = nil
      }
    }
    self.onboardingViewController = onboardingViewController
  }

  public func presentSignedIn(userSession: UserSession) {
    remove(childViewController: launchViewController)

    let signedInViewControllerToPresent: SignedInViewController
    if let vc = self.signedInViewController {
      signedInViewControllerToPresent = vc
    } else {
      signedInViewControllerToPresent = makeSignedInViewController(userSession)
      self.signedInViewController = signedInViewControllerToPresent
    }

    addFullScreen(childViewController: signedInViewControllerToPresent)

    if onboardingViewController?.presentingViewController != nil {
      onboardingViewController = nil
      dismiss(animated: true)
    }
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    observeState()
  }
}
