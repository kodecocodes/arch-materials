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

public class GettingUsersLocationRootView: NiblessView {

  // MARK: - Properties
  let appLogoImageView: UIImageView = {
    let imageView = UIImageView(image: UIImage(named: "roo_logo"))
    imageView.backgroundColor = Color.background
    return imageView
  }()

  let gettingLocationLabel: UILabel = {
    let label = UILabel()
    label.font = .boldSystemFont(ofSize: 24)
    label.text = "Finding your location..."
    label.textColor = .white
    return label
  }()

  // MARK: - Methods
  public override func didMoveToWindow() {
    super.didMoveToWindow()
    backgroundColor = Color.background
    constructHierarchy()
    activateConstraints()
  }
  
  func constructHierarchy() {
    addSubview(appLogoImageView)
    addSubview(gettingLocationLabel)
  }
  
  func activateConstraints() {
    activateConstraintsAppLogo()
    activateConstraintsLocationLabel()
  }
  
  func activateConstraintsAppLogo() {
    appLogoImageView.translatesAutoresizingMaskIntoConstraints = false
    let centerY = appLogoImageView.centerYAnchor
      .constraint(equalTo: centerYAnchor)
    let centerX = appLogoImageView.centerXAnchor
      .constraint(equalTo: centerXAnchor)
    NSLayoutConstraint.activate([centerY, centerX])
  }
  
  func activateConstraintsLocationLabel() {
    gettingLocationLabel.translatesAutoresizingMaskIntoConstraints = false
    let topY = gettingLocationLabel.topAnchor
      .constraint(equalTo: appLogoImageView.bottomAnchor, constant: 30)
    let centerX = gettingLocationLabel.centerXAnchor
      .constraint(equalTo: centerXAnchor)
    NSLayoutConstraint.activate([topY, centerX])
  }
}
