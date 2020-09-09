/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import PromiseKit

public class SearchDropoffLocationsUseCase: CancelableUseCase {

  // MARK: - Properties
  let query: String
  let pickupLocation: Location
  let actionDispatcher: ActionDispatcher
  let locationRepository: LocationRepository
  var cancelled = false

  // MARK: - Methods
  public init(query: String,
              pickupLocation: Location,
              actionDispatcher: ActionDispatcher,
              locationRepository: LocationRepository) {
    self.query = query
    self.pickupLocation = pickupLocation
    self.actionDispatcher = actionDispatcher
    self.locationRepository = locationRepository
  }

  public func start() {
    assert(Thread.isMainThread)
    guard !cancelled else {
      return
    }

    let searchID = UUID()
    let newSearchAction = DropoffLocationPickerActions.NewLocationSearch(searchID: searchID)
    actionDispatcher.dispatch(newSearchAction)

    locationRepository
      .searchForLocations(using: query, pickupLocation: pickupLocation)
      .done { searchResults in
        assert(Thread.isMainThread)
        guard self.cancelled == false else {
          return
        }
        self.update(searchResults: searchResults, for: searchID)
      }
      .catch { error in
        assert(Thread.isMainThread)
        guard self.cancelled == false else {
          return
        }
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

  public func cancel() {
    assert(Thread.isMainThread)
    cancelled = true
  }
}

public protocol SearchDropoffLocationsUseCaseFactory {

  func makeSearchDropoffLocationsUseCase(
    query: String,
    pickupLocation: Location
  ) -> UseCase
}
