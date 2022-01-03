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

  public static func appReducer(action: Action, state: AppState?) -> AppState {
    var state = state ?? .launching(LaunchViewControllerState())

    switch action {
    case let action as LaunchingActions.FinishedLaunchingApp:
      let authenticatedState = action.authenticationState
      state = AppLogic.appState(for: authenticatedState)
    case let action as LaunchingActions.FinishedPresentingLaunchError:
      guard case .launching(var launchingViewControllerState) = state else {
        break
      }
      launchingViewControllerState.errorsToPresent.remove(action.errorMessage)
      if launchingViewControllerState.errorsToPresent.count == 0 {
        state = .running(.onboarding(.welcoming))
      } else {
        state = .launching(launchingViewControllerState)
      }
    default:
      break
    }

    switch state {
    case .launching(let launchViewControllerState):
      state = .launching(Reducers.launchingReducer(action: action,
                                                   state: launchViewControllerState))
    case .running(let runningState):
      state = .running(Reducers.appRunningReducer(action: action,
                                                  state: runningState))
    }

    return state
  }
}
