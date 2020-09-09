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

public class KooberSignedInDependencyContainer {

  // MARK: - Properties

  // From parent container
  let userSessionRepository: UserSessionRepository
  let mainViewModel: MainViewModel

  // Context
  let userSession: UserSession

  // Longed-lived dependencies
  let signedInViewModel: SignedInViewModel
  let imageCache: ImageCache
  let locator: Locator


  // MARK: - Methods
  public init(userSession: UserSession, appDependencyContainer: KooberAppDependencyContainer) {
    func makeSignedInViewModel() -> SignedInViewModel {
      return SignedInViewModel()
    }
    func makeImageCache() -> ImageCache {
      return InBundleImageCache()
    }
    func makeLocator() -> Locator {
      return FakeLocator()
    }

    self.userSessionRepository = appDependencyContainer.sharedUserSessionRepository
    self.mainViewModel = appDependencyContainer.sharedMainViewModel

    self.userSession = userSession

    self.signedInViewModel = makeSignedInViewModel()
    self.imageCache = makeImageCache()
    self.locator = makeLocator()
  }

  // Signed-in
  public func makeSignedInViewController() -> SignedInViewController {
    let profileViewController = makeProfileViewController()
    return SignedInViewController(viewModel: signedInViewModel,
                                  userSession: userSession,
                                  profileViewController: profileViewController,
                                  viewControllerFactory: self)
  }

  // Getting user's location
  public func makeGettingUsersLocationViewController() -> GettingUsersLocationViewController {
    return GettingUsersLocationViewController(viewModelFactory: self)
  }

  public func makeGettingUsersLocationViewModel() -> GettingUsersLocationViewModel {
    return GettingUsersLocationViewModel(determinedPickUpLocationResponder: signedInViewModel,
                                         locator: locator)
  }

  // Pick-me-up
  public func makePickMeUpViewController(pickupLocation: Location) -> PickMeUpViewController {
    let pickMeUpDependencyContainer = KooberPickMeUpDependencyContainer(signedInDependencyContainer: self,
                                                                        pickupLocation: pickupLocation)
    return pickMeUpDependencyContainer.makePickMeUpViewController()
  }

  // Waiting for Pickup
  public func makeWaitingForPickupViewController() -> WaitingForPickupViewController {
    return WaitingForPickupViewController(viewModelFactory: self)
  }

  public func makeWaitingForPickupViewModel() -> WaitingForPickupViewModel {
    return WaitingForPickupViewModel(goToNewRideNavigator: signedInViewModel)
  }

  // View profile
  public func makeProfileViewController() -> ProfileViewController {
    let contentViewController = makeProfileContentViewController()
    return ProfileViewController(contentViewController: contentViewController)
  }

  private func makeProfileContentViewController() -> ProfileContentViewController {
    let viewModel = makeProfileViewModel()
    return ProfileContentViewController(viewModel: viewModel)
  }

  public func makeProfileViewModel() -> ProfileViewModel {
    return ProfileViewModel(userSession: userSession,
                            notSignedInResponder: mainViewModel,
                            doneWithProfileResponder: signedInViewModel,
                            userSessionRepository: userSessionRepository)
  }
}

extension KooberSignedInDependencyContainer: SignedInViewControllerFactory {}

extension KooberSignedInDependencyContainer: GettingUsersLocationViewModelFactory, WaitingForPickupViewModelFactory {}
