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


class ObserverForRideOptionPicker: Observer {

  // MARK: - Properties
  weak var eventResponder: ObserverForRideOptionPickerEventResponder? {
    willSet {
      if newValue == nil {
        stopObserving()
      }
    }
  }

  let rideOptionPickerState: AnyPublisher<RideOptionPickerViewControllerState, Never>
  var rideOptionSegmentedControlStateSubscription: AnyCancellable?
  var errorStateSubscription: AnyCancellable?

  private var isObserving: Bool {
    if rideOptionSegmentedControlStateSubscription != nil
      && errorStateSubscription != nil
    {
      return true
    } else {
      return false
    }
  }

  // MARK: - Methods
  init(rideOptionPickerState: AnyPublisher<RideOptionPickerViewControllerState, Never>) {
    self.rideOptionPickerState = rideOptionPickerState
  }

  func startObserving() {
    assert(self.eventResponder != nil)

    guard let _ = self.eventResponder else {
      return
    }

    if isObserving {
      return
    }

    subscribeToRideOptionSegmentedControlState()
    subscribeToErrorMessages()
  }

  func stopObserving() {
    unsubscribeFromRideOptionSegmentedControlState()
    unsubscribeFromErrorMessages()
  }

  func subscribeToRideOptionSegmentedControlState() {
    rideOptionSegmentedControlStateSubscription =
      rideOptionPickerState
        .receive(on: DispatchQueue.main)
        .map { $0.segmentedControlState }
        .removeDuplicates()
        .sink { [weak self] segmentedControlState in
          self?.received(newRideOptionSegmentedControlState: segmentedControlState)
        }
  }

  func received(newRideOptionSegmentedControlState rideOptionSegmentedControlState: RideOptionSegmentedControlState) {
    eventResponder?.received(newRideOptionSegmentedControlState: rideOptionSegmentedControlState)
  }

  func unsubscribeFromRideOptionSegmentedControlState() {
    rideOptionSegmentedControlStateSubscription = nil
  }

  func subscribeToErrorMessages() {
    errorStateSubscription =
      rideOptionPickerState
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
