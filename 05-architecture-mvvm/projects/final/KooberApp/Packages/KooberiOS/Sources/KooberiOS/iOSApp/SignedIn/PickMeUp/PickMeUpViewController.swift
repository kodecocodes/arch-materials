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

public class PickMeUpViewController: NiblessViewController {

  // MARK: - Properties
  // View Model
  let viewModel: PickMeUpViewModel

  // Child View Controllers
  let mapViewController: PickMeUpMapViewController
  let rideOptionPickerViewController: RideOptionPickerViewController
  let sendingRideRequestViewController: SendingRideRequestViewController

  // State
  private var subscriptions = Set<AnyCancellable>()

  // Factories
  let viewControllerFactory: PickMeUpViewControllerFactory

  // MARK: - Methods
  init(viewModel: PickMeUpViewModel,
       mapViewController: PickMeUpMapViewController,
       rideOptionPickerViewController: RideOptionPickerViewController,
       sendingRideRequestViewController: SendingRideRequestViewController,
       viewControllerFactory: PickMeUpViewControllerFactory) {
    self.viewModel = viewModel
    self.mapViewController = mapViewController
    self.rideOptionPickerViewController = rideOptionPickerViewController
    self.sendingRideRequestViewController = sendingRideRequestViewController
    self.viewControllerFactory = viewControllerFactory
    super.init()
  }

  public override func loadView() {
    view = PickMeUpRootView(viewModel: viewModel)
  }

  public override func viewDidLoad() {
    addFullScreen(childViewController: mapViewController)
    super.viewDidLoad()
    subscribe(to: viewModel.$view.eraseToAnyPublisher())
    observeErrorMessages()
  }

  func subscribe(to publisher: AnyPublisher<PickMeUpView, Never>) {
    publisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] view in
        self?.present(view)
      }.store(in: &subscriptions)
  }

  func present(_ view: PickMeUpView) {
    switch view {
    case .initial:
      presentInitialState()
    case .selectDropoffLocation:
      presentDropoffLocationPicker()
    case .selectRideOption:
      dropoffLocationSelected()
    case .confirmRequest:
      presentConfirmControl()
    case .sendingRideRequest:
      presentSendingRideRequestScreen()
    case .final:
      dismissSendingRideRequestScreen()
    }
  }

  public override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    mapViewController.view.frame = view.bounds
  }

  public override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  func presentInitialState() {
    if let _ = presentedViewController as? DropoffLocationPickerViewController {
      dismiss(animated: true)
    }
    remove(childViewController: rideOptionPickerViewController)
    confirmControl?.removeFromSuperview()
    confirmControl = nil
  }

  func presentWhereTo() {
    if let view = view as? PickMeUpRootView {
      view.presentWhereToControl()
    }
  }

  func presentDropoffLocationPicker() {
    let viewController = viewControllerFactory.makeDropoffLocationPickerViewController()
    present(viewController, animated: true)
  }

  func dropoffLocationSelected() {
    if presentedViewController is DropoffLocationPickerViewController {
      dismiss(animated: true)
    }
    presentRideOptionPicker()
  }

  func dismissWhereTo() {
    if let view = view as? PickMeUpRootView {
      view.dismissWhereToControl()
    }
  }

  func presentRideOptionPicker() {
    let child = rideOptionPickerViewController
    guard child.parent == nil else {
      return
    }

    addChild(child)
    child.view.frame = CGRect(x: 0,
                              y: view.bounds.maxY - 140,
                              width: view.bounds.width,
                              height: 140)
    view.addSubview(child.view)
    child.didMove(toParent: self)
  }

  var confirmControl: UIButton?

  func presentConfirmControl() {
    if let _ = presentedViewController {
      dismiss(animated: true, completion: nil)
    }
    guard confirmControl.isEmpty else {
      return
    }
    
    let buttonBackground: UIView = {
      let background = UIView()
      background.backgroundColor = Color.background
      background.frame = CGRect(x: 0,
                                y: rideOptionPickerViewController.view.frame.maxY,
                                width: self.view.bounds.width,
                                height: 70)
      return background
    }()

    let button: UIButton = {
      let button = UIButton(type: .system)
      button.backgroundColor = Color.lightButtonBackground
      button.setTitle("Confirm", for: .normal)
      button.frame = CGRect(x: 20,
                            y: rideOptionPickerViewController.view.frame.maxY,
                            width: self.view.bounds.width - 40,
                            height: 50)
      button.addTarget(viewModel,
                       action: #selector(PickMeUpViewModel.sendRideRequest),
                       for: .touchUpInside)
      button.titleLabel?.font = .boldSystemFont(ofSize: 18)
      button.setTitleColor(.white, for: .normal)
      button.layer.cornerRadius = 3
      return button
    }()

    view.addSubview(buttonBackground)
    view.addSubview(button)

    UIView.animate(withDuration: 0.7) {
      var rideOptionPickerFrame = self.rideOptionPickerViewController.view.frame
      rideOptionPickerFrame.origin.y -= 70
      self.rideOptionPickerViewController.view.frame = rideOptionPickerFrame

      var confirmControlFrame = button.frame
      confirmControlFrame.origin.y -= 70
      button.frame = confirmControlFrame
      
      var backgroundFrame = buttonBackground.frame
      backgroundFrame.origin.y -= 70
      buttonBackground.frame = backgroundFrame
    }

    self.confirmControl = button
  }

  func presentSendingRideRequestScreen() {
    sendingRideRequestViewController.modalPresentationStyle = .fullScreen
    present(sendingRideRequestViewController, animated: true)
  }

  func dismissSendingRideRequestScreen() {
    view.alpha = 0
    dismiss(animated: true) { [weak self] in
      self?.viewModel.finishedSendingNewRideRequest()
    }
  }

  func observeErrorMessages() {
    viewModel
      .errorMessages
      .receive(on: DispatchQueue.main)
      .sink { [weak self] errorMessage in
        self?.routePresentation(forErrorMessage: errorMessage)
      }.store(in: &subscriptions)
  }

  func routePresentation(forErrorMessage errorMessage: ErrorMessage) {
    if let presentedViewController = presentedViewController {
      presentedViewController.present(errorMessage: errorMessage,
                                      withPresentationState: viewModel.errorPresentation)
    } else {
      present(errorMessage: errorMessage,
              withPresentationState: viewModel.errorPresentation)
    }
  }
}

extension Optional {

  var isEmpty: Bool {
    return self == nil
  }

  var exists: Bool {
    return self != nil
  }
}

protocol PickMeUpViewControllerFactory {
  
  func makeDropoffLocationPickerViewController() -> DropoffLocationPickerViewController
}
