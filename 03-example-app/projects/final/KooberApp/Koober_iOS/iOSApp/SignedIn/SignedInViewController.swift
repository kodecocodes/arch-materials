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
import KooberKit
import Combine

public class SignedInViewController: NiblessViewController {
  
  // MARK: - Properties
  // View Model
  let viewModel: SignedInViewModel

  // Child View Controllers
  let profileViewController: ProfileViewController
  var currentChildViewController: UIViewController?

  // State
  let userSession: UserSession
  private var subscriptions = Set<AnyCancellable>()

  // Factories
  let viewControllerFactory: SignedInViewControllerFactory

  // MARK: - Methods
  init(viewModel: SignedInViewModel,
       userSession: UserSession,
       profileViewController: ProfileViewController,
       viewControllerFactory: SignedInViewControllerFactory) {
    self.viewModel = viewModel
    self.userSession = userSession
    self.profileViewController = profileViewController
    self.viewControllerFactory = viewControllerFactory
    super.init()
  }

  public override func loadView() {
    view = SignedInRootView(viewModel: viewModel)
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    subscribe(to: viewModel.$view.eraseToAnyPublisher())
    bindToShowingProfileState()
  }

  func bindToShowingProfileState() {
    viewModel
      .$showingProfileScreen
      .receive(on: DispatchQueue.main)
      .removeDuplicates()
      .sink { [weak self] showingProfileScreen in
        guard let strongSelf = self else {
          return
        }
        strongSelf.update(showingProfileScreen: showingProfileScreen)
      }.store(in: &subscriptions)
  }

  func update(showingProfileScreen: Bool) {
    if showingProfileScreen {
      if presentedViewController.isEmpty {
        present(profileViewController, animated: true)
      }
    } else {
      if profileViewController.view.window != nil {
        dismiss(animated: true)
      }
    }
  }

  func subscribe(to publisher: AnyPublisher<SignedInView, Never>) {
    publisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] view in
        guard let strongSelf = self else {
          return
        }
        strongSelf.present(view)
      }.store(in: &subscriptions)
  }

  func present(_ view: SignedInView) {
    switch view {
    case .gettingUsersLocation:
      let viewController = viewControllerFactory.makeGettingUsersLocationViewController()
      transition(to: viewController)
    case .pickMeUp(let pickupLocation):
      let viewController = viewControllerFactory.makePickMeUpViewController(pickupLocation: pickupLocation)
      transition(to: viewController)
    case .waitingForPickup:
      let viewController = viewControllerFactory.makeWaitingForPickupViewController()
      transition(to: viewController)
    }
  }

  public override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    currentChildViewController?.view.frame = view.bounds
  }

  func transition(to viewController: UIViewController) {
    remove(childViewController: currentChildViewController)
    addFullScreen(childViewController: viewController)
    currentChildViewController = viewController
  }
}

protocol SignedInViewControllerFactory {
  
  func makeGettingUsersLocationViewController() -> GettingUsersLocationViewController
  func makePickMeUpViewController(pickupLocation: Location) -> PickMeUpViewController
  func makeWaitingForPickupViewController() -> WaitingForPickupViewController
}
