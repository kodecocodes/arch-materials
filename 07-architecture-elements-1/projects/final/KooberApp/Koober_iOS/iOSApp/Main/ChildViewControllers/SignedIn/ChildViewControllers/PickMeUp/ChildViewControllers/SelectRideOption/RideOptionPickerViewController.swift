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

public class RideOptionPickerViewController: NiblessViewController {

  // MARK: - Properties
  // Observers
  let observer: Observer

  // User interface
  let userInterface: RideOptionPickerUserInterfaceView

  // State
  let pickupLocation: Location
  var selectedRideOptionID: RideOptionID?

  // Factories
  let loadRideOptionsUseCaseFactory: LoadRideOptionsUseCaseFactory
  let selectRideOptionUseCaseFactory: SelectRideOptionUseCaseFactory
  let makeFinishedPresentingErrorUseCase: FinishedPresentingErrorUseCaseFactory

  // MARK: - Methods
  init(pickupLocation: Location,
       observer: Observer,
       userInterface: RideOptionPickerUserInterfaceView,
       loadRideOptionsUseCaseFactory: LoadRideOptionsUseCaseFactory,
       selectRideOptionUseCaseFactory: SelectRideOptionUseCaseFactory,
       finishedPresentingErrorUseCaseFactory: @escaping FinishedPresentingErrorUseCaseFactory) {
    self.pickupLocation = pickupLocation
    self.observer = observer
    self.userInterface = userInterface
    self.loadRideOptionsUseCaseFactory = loadRideOptionsUseCaseFactory
    self.selectRideOptionUseCaseFactory = selectRideOptionUseCaseFactory
    self.makeFinishedPresentingErrorUseCase = finishedPresentingErrorUseCaseFactory
    super.init()
  }

  public override func loadView() {
    view = userInterface
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    loadRideOptions()
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    observer.startObserving()
  }

  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    observer.stopObserving()
  }

  func loadRideOptions() {
    let pickupLocation = self.pickupLocation
    let screenScale = UIScreen.main.scale
    let useCase =
      loadRideOptionsUseCaseFactory
        .makeLoadRideOptionsUseCase(
          pickupLocation: pickupLocation,
          screenScale: screenScale
      )
    useCase.start()
  }

  func finishedPresenting(_ errorMessage: ErrorMessage) {
    let useCase = makeFinishedPresentingErrorUseCase(errorMessage)
    useCase.start()
  }

  class SegmentedControlStateReducer {

    static func reduce(from rideOptions: RideOptionPickerRideOptions) -> RideOptionSegmentedControlState {
      let segments = RideOptionSegmentsFactory(state: rideOptions).makeSegments(screenScale: UIScreen.main.scale)
      return RideOptionSegmentedControlState(segments: segments)
    }
  }
}

extension RideOptionPickerViewController: ObserverForRideOptionPickerEventResponder {

  func received(newRideOptionSegmentedControlState rideOptionSegmentedControlState: RideOptionSegmentedControlState) {
    userInterface.render(newState: rideOptionSegmentedControlState)
  }

  func received(newErrorMessage errorMessage: ErrorMessage) {
    present(errorMessage: errorMessage) { [weak self] in
      self?.finishedPresenting(errorMessage)
    }
  }
}

extension RideOptionPickerViewController: RideOptionPickerIxResponder {

  func select(rideOption rideOptionID: RideOptionID) {
    let useCase = selectRideOptionUseCaseFactory.makeSelectRideOptionUseCase(rideOptionID: rideOptionID)
    useCase.start()
  }
}
