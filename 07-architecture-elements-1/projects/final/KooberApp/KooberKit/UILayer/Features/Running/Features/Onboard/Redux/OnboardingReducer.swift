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

extension Reducers {
  
  static func onboardingReducer(action: Action, state: OnboardingState?) -> OnboardingState {
    var state = state ?? .welcoming

    switch action {
    case _ as WelcomeActions.GoToSignUp:
      state = OnboardingLogic.goToSignUp()
    case _ as WelcomeActions.GoToSignIn:
      state = OnboardingLogic.goToSignIn()
    case _ as OnboardingActions.NavigatedBackToWelcome:
      state = OnboardingLogic.navigatedBackToWelcome()
    default:
      break
    }

    switch state {
    case .signingUp(let signUpViewControllerState):
      state = .signingUp(Reducers.signUpReducer(action: action,
                                                state: signUpViewControllerState))
    case .signingIn(let signInViewControllerState):
      state = .signingIn(Reducers.signInReducer(action: action,
                                                state: signInViewControllerState))
      break
    case .welcoming:
      break
    }

    return state
  }
}
