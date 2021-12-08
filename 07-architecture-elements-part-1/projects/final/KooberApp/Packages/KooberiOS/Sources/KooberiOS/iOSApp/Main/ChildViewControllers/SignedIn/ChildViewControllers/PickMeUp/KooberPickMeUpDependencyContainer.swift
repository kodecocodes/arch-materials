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
    let userInterface = PickMeUpRootView()
    let statePublisher = makePickMeUpViewControllerStatePublisher()
    let observer = ObserverForPickMeUp(pickMeUpState: statePublisher)
    let mapViewController = makePickMeUpMapViewController()
    let rideOptionPickerViewController = makeRideOptionPickerViewController()
    let sendingRideRequestViewController = makeSendingRideRequestViewController()
    let viewControllerFactory = self
    let goToDropoffLocationPickerUseCaseFactory = self
    let confirmRideRequestUseCaseFactory = self
    let requestRideUseCaseFactory = self
    let finishedRequestingNewRideUseCaseFactory = self
    let finishedPresentingErrorUseCaseFactory = self.makeFinishedPresentingPickMeUpErrorUseCase

    let pickMeUpViewController =
      PickMeUpViewController(
        observer: observer,
        userInterface: userInterface,
        mapViewController: mapViewController,
        rideOptionPickerViewController: rideOptionPickerViewController,
        sendingRideRequestViewController: sendingRideRequestViewController,
        viewControllerFactory: viewControllerFactory,
        goToDropoffLocationPickerUseCaseFactory: goToDropoffLocationPickerUseCaseFactory,
        confirmRideRequestUseCaseFactory: confirmRideRequestUseCaseFactory,
        requestRideUseCaseFactory: requestRideUseCaseFactory,
        finishedRequestingNewRideUseCaseFactory: finishedRequestingNewRideUseCaseFactory,
        finishedPresentingErrorUseCaseFactory: finishedPresentingErrorUseCaseFactory)
    observer.eventResponder = pickMeUpViewController
    userInterface.ixResponder = pickMeUpViewController

    return pickMeUpViewController
  }

  public func makePickMeUpViewControllerStatePublisher() -> AnyPublisher<PickMeUpViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.signedInGetters.getPickMeUpViewControllerState)
        }
    return statePublisher
  }

  public func makeFinishedPresentingPickMeUpErrorUseCase(errorMessage: ErrorMessage) -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase =
      FinishedPresentingErrorUseCaseFactories
        .makeFinishedPresentingPickMeUpErrorUseCase(
          errorMessage: errorMessage,
          actionDispatcher: actionDispatcher
        )
    return useCase
  }

  public func makeNewRideRepository() -> NewRideRepository {
    return KooberNewRideRepository(remoteAPI: newRideRemoteAPI)
  }

  // Map
  func makePickMeUpMapViewController() -> PickMeUpMapViewController {
    let imageCache = self.imageCache
    let userInterface = PickMeUpMapRootView(imageCache: imageCache)
    let statePublisher = makeMapViewControllerStatePublisher()
    let observer = ObserverForPickMeUpMap(mapState: statePublisher)

    let pickMeUpMapViewController =
      PickMeUpMapViewController(
        observer: observer,
        userInterface: userInterface
    )
    observer.eventResponder = pickMeUpMapViewController

    return pickMeUpMapViewController
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
    let pickupLocation = self.pickupLocation
    let userInterface = DropoffLocationPickerContentRootView()
    let statePublisher = makeDropoffLocationPickerViewControllerStatePublisher()
    let observer = ObserverForSelectDropoffLocation(dropoffLocationPickerState: statePublisher)
    let searchDropoffLocationsUseCaseFactory = self
    let selectDropoffLocationUseCaseFactory = self
    let cancelDropoffLocationPickerUseCaseFactory = self
    let finishedPresentingErrorUseCaseFactory = self.makeFinishedPresentingDropoffLocationPickerErrorUseCase

    let dropoffLocationPickerContentViewController =
      DropoffLocationPickerContentViewController(
        pickupLocation: pickupLocation,
        observer: observer,
        userInterface: userInterface,
        searchDropoffLocationsUseCaseFactory: searchDropoffLocationsUseCaseFactory,
        selectDropoffLocationUseCaseFactory: selectDropoffLocationUseCaseFactory,
        cancelDropoffLocationPickerUseCaseFactory: cancelDropoffLocationPickerUseCaseFactory,
        finishedPresentingErrorUseCaseFactory: finishedPresentingErrorUseCaseFactory
      )
    observer.eventResponder = dropoffLocationPickerContentViewController
    userInterface.ixResponder = dropoffLocationPickerContentViewController

    return dropoffLocationPickerContentViewController
  }

  public func makeDropoffLocationPickerViewControllerStatePublisher() -> AnyPublisher<DropoffLocationPickerViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.pickMeUpStateGetters.getDropoffLocationPickerViewControllerState)
        }
    return statePublisher
  }

  public func makeFinishedPresentingDropoffLocationPickerErrorUseCase(errorMessage: ErrorMessage) -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase =
      FinishedPresentingErrorUseCaseFactories
        .makeFinishedPresentingDropoffLocationPickerErrorUseCase(
          errorMessage: errorMessage,
          actionDispatcher: actionDispatcher
        )
    return useCase
  }

  public func makeLocationRepository() -> LocationRepository {
    return KooberLocationRepository(remoteAPI: newRideRemoteAPI)
  }

  // Ride-option picker
  public func makeRideOptionPickerViewController() -> RideOptionPickerViewController {
    let imageCache = self.imageCache
    let userInterface = RideOptionSegmentedControl(imageCache: imageCache)
    let statePublisher = makeRideOptionPickerViewControllerStatePublisher()
    let observer = ObserverForRideOptionPicker(rideOptionPickerState: statePublisher)
    let loadRideOptionsUseCaseFactory = self
    let selectRideOptionUseCaseFactory = self
    let finishedPresentingErrorUseCaseFactory = self.makeFinishedPresentingRideOptionPickerErrorUseCase

    let rideOptionPickerViewController =
      RideOptionPickerViewController(
        pickupLocation: pickupLocation,
        observer: observer,
        userInterface: userInterface,
        loadRideOptionsUseCaseFactory: loadRideOptionsUseCaseFactory,
        selectRideOptionUseCaseFactory: selectRideOptionUseCaseFactory,
        finishedPresentingErrorUseCaseFactory: finishedPresentingErrorUseCaseFactory
      )
    observer.eventResponder = rideOptionPickerViewController
    userInterface.ixResponder = rideOptionPickerViewController

    return rideOptionPickerViewController
  }

  public func makeRideOptionPickerViewControllerStatePublisher() -> AnyPublisher<RideOptionPickerViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.pickMeUpStateGetters.getRideOptionPickerViewControllerState)
        }
    return statePublisher
  }

  public func makeFinishedPresentingRideOptionPickerErrorUseCase(errorMessage: ErrorMessage) -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase =
      FinishedPresentingErrorUseCaseFactories
        .makeFinishedPresentingRideOptionPickerErrorUseCase(
          errorMessage: errorMessage,
          actionDispatcher: actionDispatcher
        )
    return useCase
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

