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
import PromiseKit
import Combine

class RideOptionSegmentedControl: UIControl {

  // MARK: - Properties
  let mvvmViewModel: RideOptionPickerViewModel
  var viewModel = RideOptionSegmentedControlViewModel() {
    didSet {
      if oldValue != viewModel {
        loadAndRecreateButtons(withSegments: viewModel.segments)
      } else {
        update(withSegments: viewModel.segments)
      }
    }
  }
  private var subscriptions = Set<AnyCancellable>()

  private let maxRideOptionSegments = 3
  private let imageLoader: RideOptionSegmentButtonImageLoader
  private var buttons: [RideOptionID: RideOptionButton] = [:]
  private var rideOptionStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.distribution = .equalSpacing
    return stackView
  }()


  // MARK: - Methods
  init(frame: CGRect = .zero,
       imageCache: ImageCache,
       mvvmViewModel: RideOptionPickerViewModel) {
    self.imageLoader = RideOptionSegmentButtonImageLoader(imageCache: imageCache)
    self.mvvmViewModel = mvvmViewModel
    super.init(frame: frame)

    constructViewHierarchy()
    wireMVVMViewModel()
  }

  func wireMVVMViewModel(){
    mvvmViewModel
      .$pickerSegments
      .receive(on: DispatchQueue.main)
      .assign(to: \.viewModel, on: self)
      .store(in: &subscriptions)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("RideOptionSegmentedControl does not support instantiation via NSCoding.")
  }

  private func constructViewHierarchy() {

    func applyConstraints(toBackgroundBanner backgroundBanner: UIView) {
      backgroundBanner.translatesAutoresizingMaskIntoConstraints = false
      backgroundBanner.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
      backgroundBanner.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
      backgroundBanner.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5).isActive = true
      backgroundBanner.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    func applyConstraints(toRideOptionStackView rideOptionStackView: UIStackView) {
      rideOptionStackView.translatesAutoresizingMaskIntoConstraints = false
      rideOptionStackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
      rideOptionStackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
      rideOptionStackView.heightAnchor.constraint(equalToConstant: 140.0).isActive = true
      rideOptionStackView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }

    let backgroundBanner = UIView()
    backgroundBanner.backgroundColor = UIColor(red: 0,
                                               green: 205/255.0,
                                               blue: 188/255.0,
                                               alpha: 1)

    addSubview(backgroundBanner)
    applyConstraints(toBackgroundBanner: backgroundBanner)

    addSubview(rideOptionStackView)
    applyConstraints(toRideOptionStackView: rideOptionStackView)
  }

  private func update(withSegments segments: [RideOptionSegmentViewModel]) {
    segments.forEach(update(withSegment:))
  }

  private func update(withSegment segment: RideOptionSegmentViewModel) {
    buttons[segment.id]?.isSelected = segment.isSelected
  }

  private func loadAndRecreateButtons(withSegments segments:  [RideOptionSegmentViewModel]) {
    loadButtonImages().done { loadedSegments in
      guard loadedSegments == self.viewModel.segments else {
        return
      }
      self.recreateButtons(withSegments: loadedSegments)
      }.catch { error in
        self.recreateButtons(withSegments: segments)
      }
  }

  func loadRideOptions(availableAt pickupLocation: Location) {
    mvvmViewModel.loadRideOptions(availableAt: pickupLocation,
                                  screenScale: UIScreen.main.scale)
  }

  private func loadButtonImages() -> Promise<[RideOptionSegmentViewModel]> {
    return imageLoader.loadImages(using: viewModel.segments)
  }

  private func recreateButtons(withSegments segments: [RideOptionSegmentViewModel]) {
    rideOptionStackView.removeAllArangedSubviews()
    segments.prefix(maxRideOptionSegments)
      .map(makeRideOptionButton(forSegment:))
      .map { id, button in
        store(button: button, forID: id)
      }
      .forEach(rideOptionStackView.addArrangedSubview)
  }

  private func makeRideOptionButton(forSegment segment: RideOptionSegmentViewModel) -> (RideOptionID, RideOptionButton) {
    let button = RideOptionButton(segment: segment)
    button.didSelectRideOption = { [weak self] id in
      self?.mvvmViewModel.select(rideOptionID: id)
    }
    return (segment.id, button)
  }

  private func store(button: RideOptionButton, forID id: RideOptionID) -> RideOptionButton {
    buttons[id] = button
    return button
  }
}
