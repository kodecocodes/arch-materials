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
import KooberKit
import Combine


class ObserverForPickMeUpMap: Observer {

  // MARK: - Properties
  weak var eventResponder: ObserverForPickMeUpMapEventResponder? {
    willSet {
      if newValue == nil {
        stopObserving()
      }
    }
  }

  let mapState: AnyPublisher<MapViewControllerState, Never>
  var mapStateSubscription: AnyCancellable?

  private var isObserving: Bool {
    if mapStateSubscription != nil {
      return true
    } else {
      return false
    }
  }

  // MARK: - Methods
  init(mapState: AnyPublisher<MapViewControllerState, Never>) {
    self.mapState = mapState
  }

  func startObserving() {
    assert(self.eventResponder != nil)

    guard let _ = self.eventResponder else {
      return
    }

    if isObserving {
      return
    }

    subscribeToMapState()
  }

  func stopObserving() {
    unsubscribeFromMapState()
  }

  func subscribeToMapState() {
    mapStateSubscription =
      mapState
        .receive(on: DispatchQueue.main)
        .sink { [weak self] mapViewControllerState in
          self?.received(newMapState: mapViewControllerState)
        }
  }

  func received(newMapState mapState: MapViewControllerState) {
    eventResponder?.received(newMapState: mapState)
  }

  func unsubscribeFromMapState() {
    mapStateSubscription = nil
  }
}
