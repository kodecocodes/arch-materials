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
import ReSwift

public class KooberPickMeUpDependencyContainer {

  // MARK: - Properties

  // From parent container
  let imageCache: ImageCache
  let actionDispatcher: ActionDispatcher
  let stateStore: Store<AppState>
  let signedInGetters: SignedInGetters
  let newRideRemoteAPI: NewRideRemoteAPI
  let rideOptionDataStore: RideOptionDataStore

  let pickupLocation: Location

  let pickMeUpStateGetters: PickMeUpGetters

  // MARK: - Methods
  init(pickupLocation: Location, signedInDependencyContainer: KooberSignedInDependencyContainer) {
    self.imageCache = signedInDependencyContainer.imageCache
    self.actionDispatcher = signedInDependencyContainer.stateStore
    self.stateStore = signedInDependencyContainer.stateStore
    self.signedInGetters = signedInDependencyContainer.signedInGetters
    self.newRideRemoteAPI = signedInDependencyContainer.newRideRemoteAPI
    self.rideOptionDataStore = signedInDependencyContainer.rideOptionDataStore

    self.pickupLocation = pickupLocation
    self.pickMeUpStateGetters = PickMeUpGetters(getPickMeUpState: signedInGetters.getPickMeUpViewControllerState)
  }

  // Pick Me Up (container view controller)
  public func makePickMeUpViewController() -> PickMeUpViewController {
    let statePublisher = makePickMeUpViewControllerStatePublisher()
    let userInteractions = makePickMeUpUserInteractions()
    let mapViewController = makePickMeUpMapViewController()
    let rideOptionPickerViewController = makeRideOptionPickerViewController()
    let sendingRideRequestViewController = makeSendingRideRequestViewController()
    return PickMeUpViewController(statePublisher: statePublisher,
                                  userInteractions: userInteractions,
                                  mapViewController: mapViewController,
                                  rideOptionPickerViewController: rideOptionPickerViewController,
                                  sendingRideRequestViewController: sendingRideRequestViewController,
                                  viewControllerFactory: self)
  }

  public func makePickMeUpViewControllerStatePublisher() -> AnyPublisher<PickMeUpViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.signedInGetters.getPickMeUpViewControllerState)
        }
    return statePublisher
  }

  public func makePickMeUpUserInteractions() -> PickMeUpUserInteractions {
    let newRideRepository = makeNewRideRepository()
    return ReduxPickMeUpUserInteractions(actionDispatcher: actionDispatcher,
                                         newRideRepository: newRideRepository)
  }

  public func makeNewRideRepository() -> NewRideRepository {
    return KooberNewRideRepository(remoteAPI: newRideRemoteAPI)
  }

  // Map
  func makePickMeUpMapViewController() -> PickMeUpMapViewController {
    let statePublisher = makeMapViewControllerStatePublisher()
    return PickMeUpMapViewController(statePublisher: statePublisher,
                                     imageCache: imageCache)
  }

  public func makeMapViewControllerStatePublisher() -> AnyPublisher<MapViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.pickMeUpStateGetters.getMapViewControllerState)
        }
    return statePublisher
  }

  // Dropoff Location Picker
  public func makeDropoffLocationPickerViewController() -> DropoffLocationPickerViewController {
    let contentViewController = makeDropoffLocationPickerContentViewController()
    return DropoffLocationPickerViewController(contentViewController: contentViewController)
  }

  func makeDropoffLocationPickerContentViewController() -> DropoffLocationPickerContentViewController {
    let statePublisher = makeDropoffLocationPickerViewControllerStatePublisher()
    let userInteractions = makeDropoffLocationPickerUserInteractions()
    return DropoffLocationPickerContentViewController(pickupLocation: pickupLocation,
                                                      statePublisher: statePublisher,
                                                      userInteractions: userInteractions)
  }

  public func makeDropoffLocationPickerViewControllerStatePublisher() -> AnyPublisher<DropoffLocationPickerViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.pickMeUpStateGetters.getDropoffLocationPickerViewControllerState)
        }
    return statePublisher
  }

  public func makeDropoffLocationPickerUserInteractions() -> DropoffLocationPickerUserInteractions {
    let locationRepository = makeLocationRepository()
    return ReduxDropoffLocationPickerUserInteractions(actionDispatcher: actionDispatcher,
                                                      locationRepository: locationRepository)
  }

  public func makeLocationRepository() -> LocationRepository {
    return KooberLocationRepository(remoteAPI: newRideRemoteAPI)
  }

  // Ride-option picker
  public func makeRideOptionPickerViewController() -> RideOptionPickerViewController {
    let statePublisher = makeRideOptionPickerViewControllerStatePublisher()
    let userInteractions = makeRideOptionPickerUserInteractions()
    return RideOptionPickerViewController(pickupLocation: pickupLocation,
                                          statePublisher: statePublisher,
                                          userInteractions: userInteractions,
                                          imageCache: imageCache)
  }

  public func makeRideOptionPickerViewControllerStatePublisher() -> AnyPublisher<RideOptionPickerViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.pickMeUpStateGetters.getRideOptionPickerViewControllerState)
        }
    return statePublisher
  }

  public func makeRideOptionPickerUserInteractions() -> RideOptionPickerUserInteractions {
    let repository = makeRideOptionRepository()
    return ReduxRideOptionPickerUserInteractions(actionDispatcher: actionDispatcher,
                                                 rideOptionRepository: repository)
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
