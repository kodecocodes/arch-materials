/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import KooberKit

class SelectPickupAndDropoffViewController: UIViewController {
  @IBOutlet weak var stateLabel: UILabel!

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NotificationCenter.default.addStateChangeObserver(using: update(withState:))
    flushMessage()
  }

  func update(withState state: State) {
    switch state.selectedRideOptionAvailabilityLoadStatus {
    case .notLoaded:
      flushMessage()
    case .loaded(let selectionsState):
      if selectionsState.selectedPickupLocation == nil {
        configureForSelectingPickupLocation()
      } else if selectionsState.selectedPickupLocation != nil && selectionsState.selectedDropoffLocation == nil {
        configureForSelectingDropoffLocation()
      } else if selectionsState.selectedDropoffLocation != nil {
        flushMessage()
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(self)
  }
  
  func configureForSelectingPickupLocation() {
    stateLabel.text = "SELECT PICKUP LOCATION"
  }
  
  func configureForSelectingDropoffLocation() {
    stateLabel.text = "SELECT DROPOFF LOCATION"
  }

  func flushMessage() {
    stateLabel.text = ""
  }
  
}
