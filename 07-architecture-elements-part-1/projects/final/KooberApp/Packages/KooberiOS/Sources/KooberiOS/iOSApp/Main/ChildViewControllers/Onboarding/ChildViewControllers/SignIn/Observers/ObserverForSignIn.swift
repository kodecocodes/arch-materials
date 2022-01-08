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
import UIKit
import KooberKit
import Combine

class ObserverForSignIn: Observer {

  // MARK: - Properties
  weak var eventResponder: ObserverForSignInEventResponder? {
    willSet {
      if newValue == nil {
        stopObserving()
      }
    }
  }

  let signInState: AnyPublisher<SignInViewControllerState, Never>
  var errorStateSubscription: AnyCancellable?
  var viewStateSubscription: AnyCancellable?

  private var isObserving: Bool {
    if isObservingState && isObservingKeyboard {
      return true
    } else {
      return false
    }
  }

  private var isObservingState: Bool {
    if errorStateSubscription != nil
      && viewStateSubscription != nil
    {
      return true
    } else {
      return false
    }
  }

  private var isObservingKeyboard = false

  // MARK: - Methods
  init(signInState: AnyPublisher<SignInViewControllerState, Never>) {
    self.signInState = signInState
  }

  func startObserving() {
    assert(self.eventResponder != nil)

    guard let _ = self.eventResponder else {
      return
    }

    if isObserving {
      return
    }

    subscribeToErrorMessages()
    subscribeToSignInViewState()
    startObservingKeyboardNotifications()
  }

  func stopObserving() {
    unsubscribeFromSignInViewState()
    unsubscribeFromErrorMessages()
    stopObservingNotificationCenterNotifications()
  }

  func subscribeToSignInViewState() {
    viewStateSubscription =
      signInState
        .receive(on: DispatchQueue.main)
        .map { $0.viewState }
        .removeDuplicates()
        .sink { [weak self] viewState in
          self?.received(newViewState: viewState)
        }
  }

  func received(newViewState: SignInViewState) {
    eventResponder?.received(newViewState: newViewState)
  }

  func unsubscribeFromSignInViewState() {
    viewStateSubscription = nil
  }

  func subscribeToErrorMessages() {
    errorStateSubscription =
      signInState
        .receive(on: DispatchQueue.main)
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

  func startObservingKeyboardNotifications() {
    let notificationCenter = NotificationCenter.default

    notificationCenter
      .addObserver(
        self,
        selector: #selector(
          handle(keyboardWillHideNotification:)),
        name: UIResponder.keyboardWillHideNotification,
        object: nil)

    notificationCenter
      .addObserver(
        self,
        selector: #selector(
          handle(keyboardWillChangeFrameNotification:)),
        name: UIResponder.keyboardWillChangeFrameNotification,
        object: nil)

    isObservingKeyboard = true
  }

  @objc func handle(
    keyboardWillHideNotification notification: Notification
  ) {
    assert(notification.name ==
      UIResponder.keyboardWillHideNotification)
    eventResponder?.keyboardWillHide()
  }

  @objc func handle(
    keyboardWillChangeFrameNotification
      notification: Notification
  ) {

    assert(notification.name ==
      UIResponder.keyboardWillChangeFrameNotification)

    guard let userInfo = notification.userInfo else {
      return
    }
    guard let keyboardEndFrameUserInfo =
      userInfo[UIResponder.keyboardFrameEndUserInfoKey] else {
        return
    }
    guard let keyboardEndFrame =
      keyboardEndFrameUserInfo as? NSValue else {
        return
    }

    eventResponder?
      .keyboardWillChangeFrame(
        keyboardEndFrame: keyboardEndFrame.cgRectValue)
  }

  func stopObservingNotificationCenterNotifications() {
    let notificationCenter = NotificationCenter.default
    notificationCenter.removeObserver(self)

    isObservingKeyboard = false
  }
}
