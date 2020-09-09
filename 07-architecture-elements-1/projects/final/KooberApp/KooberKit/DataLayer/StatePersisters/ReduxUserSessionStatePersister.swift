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
import ReSwift
import Combine

public class ReduxUserSessionStatePersister: UserSessionStatePersister {

  // MARK: - Properties
  let authenticationStatePublisher: AnyPublisher<AuthenticationState?, Never>
  var subscriptions = Set<AnyCancellable>()

  // MARK: - Methods
  public init(reduxStore: Store<AppState>) {
    let runningGetters = AppRunningGetters(getAppRunningState: EntryPointGetters().getAppRunningState)
    self.authenticationStatePublisher =
      reduxStore.publisher { subscription in
        subscription.select(runningGetters.getAuthenticationState)
      }
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  public func startPersistingStateChanges(to userSessionDataStore: UserSessionDataStore) {
    self.authenticationStatePublisher
      .receive(on: DispatchQueue.main)
      .dropFirst(1)
      .sink { [weak self] authenticationState in
        self?.on(authenticationState: authenticationState, with: userSessionDataStore)
      }
      .store(in: &subscriptions)
  }

  private func on(authenticationState: AuthenticationState?, with userSessionDataStore: UserSessionDataStore) {
    guard let authenticationState = authenticationState else {
      assertionFailure("startPersistingStateChanges called while app was launching.")
      return
    }

    switch authenticationState {
    case .notSignedIn:
      deleteUserSession(from: userSessionDataStore)
    case .signedIn(let userSession):
      persist(userSession, to: userSessionDataStore)
    }
  }

  private func persist(_ userSession: UserSession, to userSessionDataStore: UserSessionDataStore) {
    userSessionDataStore
      .save(userSession: userSession)
      .catch { error in
        assertionFailure("Failed to persist user session.")
      }
  }

  private func deleteUserSession(from userSessionDataStore: UserSessionDataStore) {
    userSessionDataStore
      .deleteUserSession()
      .catch { error in
        assertionFailure("Failed to delete user session.")
      }
  }
}
