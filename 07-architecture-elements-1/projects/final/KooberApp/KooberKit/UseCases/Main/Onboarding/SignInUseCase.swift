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

public class SignInUseCase: UseCase {

  // MARK: - Properties
  // Input data
  let username: String
  let password: Secret

  // Side-effect subsystems
  let remoteAPI: AuthRemoteAPI
  let actionDispatcher: ActionDispatcher

  // MARK: - Methods
  public init(
    username: String,
    password: String,
    remoteAPI: AuthRemoteAPI,
    actionDispatcher: ActionDispatcher
  ) {
    // Input data
    self.username = username
    self.password = password

    // Side-effect subsystems
    self.remoteAPI = remoteAPI
    self.actionDispatcher = actionDispatcher
  }

  public func start() {
    assert(Thread.isMainThread)

    self.actionDispatcher.dispatch(SignInActions.SigningIn())

    firstly {
      self.remoteAPI.signIn(username: username,
                            password: password)
    }.done { userSession in
      let action =
        SignInActions.SignedIn(userSession: userSession)
      self.actionDispatcher.dispatch(action)
    }.catch { error in
      let errorMessage =
        ErrorMessage(title: "Sign In Failed",
                     message: """
                              Could not sign in.
                              Please try again.
                              """)
      let action =
        SignInActions.SignInFailed(errorMessage: errorMessage)
      self.actionDispatcher.dispatch(action)
    }
  }
}


public protocol SignInUseCaseFactory {

  func makeSignInUseCase(
    username: String,
    password: Secret
  ) -> UseCase
}
