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
import MapKit
import KooberKit

class MapViewController: UIViewController {
  @IBOutlet weak var mapView: MapView!

  var imageCache: ImageCache!

  var startSelectPickupLocationUseCase: ((LocationID) -> SelectPickupLocationUseCase)!
  var startSelectDropoffLocationUseCase: ((LocationID) -> SelectDropoffLocationUseCase)!

  override func viewDidLoad() {
    super.viewDidLoad()
    mapView.imageCache = imageCache
    mapView.onSelectPickupLocation = { [weak self] selectedPickupLocationID in
      _ = self?.startSelectPickupLocationUseCase(selectedPickupLocationID)
    }
    mapView.onSelectDropoffLocation = { [weak self] selectedDropoffLocationID in
      _ = self?.startSelectDropoffLocationUseCase(selectedDropoffLocationID)
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NotificationCenter.default.addStateChangeObserver(using: update(withState:))
  }

  func update(withState state: State) {
    switch state.selectedRideOptionAvailabilityLoadStatus {
    case .notLoaded:
      mapView.viewModel = MapViewModel()
    case .loaded(let state):
      mapView.viewModel = MapStateReducer.reduce(from: state)
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(self)
  }

  class MapStateReducer {
    static func reduce(from selectionsState: SelectionsState) -> MapViewModel {
      let availableRideLocationAnnotations =
        AvailableRideLocationMapAnnotationsFactory(selectionsState: selectionsState).makeAnnotations()
      let pickupLocationAnnotations =
        PickupLocationMapAnnotationsFactory(selectionsState: selectionsState).makeAnnotations()
      let dropoffLocationAnnotations =
        DropoffLocationMapAnnotationsFactory(selectionsState: selectionsState).makeAnnotations()

      return MapViewModel(pickupLocationAnnotations: pickupLocationAnnotations,
                          dropoffLocationAnnotations: dropoffLocationAnnotations,
                          availableRideLocationAnnotations: availableRideLocationAnnotations)
    }
  }
  
}
