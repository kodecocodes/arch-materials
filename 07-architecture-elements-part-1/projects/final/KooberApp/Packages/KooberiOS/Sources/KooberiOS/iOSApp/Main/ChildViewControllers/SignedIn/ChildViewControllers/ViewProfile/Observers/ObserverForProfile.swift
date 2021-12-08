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
import KooberKit
import Combine


class ObserverForProfile: Observer {

  // MARK: - Properties
  weak var eventResponder: ObserverForProfileEventResponder? {
    willSet {
      if newValue == nil {
        stopObserving()
      }
    }
  }

  let profileState: AnyPublisher<ProfileViewControllerState, Never>
  var profileStateSubscription: AnyCancellable?
  var errorStateSubscription: AnyCancellable?

  private var isObserving: Bool {
    if profileStateSubscription != nil
      && errorStateSubscription != nil
    {
      return true
    } else {
      return false
    }
  }

  // MARK: - Methods
  init(profileState: AnyPublisher<ProfileViewControllerState, Never>) {
    self.profileState = profileState
  }

  func startObserving() {
    assert(self.eventResponder != nil)

    guard let _ = self.eventResponder else {
      return
    }

    if isObserving {
      return
    }

    subscribeToProfileState()
    subscribeToErrorMessages()
  }

  func stopObserving() {
    unsubscribeFromProfileState()
    unsubscribeFromErrorMessages()
  }

  func subscribeToProfileState() {
    profileStateSubscription =
      profileState
        .receive(on: DispatchQueue.main)
        .map { $0.profile }
        .removeDuplicates()
        .sink { [weak self] userProfile in
          self?.received(newUserProfile: userProfile)
        }
  }

  func received(newUserProfile userProfile: UserProfile) {
    eventResponder?.received(newUserProfile: userProfile)
  }

  func unsubscribeFromProfileState() {
    profileStateSubscription = nil
  }

  func subscribeToErrorMessages() {
    errorStateSubscription =
      profileState
        .map { $0.errorsToPresent.first }
        .compactMap { $0 }
        .removeDuplicates()
        .sink { [weak self] errorMessage in
          self?.received(newErrorMessage: errorMessage)
        }
  }

  func received(newErrorMessage errorMessage: ErrorMessage) {
    eventResponder?.received(newErrorMessage: errorMessage)
  }

  func unsubscribeFromErrorMessages() {
    errorStateSubscription = nil
  }
}
