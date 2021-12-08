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

public class ProfileContentViewController: NiblessViewController {

  // MARK: - Properties
  // Observers
  let observer: Observer

  // User interface
  let userInterface: ProfileUserInterfaceView

  // Factories
  let dismissProfileUseCaseFactory: DismissProfileUseCaseFactory
  let signOutUseCaseFactory: SignOutUseCaseFactory
  let makeFinishedPresentingErrorUseCase: FinishedPresentingErrorUseCaseFactory

  // MARK: - Methods
  init(observer: Observer,
       userInterface: ProfileUserInterfaceView,
       dismissProfileUseCaseFactory: DismissProfileUseCaseFactory,
       signOutUseCaseFactory: SignOutUseCaseFactory,
       finishedPresentingErrorUseCaseFactory: @escaping FinishedPresentingErrorUseCaseFactory) {
    self.observer = observer
    self.userInterface = userInterface
    self.dismissProfileUseCaseFactory = dismissProfileUseCaseFactory
    self.signOutUseCaseFactory = signOutUseCaseFactory
    self.makeFinishedPresentingErrorUseCase = finishedPresentingErrorUseCaseFactory

    super.init()

    self.navigationItem.title = "My Profile"
    self.navigationItem.rightBarButtonItem =
      UIBarButtonItem(barButtonSystemItem: .done,
                      target: self,
                      action: #selector(dismissProfile))
  }

  public override func loadView() {
    view = userInterface
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    observer.startObserving()
  }

  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    observer.stopObserving()
  }

  @objc
  func dismissProfile() {
    let useCase = dismissProfileUseCaseFactory.makeDismissProfileUseCase()
    useCase.start()
  }

  func finishedPresenting(_ errorMessage: ErrorMessage) {
    let useCase = makeFinishedPresentingErrorUseCase(errorMessage)
    useCase.start()
  }
}

extension ProfileContentViewController: ObserverForProfileEventResponder {
  func received(newUserProfile userProfile: UserProfile) {
    userInterface.render(userProfile: userProfile)
  }

  func received(newErrorMessage errorMessage: ErrorMessage) {
    present(errorMessage: errorMessage) { [weak self] in
      self?.finishedPresenting(errorMessage)
    }
  }
}

extension ProfileContentViewController: ProfileIxResponder {

  func signOut() {
    let useCase = signOutUseCaseFactory.makeSignOutUseCase()
    useCase.start()
  }
}
