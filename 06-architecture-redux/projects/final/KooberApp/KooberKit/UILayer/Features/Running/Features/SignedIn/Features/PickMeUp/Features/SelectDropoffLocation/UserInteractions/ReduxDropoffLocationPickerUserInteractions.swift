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

public class ReduxDropoffLocationPickerUserInteractions: DropoffLocationPickerUserInteractions {

  // MARK: - Properties
  let actionDispatcher: ActionDispatcher
  let locationRepository: LocationRepository

  // MARK: - Methods
  public init(actionDispatcher: ActionDispatcher,
              locationRepository: LocationRepository) {
    self.actionDispatcher = actionDispatcher
    self.locationRepository = locationRepository
  }

  public func cancelDropoffLocationPicker() {
    let action = DropoffLocationPickerActions.CancelDropoffLocationPicker()
    actionDispatcher.dispatch(action)
  }

  public func searchForDropoffLocations(using query: String, for pickupLocation: Location) {
    let searchID = UUID()
    let newSearchAction = DropoffLocationPickerActions.NewLocationSearch(searchID: searchID)
    actionDispatcher.dispatch(newSearchAction)

    locationRepository
      .searchForLocations(using: query, pickupLocation: pickupLocation)
      .done { [weak self] searchResults in
        self?.update(searchResults: searchResults, for: searchID)
      }
      .catch { error in
        let errorMessage = ErrorMessage(title: "Location Error",
                                        message: "Sorry, we ran into an unexpected error while getting locations.\nPlease try again.")
        let action = DropoffLocationPickerActions.LocationSearchFailed(errorMessage: errorMessage)
        self.actionDispatcher.dispatch(action)
    }
  }

  private func update(searchResults: [NamedLocation], for searchID: UUID) {
    let action = DropoffLocationPickerActions.LocationSearchComplete(searchID: searchID, searchResults: searchResults)
    actionDispatcher.dispatch(action)
  }

  public func select(dropoffLocation: Location) {
    let action = DropoffLocationPickerActions.DropoffLocationSelected(dropoffLocation: dropoffLocation)
    actionDispatcher.dispatch(action)
  }

  public func finishedPresenting(_ errorMessage: ErrorMessage) {
    let action = DropoffLocationPickerActions.FinishedPresentingError(errorMessage: errorMessage)
    return actionDispatcher.dispatch(action)
  }
}