extension KooberPickMeUpDependencyContainer: GoToDropoffLocationPickerUseCaseFactory {

  public func makeGoToDropoffLocationPickerUseCase() -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase = GoToDropoffLocationPickerUseCase(actionDispatcher: actionDispatcher)
    return useCase
  }
}

extension KooberPickMeUpDependencyContainer: ConfirmRideRequestUseCaseFactory {

  public func makeConfirmRideRequestUseCase() -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase = ConfirmRideRequestUseCase(actionDispatcher: actionDispatcher)
    return useCase
  }
}

extension KooberPickMeUpDependencyContainer: RequestRideUseCaseFactory {

  public func makeRequestRideUseCase(newRideRequest: NewRideRequest) -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let newRideRepository = makeNewRideRepository()
    let useCase =
      RequestRideUseCase(
        newRideRequest: newRideRequest,
        actionDispatcher: actionDispatcher,
        newRideRepository: newRideRepository
      )
    return useCase
  }
}

extension KooberPickMeUpDependencyContainer: FinishedRequestingNewRideUseCaseFactory {

  public func makeFinishedRequestingNewRideUseCase() -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase = FinishedRequestingNewRideUseCase(actionDispatcher: actionDispatcher)
    return useCase
  }
}

extension KooberPickMeUpDependencyContainer: SearchDropoffLocationsUseCaseFactory {

  public func makeSearchDropoffLocationsUseCase(query: String, pickupLocation: Location) -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let locationRepository = self.makeLocationRepository()
    let useCase =
      SearchDropoffLocationsUseCase(
        query: query,
        pickupLocation: pickupLocation,
        actionDispatcher: actionDispatcher,
        locationRepository: locationRepository
      )
    return useCase
  }
}

extension KooberPickMeUpDependencyContainer: SelectDropoffLocationUseCaseFactory {

  public func makeSelectDropoffLocationUseCase(dropoffLocation: Location) -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase =
      SelectDropoffLocationUseCase(
        dropoffLocation: dropoffLocation,
        actionDispatcher: actionDispatcher
      )
    return useCase
  }
}

extension KooberPickMeUpDependencyContainer: CancelDropoffLocationPickerUseCaseFactory {

  public func makeCancelDropoffLocationPickerUseCase() -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase = CancelDropoffLocationPickerUseCase(actionDispatcher: actionDispatcher)
    return useCase
  }
}

extension KooberPickMeUpDependencyContainer: LoadRideOptionsUseCaseFactory {

  public func makeLoadRideOptionsUseCase(pickupLocation: Location, screenScale: CGFloat) -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let rideOptionRepository = makeRideOptionRepository()
    let useCase =
      LoadRideOptionsUseCase(
        pickupLocation: pickupLocation,
        screenScale: screenScale,
        actionDispatcher: actionDispatcher,
        rideOptionRepository: rideOptionRepository
      )
    return useCase
  }
}

extension KooberPickMeUpDependencyContainer: SelectRideOptionUseCaseFactory {

  public func makeSelectRideOptionUseCase(rideOptionID: RideOptionID) -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase =
      SelectRideOptionUseCase(
        rideOptionID: rideOptionID,
        actionDispatcher: actionDispatcher
      )
    return useCase
  }
}

extension KooberPickMeUpDependencyContainer: PickMeUpViewControllerFactory {}
