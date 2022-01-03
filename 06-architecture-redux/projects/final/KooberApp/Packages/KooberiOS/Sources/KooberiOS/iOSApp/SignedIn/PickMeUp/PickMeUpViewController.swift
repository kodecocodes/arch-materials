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

enum PickMeUpView: Equatable {

  case initial
  case selectDropoffLocation
  case selectRideOption
  case confirmRequest
  case sendingRideRequest(NewRideRequest)
  case final
}

func mapToView(pickMeUpState: PickMeUpState, sendingState: NewRideRequestSendingState) -> PickMeUpView {
  switch sendingState {
  case .send(let rideRequest):
    return .sendingRideRequest(rideRequest)
  default:
    break
  }
  switch pickMeUpState {
  case .initial:
    return .initial
  case .selectDropoffLocation:
    return .selectDropoffLocation
  case let .selectRideOption(_, confirmingRequest):
    if confirmingRequest {
      return .confirmRequest
    } else {
      return .selectRideOption
    }
  case .final:
    return .final
  }
}

public class PickMeUpViewController: NiblessViewController {

  // MARK: - Properties
  // Child View Controllers
  let mapViewController: PickMeUpMapViewController
  let rideOptionPickerViewController: RideOptionPickerViewController
  let sendingRideRequestViewController: SendingRideRequestViewController

  // State
  let statePublisher: AnyPublisher<PickMeUpViewControllerState, Never>
  var subscriptions = Set<AnyCancellable>()

  // User Interactions
  let userInteractions: PickMeUpUserInteractions

  // Factories
  let viewControllerFactory: PickMeUpViewControllerFactory

  // Root View
  var rootView: PickMeUpRootView {
    return view as! PickMeUpRootView
  }

  // MARK: - Methods
  init(statePublisher: AnyPublisher<PickMeUpViewControllerState, Never>,
       userInteractions: PickMeUpUserInteractions,
       mapViewController: PickMeUpMapViewController,
       rideOptionPickerViewController: RideOptionPickerViewController,
       sendingRideRequestViewController: SendingRideRequestViewController,
       viewControllerFactory: PickMeUpViewControllerFactory) {
    self.statePublisher = statePublisher
    self.userInteractions = userInteractions
    self.mapViewController = mapViewController
    self.rideOptionPickerViewController = rideOptionPickerViewController
    self.sendingRideRequestViewController = sendingRideRequestViewController
    self.viewControllerFactory = viewControllerFactory
    super.init()
  }

  public override func loadView() {
    view = PickMeUpRootView(userInteractions: userInteractions)
  }

  public override func viewDidLoad() {
    addFullScreen(childViewController: mapViewController)

    super.viewDidLoad()

    observeState()
  }

  func observeState() {
    statePublisher
      .receive(on: DispatchQueue.main)
      .map { $0.shouldDisplayWhereTo }
      .removeDuplicates()
      .sink { [weak self] shouldDisplayWhereTo in
        if shouldDisplayWhereTo {
          self?.rootView.presentWhereToControl()
        } else {
          self?.rootView.dismissWhereToControl()
        }
      }
      .store(in: &subscriptions)

    statePublisher
      .receive(on: DispatchQueue.main)
      .map { (state: $0.state, sendingState: $0.sendingState) }
      .map (mapToView)
      .removeDuplicates()
      .sink { [weak self] view in
        self?.present(view)
      }
      .store(in: &subscriptions)

    statePublisher
      .receive(on: DispatchQueue.main)
      .map { $0.errorsToPresent }
      .removeDuplicates()
      .sink { [weak self] errorsToPresent in
        if let errorMessage = errorsToPresent.first {
          if let presentedViewController = self?.presentedViewController {
            presentedViewController.present(errorMessage: errorMessage) {
              self?.userInteractions.finishedPresentingNewRequestError(errorMessage)
            }
          } else {
            self?.present(errorMessage: errorMessage) {
              self?.userInteractions.finishedPresentingNewRequestError(errorMessage)
            }
          }
        }
      }
      .store(in: &subscriptions)
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
    case .sendingRideRequest(let rideRequest):
      presentSendingRideRequestScreen()
      userInteractions.send(rideRequest)
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
      button.addTarget(self,
                       action: #selector(confirmNewRideRequest),
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
      self?.userInteractions.finishedRequestingNewRide()
    }
  }

  @objc
  func confirmNewRideRequest() {
    userInteractions.confirmNewRideRequest()
  }
}

protocol PickMeUpViewControllerFactory {

  func makeDropoffLocationPickerViewController() -> DropoffLocationPickerViewController
}
