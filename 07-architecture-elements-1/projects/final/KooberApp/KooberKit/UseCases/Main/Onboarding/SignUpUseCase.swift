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

public class SignUpUseCase: UseCase {
  let newAccount: NewAccount
  let remoteAPI: AuthRemoteAPI
  let actionDispatcher: ActionDispatcher

  public private(set) var userSession: UserSession?

  public init(newAccount: NewAccount,
              remoteAPI: AuthRemoteAPI,
              actionDispatcher: ActionDispatcher) {
    self.newAccount = newAccount
    self.remoteAPI = remoteAPI
    self.actionDispatcher = actionDispatcher
  }

  public func start() {
    remoteAPI.signUp(account: newAccount)
      .done(signedIn(to:))
      .catch(handleSignUpError)
  }

  private func signedIn(to userSession: UserSession) {
    let action = SignInActions.SignedIn(userSession: userSession)
    actionDispatcher.dispatch(action)
  }

  private func handleSignUpError(_ error: Error) {
    let errorMessage = ErrorMessage(title: "Sign Up Failed",
                                    message: "Could not sign up.\nPlease try again.")
    let action = SignUpActions.SignUpFailed(errorMessage: errorMessage)
    actionDispatcher.dispatch(action)
  }
}

public protocol SignUpUseCaseFactory {

  func makeSignUpUseCase(newAccount: NewAccount) -> UseCase
}
