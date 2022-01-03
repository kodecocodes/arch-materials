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
import ReSwift
import PromiseKit

public class ReduxPickMeUpUserInteractions: PickMeUpUserInteractions {

  // MARK: - Properties
  let actionDispatcher: ActionDispatcher
  let newRideRepository: NewRideRepository

  // MARK: - Methods
  public init(actionDispatcher: ActionDispatcher,
              newRideRepository: NewRideRepository) {
    self.actionDispatcher = actionDispatcher
    self.newRideRepository = newRideRepository
  }

  public func goToDropoffLocationPicker() {
    let action = PickMeUpActions.GoToDropoffLocationPicker()
    actionDispatcher.dispatch(action)
  }

  public func confirmNewRideRequest() {
    let action = PickMeUpActions.ConfirmedNewRideRequest()
    actionDispatcher.dispatch(action)
  }

  public func send(_ newRideRequest: NewRideRequest) {
    newRideRepository.request(newRide: newRideRequest)
      .done {
        let action = PickMeUpActions.NewRideRequestSent()
        self.actionDispatcher.dispatch(action)
      }.catch { error in
        let errorMessage = ErrorMessage(title: "Ride Request Error",
                                        message: "There was an error trying to confirm your ride request.\nPlease try again.")
        let action = PickMeUpActions.FailedToSendNewRideRequest(errorMessage: errorMessage)
        self.actionDispatcher.dispatch(action)
    }
  }

  public func finishedRequestingNewRide() {
    let action = SignedInActions.FinishedRequestingNewRide()
    actionDispatcher.dispatch(action)
  }

  public func finishedPresentingNewRequestError(_ errorMessage: ErrorMessage) {
    let action = PickMeUpActions.FinishedPresentingNewRideRequestError(errorMessage: errorMessage)
    actionDispatcher.dispatch(action)
  }
}
