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

extension UIViewController {

  // MARK: - Methods
  public func addFullScreen(childViewController child: UIViewController) {
    guard child.parent == nil else {
      return
    }

    addChild(child)
    view.addSubview(child.view)

    child.view.translatesAutoresizingMaskIntoConstraints = false
    let constraints = [
      view.leadingAnchor.constraint(equalTo: child.view.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: child.view.trailingAnchor),
      view.topAnchor.constraint(equalTo: child.view.topAnchor),
      view.bottomAnchor.constraint(equalTo: child.view.bottomAnchor)
    ]
    constraints.forEach { $0.isActive = true }
    view.addConstraints(constraints)

    child.didMove(toParent: self)
  }

  public func remove(childViewController child: UIViewController?) {
    guard let child = child else {
      return
    }

    guard child.parent != nil else {
      return
    }
    
    child.willMove(toParent: nil)
    child.view.removeFromSuperview()
    child.removeFromParent()
  }
}
