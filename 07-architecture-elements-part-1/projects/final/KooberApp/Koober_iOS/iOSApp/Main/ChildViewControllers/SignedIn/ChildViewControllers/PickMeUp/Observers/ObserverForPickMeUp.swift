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

import Foundation
import KooberKit
import Combine


class ObserverForPickMeUp: Observer {

  // MARK: - Properties
  weak var eventResponder: ObserverForPickMeUpEventResponder? {
    willSet {
      if newValue == nil {
        stopObserving()
      }
    }
  }

  let pickMeUpState: AnyPublisher<PickMeUpViewControllerState, Never>
  var shouldDisplayWhereToStateSubscription: AnyCancellable?
  var pickMeUpViewStateSubscription: AnyCancellable?
  var errorStateSubscription: AnyCancellable?

  private var isObserving: Bool {
    if shouldDisplayWhereToStateSubscription != nil
      && pickMeUpViewStateSubscription != nil
      && errorStateSubscription != nil
    {
      return true
    } else {
      return false
    }
  }

  // MARK: - Methods
  init(pickMeUpState: AnyPublisher<PickMeUpViewControllerState, Never>) {
    self.pickMeUpState = pickMeUpState
  }

  func startObserving() {
    assert(self.eventResponder != nil)

    guard let _ = self.eventResponder else {
      return
    }

    if isObserving {
      return
    }

    subscribeToShouldDisplayWhereToState()
    subscribeToPickMeUpViewState()
    subscribeToErrorMessages()
  }

  func stopObserving() {
    unsubscribeFromShouldDisplayWhereToState()
    unsubscribeFromPickMeUpViewState()
    unsubscribeFromErrorMessages()
  }

  func subscribeToShouldDisplayWhereToState() {
    shouldDisplayWhereToStateSubscription =
      pickMeUpState
        .receive(on: DispatchQueue.main)
        .map { $0.shouldDisplayWhereTo }
        .removeDuplicates()
        .sink { [weak self] shouldDisplayWhereTo in
          self?.received(newShouldDisplayWhereToState: shouldDisplayWhereTo)
        }
  }

  func received(newShouldDisplayWhereToState shouldDisplayWhereTo: Bool) {
    eventResponder?.received(newShouldDisplayWhereTo: shouldDisplayWhereTo)
  }

  func unsubscribeFromShouldDisplayWhereToState() {
    shouldDisplayWhereToStateSubscription = nil
  }

  func subscribeToPickMeUpViewState() {
    pickMeUpViewStateSubscription =
      pickMeUpState
        .receive(on: DispatchQueue.main)
        .map { (state: $0.state, sendingState: $0.sendingState) }
        .map (mapToView)
        .removeDuplicates()
        .sink { [weak self] view in
          self?.received(newPickMeUpViewState: view)
        }
  }

  func received(newPickMeUpViewState pickMeUpView: PickMeUpView) {
    eventResponder?.received(newPickMeUpView: pickMeUpView)
  }

  func unsubscribeFromPickMeUpViewState() {
    pickMeUpViewStateSubscription = nil
  }

  func subscribeToErrorMessages() {
    errorStateSubscription =
      pickMeUpState
        .receive(on: DispatchQueue.main)
        .map { $0.errorsToPresent.first }
        .compactMap { $0 }
        .removeDuplicates()
        .sink { [weak self] errorMessage in
          self?.received(newErrorMessage: errorMessage)
        }
  }

  func received(newErrorMessage errorMessage: ErrorMessage) {
    eventResponder?.received(newErrorMessage: errorMessage)
  }

  func unsubscribeFromErrorMessages() {
    errorStateSubscription = nil
  }
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
