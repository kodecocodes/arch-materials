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

extension UIColor {

  // MARK: - Methods
  /// Hex sRGB color initializer.
  ///
  /// - parameter hex: Pass in a sRGB color integer using hex notation, i.e. 0xFFFFFF. Make sure to only include 6 hex digits.
  ///
  /// - returns: Initialized opaque UIColor, i.e. alpha is set to 1.0.
  public convenience init(_ hex: Int) {
    assert(
      0...0xFFFFFF ~= hex,
      "UIColor+Hex: Hex value given to UIColor initializer should only include RGB values, i.e. the hex value should have six digits." //swiftlint:disable:this line_length
    )
    let red = (hex & 0xFF0000) >> 16
    let green = (hex & 0x00FF00) >> 8
    let blue = (hex & 0x0000FF)
    self.init(red: red, green: green, blue: blue)
  }

  /// RGB integer color initializer.
  ///
  /// - parameter red:   Red component as integer. In iOS 9 or below, this value should be between 0 and 255. iOS 10
  ///                    and above uses an extended color space to support wide color.
  /// - parameter green: Green component as integer. In iOS 9 or below, this value should be between 0 and 255. iOS 10
  ///                    and above uses an extended color space to support wide color.
  /// - parameter blue:  Blue component as integer. In iOS 9 or below, this value should be between 0 and 255. iOS 10
  ///                    and above uses an extended color space to support wide color.
  ///
  /// - returns: Initialized opaque UIColor, i.e. alpha is set to 1.0.
  public convenience init(red: Int, green: Int, blue: Int) {
    self.init(
      red: CGFloat(red) / 255.0,
      green: CGFloat(green) / 255.0,
      blue: CGFloat(blue) / 255.0,
      alpha:  1.0
    )
  }
}
