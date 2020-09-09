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

public class KooberPickMeUpDependencyContainer {

  // MARK: - Properties

  // From parent container
  let imageCache: ImageCache
  let signedInViewModel: SignedInViewModel

  // Context
  let pickupLocation: Location

  // Long-lived dependencies
  let mapViewModel: PickMeUpMapViewModel
  let newRideRemoteAPI: NewRideRemoteAPI
  let newRideRepository: NewRideRepository
  let rideOptionDataStore: RideOptionDataStore
  let pickMeUpViewModel: PickMeUpViewModel

  // MARK: - Methods
  init(signedInDependencyContainer: KooberSignedInDependencyContainer, pickupLocation: Location) {
    func makePickMeUpMapViewModel() -> PickMeUpMapViewModel {
      return PickMeUpMapViewModel(pickupLocation: pickupLocation)
    }
    func makeNewRideRemoteAPI() -> NewRideRemoteAPI {
      return FakeNewRideRemoteAPI()
    }
    func makeNewRideRepository(newRideRemoteAPI: NewRideRemoteAPI) -> NewRideRepository {
      let newRideRemoteAPI = makeNewRideRemoteAPI()
      return KooberNewRideRepository(remoteAPI: newRideRemoteAPI)
    }
    func makeRideOptionDataStore() -> RideOptionDataStore {
      return RideOptionDataStoreInMemory()
    }
    func makePickMeUpViewModel(newRideRepository: NewRideRepository,
                               newRideRequestAcceptedResponder: NewRideRequestAcceptedResponder,
                               mapViewModel: PickMeUpMapViewModel) -> PickMeUpViewModel {
      return PickMeUpViewModel(pickupLocation: pickupLocation,
                               newRideRepository: newRideRepository,
                               newRideRequestAcceptedResponder: newRideRequestAcceptedResponder,
                               mapViewModel: mapViewModel)
    }

    self.imageCache = signedInDependencyContainer.imageCache
    self.signedInViewModel = signedInDependencyContainer.signedInViewModel

    self.pickupLocation = pickupLocation

    self.mapViewModel = makePickMeUpMapViewModel()
    self.newRideRemoteAPI = makeNewRideRemoteAPI()
    self.newRideRepository = makeNewRideRepository(newRideRemoteAPI: self.newRideRemoteAPI)
    self.rideOptionDataStore = makeRideOptionDataStore()
    self.pickMeUpViewModel = makePickMeUpViewModel(newRideRepository: newRideRepository,
                                                   newRideRequestAcceptedResponder: signedInViewModel,
                                                   mapViewModel: mapViewModel)
  }

  // Pick-me-up (container view controller)
  public func makePickMeUpViewController() -> PickMeUpViewController {
    let mapViewController = makePickMeUpMapViewController()
    let rideOptionPickerViewController = makeRideOptionPickerViewController()
    let sendingRideRequestViewController = makeSendingRideRequestViewController()
    return PickMeUpViewController(viewModel: pickMeUpViewModel,
                                  mapViewController: mapViewController,
                                  rideOptionPickerViewController: rideOptionPickerViewController,
                                  sendingRideRequestViewController: sendingRideRequestViewController,
                                  viewControllerFactory: self)
  }

  // Map
  func makePickMeUpMapViewController() -> PickMeUpMapViewController {
    return PickMeUpMapViewController(viewModelFactory: self,
                                     imageCache: imageCache)
  }

  public func makePickMeUpMapViewModel() -> PickMeUpMapViewModel {
    return mapViewModel
  }

  // Dropoff location picker
  public func makeDropoffLocationPickerViewController() -> DropoffLocationPickerViewController {
    let contentViewController = makeDropoffLocationPickerContentViewController()
    return DropoffLocationPickerViewController(contentViewController: contentViewController)
  }

  func makeDropoffLocationPickerContentViewController() -> DropoffLocationPickerContentViewController {
    return DropoffLocationPickerContentViewController(pickupLocation: pickupLocation,
                                                      viewModel: makeDropoffLocationPickerViewModel())
  }

  public func makeDropoffLocationPickerViewModel() -> DropoffLocationPickerViewModel {
    let repository = makeLocationRepository()
    return DropoffLocationPickerViewModel(pickupLocation: pickupLocation,
                                          locationRepository: repository,
                                          dropoffLocationDeterminedResponder: pickMeUpViewModel,
                                          cancelDropoffLocationSelectionResponder: pickMeUpViewModel)
  }

  public func makeLocationRepository() -> LocationRepository {
    return KooberLocationRepository(remoteAPI: newRideRemoteAPI)
  }

  // Ride-option picker
  public func makeRideOptionPickerViewController() -> RideOptionPickerViewController {
    return RideOptionPickerViewController(pickupLocation: pickupLocation,
                                          imageCache: imageCache,
                                          viewModelFactory: self)
  }

  public func makeRideOptionPickerViewModel() -> RideOptionPickerViewModel {
    let repository = makeRideOptionRepository()
    return RideOptionPickerViewModel(repository: repository,
                                     rideOptionDeterminedResponder: pickMeUpViewModel)
  }

  public func makeRideOptionRepository() -> RideOptionRepository {
    return KooberRideOptionRepository(remoteAPI: newRideRemoteAPI,
                                      datastore: rideOptionDataStore)
  }

  // Sending ride request
  public func makeSendingRideRequestViewController() -> SendingRideRequestViewController {
    return SendingRideRequestViewController()
  }
}

extension KooberPickMeUpDependencyContainer: PickMeUpViewControllerFactory {}

extension KooberPickMeUpDependencyContainer: PickMeUpMapViewModelFactory {}

extension KooberPickMeUpDependencyContainer: DropoffLocationViewModelFactory, RideOptionPickerViewModelFactory {}
