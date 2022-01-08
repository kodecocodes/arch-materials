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
import CoreGraphics
import PromiseKit

public class ReduxRideOptionPickerUserInteractions: RideOptionPickerUserInteractions {

  // MARK: - Properties
  let actionDispatcher: ActionDispatcher
  let rideOptionRepository: RideOptionRepository

  // MARK: - Methods
  public init(actionDispatcher: ActionDispatcher,
              rideOptionRepository: RideOptionRepository) {
    self.actionDispatcher = actionDispatcher
    self.rideOptionRepository = rideOptionRepository
  }

  public func loadRideOptions(availableAt pickupLocation: Location, screenScale: CGFloat) {
    rideOptionRepository
      .readRideOptions(availableAt: pickupLocation)
      .then { (rideOptions: [RideOption]) -> Promise<RideOptionPickerRideOptions> in
        let pickerRideOptions = RideOptionPickerRideOptions(rideOptions: rideOptions)
        return Promise.value(pickerRideOptions)
      }
      .then { (pickerRideOptions: RideOptionPickerRideOptions) -> Promise<[RideOptionSegmentState]>  in
        let factory = RideOptionSegmentsFactory(state: pickerRideOptions)
        let segments = factory.makeSegments(screenScale: screenScale)
        return Promise.value(segments)
      }
      .done { segments in
        let rideOptions = RideOptionSegmentedControlState(segments: segments)
        let action = RideOptionPickerActions.RideOptionsLoaded(rideOptions: rideOptions)
        self.actionDispatcher.dispatch(action)
      }
      .catch { error in
        let errorMessage = ErrorMessage(title: "Ride Option Error",
                                        message: "We're having trouble getting available ride options. Please start a new ride and try again.")
        let action = RideOptionPickerActions.FailedToLoadRideOptions(errorMessage: errorMessage)
        self.actionDispatcher.dispatch(action)
    }
  }

  public func select(rideOptionID: RideOptionID) {
    let action = RideOptionPickerActions.RideOptionSelected(rideOptionID: rideOptionID)
    actionDispatcher.dispatch(action)
  }

  public func finishedPresenting(_ errorMessage: ErrorMessage) {
    let action = RideOptionPickerActions.FinishedPresentingError(errorMessage: errorMessage)
    actionDispatcher.dispatch(action)
  }
}
