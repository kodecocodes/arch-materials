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
    let statePublisher = makeSignedInViewControllerStatePublisher()
    let userInteractions = makeSignedInUserInteractions()
    let profileViewController = makeProfileViewController()
    return SignedInViewController(statePublisher: statePublisher,
                                  userInteractions: userInteractions,
                                  userSession: userSession,
                                  profileViewController: profileViewController,
                                  viewControllerFactory: self)
  }

  public func makeSignedInViewControllerStatePublisher() -> AnyPublisher<SignedInViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.appRunningGetters.getSignedInViewControllerState)
        }
    return statePublisher
  }

  public func makeSignedInUserInteractions() -> SignedInUserInteractions {
    return ReduxSignedInUserInteractions(actionDispatcher: actionDispatcher)
  }

  // Getting Users Location
  public func makeGettingUsersLocationViewController() -> GettingUsersLocationViewController {
    let statePublisher = makeGettingUsersLocationViewControllerStatePublisher()
    let userInteractions = makeGettingUsersLocationUserInteractions()
    return GettingUsersLocationViewController(statePublisher: statePublisher,
                                              userInteractions: userInteractions)
  }

  public func makeGettingUsersLocationViewControllerStatePublisher() -> AnyPublisher<GettingUsersLocationViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.signedInGetters.getGettingUsersLocationViewControllerState)
        }
    return statePublisher
  }

  public func makeGettingUsersLocationUserInteractions() -> GettingUsersLocationUserInteractions {
    return ReduxGettingUsersLocationUserInteractions(actionDispatcher: actionDispatcher,
                                                     locator: locator)
  }

  // Pick Me Up
  public func makePickMeUpViewController(pickupLocation: Location) -> PickMeUpViewController {
    let pickMeUpDependencyContainer = KooberPickMeUpDependencyContainer(pickupLocation: pickupLocation,
                                                                        signedInDependencyContainer: self)
    return pickMeUpDependencyContainer.makePickMeUpViewController()
  }

  // Waiting for Pickup
  public func makeWaitingForPickupViewController() -> WaitingForPickupViewController {
    let userInteractions = makeWaitingForPickupUserInteractions()
    return WaitingForPickupViewController(userInteractions: userInteractions)
  }

  public func makeWaitingForPickupUserInteractions() -> WaitingForPickupUserInteractions {
    return ReduxWaitingForPickupUserInteractions(actionDispatcher: actionDispatcher)
  }

  // View Profile
  public func makeProfileViewController() -> ProfileViewController {
    let contentViewController = makeProfileContentViewController()
    return ProfileViewController(contentViewController: contentViewController)
  }

  private func makeProfileContentViewController() -> ProfileContentViewController {
    let statePublisher = makeProfileViewControllerStatePublisher()
    let userInteractions = makeProfileUserInteractions()
    return ProfileContentViewController(statePublisher: statePublisher,
                                        userInteractions: userInteractions)
  }

  public func makeProfileViewControllerStatePublisher() -> AnyPublisher<ProfileViewControllerState, Never> {
    let statePublisher =
      stateStore
        .publisher { subscription in
          subscription.select(self.signedInGetters.getProfileViewControllerState)
        }
    return statePublisher
  }

  public func makeProfileUserInteractions() -> ProfileUserInteractions {
    return ReduxProfileUserInteractions(actionDispatcher: actionDispatcher,
                                        userSession: userSession)
  }
}

extension KooberSignedInDependencyContainer: SignedInViewControllerFactory {}
