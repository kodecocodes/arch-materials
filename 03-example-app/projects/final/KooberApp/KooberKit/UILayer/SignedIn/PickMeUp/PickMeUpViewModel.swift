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
import Combine

public class PickMeUpViewModel: DropoffLocationDeterminedResponder,
                                RideOptionDeterminedResponder,
                                CancelDropoffLocationSelectionResponder {

  // MARK: - Properties
  var progress: PickMeUpRequestProgress
  let newRideRepository: NewRideRepository
  let newRideRequestAcceptedResponder: NewRideRequestAcceptedResponder
  let mapViewModel: PickMeUpMapViewModel

  @Published public private(set) var view: PickMeUpView
  @Published public private(set) var shouldDisplayWhereTo = true

  public let errorPresentation = PassthroughSubject<ErrorPresentation?, Never>()
  public var errorMessages: AnyPublisher<ErrorMessage, Never> {
    errorMessagesSubject.eraseToAnyPublisher()
  }
  private let errorMessagesSubject = PassthroughSubject<ErrorMessage, Never>()

  private var subscriptions = Set<AnyCancellable>()

  // MARK: - Methods
  public init(pickupLocation: Location,
              newRideRepository: NewRideRepository,
              newRideRequestAcceptedResponder: NewRideRequestAcceptedResponder,
              mapViewModel: PickMeUpMapViewModel,
              shouldDisplayWhereTo: Bool = true) {
    self.view = .initial
    self.progress = .initial(pickupLocation: pickupLocation)
    self.newRideRepository = newRideRepository
    self.newRideRequestAcceptedResponder = newRideRequestAcceptedResponder
    self.mapViewModel = mapViewModel
    self.shouldDisplayWhereTo = shouldDisplayWhereTo

    $view
      .receive(on: DispatchQueue.main)
      .sink { [weak self] view in
        self?.updateShouldDisplayWhereTo(basedOn: view)
    }.store(in: &subscriptions)
  }

  func updateShouldDisplayWhereTo(basedOn view: PickMeUpView) {
    shouldDisplayWhereTo = shouldDisplayWhereTo(during: view)
  }

  func shouldDisplayWhereTo(during view: PickMeUpView) -> Bool {
    switch view {
    case .initial, .selectDropoffLocation:
      return true
    case .selectRideOption, .confirmRequest, .sendingRideRequest, .final:
      return false
    }
  }

  public func cancelDropoffLocationSelection() {
    view = .initial
  }

  public func dropOffUser(at location: Location) {
    guard case let .initial(pickupLocation) = progress else {
      fatalError()
    }
    let waypoints = NewRideWaypoints(pickupLocation: pickupLocation,
                                     dropoffLocation: location)
    progress = .waypointsDetermined(waypoints: waypoints)
    view = .selectRideOption
    mapViewModel.dropoffLocation = location
  }

  public func pickUpUser(in rideOptionID: RideOptionID) {
    if case let .waypointsDetermined(waypoints) = progress {
      let rideRequest = NewRideRequest(waypoints: waypoints,
                                       rideOptionID: rideOptionID)
      progress = .rideRequestReady(rideRequest: rideRequest)
      view = .confirmRequest
    } else if case let .rideRequestReady(oldRideRequest) = progress {
      let rideRequest = NewRideRequest(waypoints: oldRideRequest.waypoints,
                                       rideOptionID: rideOptionID)
      progress = .rideRequestReady(rideRequest: rideRequest)
      view = .confirmRequest
    } else {
      fatalError()
    }
  }

  @objc
  public func showSelectDropoffLocationView() {
    view = .selectDropoffLocation
  }
  
  @objc
  public func sendRideRequest() {
    guard case let .rideRequestReady(rideRequest) = progress else {
      fatalError()
    }
    view = .sendingRideRequest
    newRideRepository.request(newRide: rideRequest)
      .done {
        self.view = .final
      }.catch { error in
        self.goToNextScreenAfterErrorPresentation()
        let errorMessage = ErrorMessage(title: "Ride Request Error",
                                        message: "There was an error trying to confirm your ride request.\nPlease try again.")
        self.errorMessagesSubject.send(errorMessage)
      }
  }

  public func finishedSendingNewRideRequest() {
    newRideRequestAcceptedResponder.newRideRequestAccepted()
  }

  func goToNextScreenAfterErrorPresentation() {
    errorPresentation
      .filter { $0 == .dismissed }
      .prefix(1)
      .sink { [weak self] _ in
        self?.view = .confirmRequest
    }.store(in: &subscriptions)
  }
}
