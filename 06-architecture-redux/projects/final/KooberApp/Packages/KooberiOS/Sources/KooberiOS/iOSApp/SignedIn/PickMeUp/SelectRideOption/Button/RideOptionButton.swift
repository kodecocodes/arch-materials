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

import CoreGraphics
import UIKit
import KooberKit

class RideOptionButton: UIButton {

  // MARK: - Properties
  var nameLabel: UILabel = UILabel()
  let id: String

  var didSelectRideOption: ((String) -> ())?

  // MARK: - Methods
  init(segment: RideOptionSegmentState) {
    self.id = segment.id
    super.init(frame: .zero)

    self.bounds = CGRect(x: 0, y: 0, width: 78, height: 110)
    self.isSelected = segment.isSelected

    guard case let .loaded(_, normalImage, _, selectedImage) = segment.images else {
      let normalImage = #imageLiteral(resourceName: "ride_option_placeholder")
      let selectedImage = #imageLiteral(resourceName: "ride_option_placeholder_selected")
      set(image: normalImage, selectedImage: selectedImage, title: segment.title)
      return
    }

    set(image: normalImage, selectedImage: selectedImage, title: segment.title)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("RideOptionButton does not support initialization via NSCoding.")
  }

  override func willMove(toSuperview newSuperview: UIView?) {
    super.willMove(toSuperview: newSuperview)

    addSubview(nameLabel)
    addTarget(self,
              action: #selector(RideOptionButton.tapped(button:)),
              for: .touchUpInside)
  }

  @objc
  func tapped(button: UIButton) {
    didSelectRideOption?(id)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let height = bounds.height
    let width = bounds.width
    let labelHeight = CGFloat(20.0)
    
    nameLabel.bounds = CGRect(x: 0, y: 80, width: width, height: labelHeight)
    nameLabel.center = CGPoint(x: width / 2.0, y: CGFloat(height - labelHeight))
  }
  
  private func set(image anImage: UIImage, selectedImage: UIImage, title: String) {
    setImage(anImage, for: .normal)
    setImage(selectedImage, for: .selected)
    imageView?.contentMode = .center
    nameLabel.text = title
    nameLabel.textAlignment = .center
    nameLabel.textColor = .white
    nameLabel.font = .systemFont(ofSize: 15.0)
  }
}
