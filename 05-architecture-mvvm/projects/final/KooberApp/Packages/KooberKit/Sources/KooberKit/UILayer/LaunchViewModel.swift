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
import PromiseKit
import Combine

public class LaunchViewModel {

  // MARK: - Properties
  let userSessionRepository: UserSessionRepository
  let notSignedInResponder: NotSignedInResponder
  let signedInResponder: SignedInResponder

  public var errorMessages: AnyPublisher<ErrorMessage, Never> {
    errorMessagesSubject.eraseToAnyPublisher()
  }
  private let errorMessagesSubject = PassthroughSubject<ErrorMessage,Never>()
  public let errorPresentation = PassthroughSubject<ErrorPresentation?, Never>()
  private var subscriptions = Set<AnyCancellable>()

  // MARK: - Methods
  public init(userSessionRepository: UserSessionRepository,
              notSignedInResponder: NotSignedInResponder,
              signedInResponder: SignedInResponder) {
    self.userSessionRepository = userSessionRepository
    self.notSignedInResponder = notSignedInResponder
    self.signedInResponder = signedInResponder
  }

  public func loadUserSession() {
    userSessionRepository.readUserSession()
      .done(goToNextScreen(userSession:))
      .catch { error in
        let errorMessage = ErrorMessage(title: "Sign In Error",
                                        message: "Sorry, we couldn't determine if you are already signed in. Please sign in or sign up.")
        self.present(errorMessage: errorMessage)
      }
  }

  func present(errorMessage: ErrorMessage) {
    goToNextScreenAfterErrorPresentation()
    errorMessagesSubject.send(errorMessage)
  }

  func goToNextScreenAfterErrorPresentation() {
    errorPresentation
      .filter { $0 == .dismissed }
      .prefix(1)
      .sink { [weak self] _ in
        self?.goToNextScreen(userSession: nil)
    }.store(in: &subscriptions)
  }

  func goToNextScreen(userSession: UserSession?) {
    switch userSession {
    case .none:
      notSignedInResponder.notSignedIn()
    case .some(let userSession):
      signedInResponder.signedIn(to: userSession)
    }
  }
}
