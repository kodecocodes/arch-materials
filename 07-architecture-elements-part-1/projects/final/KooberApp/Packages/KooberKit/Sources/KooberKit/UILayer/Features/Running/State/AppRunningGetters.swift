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

public struct AppRunningGetters {

  // MARK: - Properties
  public let getAppRunningState: (AppState) -> ScopedState<AppRunningState>

  // MARK: - Methods
  public init(getAppRunningState: @escaping (AppState) -> ScopedState<AppRunningState>) {
    self.getAppRunningState = getAppRunningState
  }

  public func getOnboardingState(appState: AppState) -> ScopedState<OnboardingState> {
    let runningScopedState = getAppRunningState(appState)
    guard case .inScope(let runningState) = runningScopedState else {
      return .outOfScope
    }
    guard case .onboarding(let onboardingState) = runningState else {
      return .outOfScope
    }
    return .inScope(onboardingState)
  }

  public func getSignedInViewControllerState(appState: AppState) -> ScopedState<SignedInViewControllerState> {
    let runningScopedState = getAppRunningState(appState)
    guard case .inScope(let runningState) = runningScopedState else {
      return .outOfScope
    }
    guard case .signedIn(let signedInViewControllerState, _) = runningState else {
      return .outOfScope
    }
    return .inScope(signedInViewControllerState)
  }

  public func getAuthenticationState(appState: AppState) -> AuthenticationState? {
    let runningScopedState = getAppRunningState(appState)
    guard case .inScope(let runningState) = runningScopedState else {
      return nil
    }
    guard case .signedIn(_, let userSession) = runningState else {
      return .notSignedIn
    }
    return .signedIn(userSession)
  }
}
