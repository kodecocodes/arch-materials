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

public class KooberSignedInDependencyContainer {

  // MARK: - Properties

  // From parent container
  let appRunningGetters: AppRunningGetters
  let actionDispatcher: ActionDispatcher
  let stateStore: Store<AppState>

  let userSession: UserSession

  let imageCache: ImageCache = InBundleImageCache()
  let locator: Locator = FakeLocator()
  let rideOptionDataStore: RideOptionDataStore = RideOptionDataStoreDiskUserPrefs()
  let newRideRemoteAPI: NewRideRemoteAPI = FakeNewRideRemoteAPI()
  let signedInGetters: SignedInGetters

  // MARK: - Methods
  public init(userSession: UserSession, appContainer: KooberAppDependencyContainer) {
    self.appRunningGetters = appContainer.appRunningGetters
    self.actionDispatcher = appContainer.stateStore
    self.stateStore = appContainer.stateStore

    self.userSession = userSession
    self.signedInGetters = SignedInGetters(getSignedInState: appRunningGetters.getSignedInViewControllerState)
  }

  // Signed In
  public func makeSignedInViewController() -> SignedInViewController {
    let userInterface = SignedInRootView()
    let statePublisher = makeSignedInViewControllerStatePublisher()
    let observer = ObserverForSignedIn(signedInState: statePublisher)
    let profileViewController = makeProfileViewController()
    let viewControllerFactory = self
    let goToProfileUseCaseFactory = self

    let signedInViewController =
      SignedInViewController(
        observer: observer,
        userInterface: userInterface,
        userSession: userSession,
        profileViewController: profileViewController,
        viewControllerFactory: viewControllerFactory,
        goToProfileUseCaseFactory: goToProfileUseCaseFactory)
    observer.eventResponder = signedInViewController
    userInterface.ixResponder = signedInViewController

    return signedInViewController
  }

  public func makeSignedInViewControllerStatePublisher() -> AnyPublisher<SignedInViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.appRunningGetters.getSignedInViewControllerState)
        }
    return statePublisher
  }

  // Getting Users Location
  public func makeGettingUsersLocationViewController() -> GettingUsersLocationViewController {
    let statePublisher = makeGettingUsersLocationViewControllerStatePublisher()
    let observer = ObserverForGettingUsersLocation(gettingUsersLocationState: statePublisher)
    let getUsersCurrentLocationUseCaseFactory = self
    let finishedPresentingErrorUseCaseFactory = self.makeFinishedPresentingUserLocationErrorUseCase

    let gettingUsersLocationViewController =
      GettingUsersLocationViewController(
        observer: observer,
        getUsersCurrentLocationUseCaseFactory: getUsersCurrentLocationUseCaseFactory,
        finishedPresentingErrorUseCaseFactory: finishedPresentingErrorUseCaseFactory
      )
    observer.eventResponder = gettingUsersLocationViewController

    return gettingUsersLocationViewController
  }

  public func makeGettingUsersLocationViewControllerStatePublisher() -> AnyPublisher<GettingUsersLocationViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.signedInGetters.getGettingUsersLocationViewControllerState)
        }
    return statePublisher
  }

  public func makeFinishedPresentingUserLocationErrorUseCase(errorMessage: ErrorMessage) -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase =
      FinishedPresentingErrorUseCaseFactories
        .makeFinishedPresentingUserLocationErrorUseCase(
          errorMessage: errorMessage,
          actionDispatcher: actionDispatcher
        )
    return useCase
  }

  // Pick Me Up
  public func makePickMeUpViewController(pickupLocation: Location) -> PickMeUpViewController {
    let pickMeUpDependencyContainer = KooberPickMeUpDependencyContainer(pickupLocation: pickupLocation,
                                                                        signedInDependencyContainer: self)
    return pickMeUpDependencyContainer.makePickMeUpViewController()
  }

  // Waiting for Pickup
  public func makeWaitingForPickupViewController() -> WaitingForPickupViewController {
    let userInterface = WaitingForPickupRootView()
    let startNewRideRequestUseCaseFactory = self

    let waitingForPickupViewController =
      WaitingForPickupViewController(
        userInterface: userInterface,
        startNewRideRequestUseCaseFactory: startNewRideRequestUseCaseFactory
      )
    userInterface.ixResponder = waitingForPickupViewController

    return waitingForPickupViewController
  }

  // View Profile
  public func makeProfileViewController() -> ProfileViewController {
    let contentViewController = makeProfileContentViewController()
    return ProfileViewController(contentViewController: contentViewController)
  }

  private func makeProfileContentViewController() -> ProfileContentViewController {
    let userInterface = ProfileContentRootView()
    let statePublisher = makeProfileViewControllerStatePublisher()
    let observer = ObserverForProfile(profileState: statePublisher)
    let dismissProfileUseCaseFactory = self
    let signOutUseCaseFactory = self
    let finishedPresentingErrorUseCaseFactory = self.makeFinishedPresentingProfileErrorUseCase

    let profileViewController =
      ProfileContentViewController(
        observer: observer,
        userInterface: userInterface,
        dismissProfileUseCaseFactory: dismissProfileUseCaseFactory,
        signOutUseCaseFactory: signOutUseCaseFactory,
        finishedPresentingErrorUseCaseFactory: finishedPresentingErrorUseCaseFactory
      )
    observer.eventResponder = profileViewController
    userInterface.ixResponder = profileViewController

    return profileViewController
  }

  public func makeProfileViewControllerStatePublisher() -> AnyPublisher<ProfileViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.signedInGetters.getProfileViewControllerState)
        }
    return statePublisher
  }

  public func makeFinishedPresentingProfileErrorUseCase(errorMessage: ErrorMessage) -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase =
      FinishedPresentingErrorUseCaseFactories
        .makeFinishedPresentingProfileErrorUseCase(
          errorMessage: errorMessage,
          actionDispatcher: actionDispatcher
        )
    return useCase
  }
}

extension KooberSignedInDependencyContainer: SignedInViewControllerFactory {}

extension KooberSignedInDependencyContainer: GoToProfileUseCaseFactory {

  public func makeGoToProfileUseCase() -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase = GoToProfileUseCase(actionDispatcher: actionDispatcher)
    return useCase
  }
}

extension KooberSignedInDependencyContainer: GetUsersCurrentLocationUseCaseFactory {

  public func makeGetUsersCurrentLocationUseCase() -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let locator = self.locator
    let useCase =
      GetUsersCurrentLocationUseCase(
        actionDispatcher: actionDispatcher,
        locator: locator
      )
    return useCase
  }
}

extension KooberSignedInDependencyContainer: DismissProfileUseCaseFactory {

  public func makeDismissProfileUseCase() -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase = DismissProfileUseCase(actionDispatcher: actionDispatcher)
    return useCase
  }
}

extension KooberSignedInDependencyContainer: SignOutUseCaseFactory {

  public func makeSignOutUseCase() -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase = SignOutUseCase(actionDispatcher: actionDispatcher)
    return useCase
  }
}

extension KooberSignedInDependencyContainer: StartNewRideRequestUseCaseFactory {

  public func makeStartNewRideRequestUseCase() -> UseCase {
    let actionDispatcher = self.actionDispatcher
    let useCase = StartNewRideRequestUseCase(actionDispatcher: actionDispatcher)
    return useCase
  }
}
