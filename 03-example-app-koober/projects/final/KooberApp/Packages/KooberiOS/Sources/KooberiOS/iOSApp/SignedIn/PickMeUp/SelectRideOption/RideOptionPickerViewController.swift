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
import Combine

public class RideOptionPickerViewController: NiblessViewController {

  // MARK: - Properties
  // Dependencies
  let imageCache: ImageCache

  // State
  let viewModel: RideOptionPickerViewModel
  let pickupLocation: Location
  var selectedRideOptionID: RideOptionID?
  private var subscriptions = Set<AnyCancellable>()

  // Root View
  var rideOptionSegmentedControl: RideOptionSegmentedControl {
    return view as! RideOptionSegmentedControl
  }

  // MARK: - Methods
  init(pickupLocation: Location,
       imageCache: ImageCache,
       viewModelFactory: RideOptionPickerViewModelFactory) {
    self.pickupLocation = pickupLocation
    self.imageCache = imageCache
    self.viewModel =
      viewModelFactory.makeRideOptionPickerViewModel()
    super.init()
  }

  public override func loadView() {
    view = RideOptionSegmentedControl(frame: .zero,
                                      imageCache: imageCache,
                                      mvvmViewModel: viewModel)
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    rideOptionSegmentedControl
      .loadRideOptions(availableAt: pickupLocation)
    observeErrorMessages()
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  func observeErrorMessages() {
    viewModel
      .errorMessages
      .receive(on: DispatchQueue.main)
      .sink { [weak self] errorMessage in
        self?.present(errorMessage)
      }.store(in: &subscriptions)
  }

  class SegmentedControlStateReducer {
    static func reduce(from rideOptions: RideOptionPickerRideOptions) -> RideOptionSegmentedControlViewModel {
      let segments = RideOptionSegmentsFactory(state: rideOptions).makeSegments(screenScale: UIScreen.main.scale)
      return RideOptionSegmentedControlViewModel(segments: segments)
    }
  }
}

protocol RideOptionPickerViewModelFactory {
  
  func makeRideOptionPickerViewModel() -> RideOptionPickerViewModel
}
