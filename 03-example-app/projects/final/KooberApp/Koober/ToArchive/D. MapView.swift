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

import MapKit
import PromiseKit

class MapView: MKMapView {
  let defaultMapCenterCoordinate = CLLocationCoordinate2D(latitude: -33.864308, longitude: 151.209146)
  let defaultMapSpan = MKCoordinateSpan(latitudeDelta: 0.0135, longitudeDelta: 0.0135)
  let mapDropoffLocationSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)

  var onSelectPickupLocation: ((String) -> Void)?
  var onSelectDropoffLocation: ((String) -> Void)?

  var imageCache: ImageCache!

  var viewModel = MapViewModel() {
    didSet {
      let currentAnnotations = (annotations as! [MapAnnotation]) // In real world, cast instead of force unwrap.
      let updatedAnnotations = viewModel.availableRideLocationAnnotations
                                + viewModel.pickupLocationAnnotations
                                + viewModel.dropoffLocationAnnotations

      let diff = MapAnnotionDiff.diff(currentAnnotations: currentAnnotations, updatedAnnotations: updatedAnnotations)
      removeAnnotations(diff.annotationsToRemove)
      addAnnotations(diff.annotationsToAdd)

      if !viewModel.dropoffLocationAnnotations.isEmpty {
        zoomOutToShowDropoffLocation()
      } else {
        zoomIn()
      }
    }
  }

  override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)

    guard newWindow != nil else {
      delegate = nil
      return
    }

    delegate = self
    zoomIn()
  }

  func zoomIn() {
    let center = defaultMapCenterCoordinate
    let span = defaultMapSpan
    let region = MKCoordinateRegion(center: center, span: span)
    setRegion(region, animated: true)
  }

  func zoomOutToShowDropoffLocation() {
    let center = defaultMapCenterCoordinate
    let span = mapDropoffLocationSpan
    let region = MKCoordinateRegion(center: center, span: span)
    setRegion(region, animated: true)
  }

}

extension MapView: MKMapViewDelegate {

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard let annotation = annotation as? MapAnnotation else {
      return nil
    }
    let reuseID = reuseIdentifier(forAnnotation: annotation)
    guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) else {
      return MapAnnotationView(annotation: annotation, reuseIdentifier: reuseID, imageCache: imageCache)
    }
    annotationView.annotation = annotation
    return annotationView
  }

  func reuseIdentifier(forAnnotation annotation: MapAnnotation) -> String {
    return annotation.imageIdentifier
  }

  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    guard let annotationView = view as? MapAnnotationView else {
      return
    }
    guard let annotationID = annotationView.mapAnnotation?.id,
          let annotationType = annotationView.mapAnnotation?.type else {
      return
    }

    switch annotationType {
    case .pickupLocation:
      onSelectPickupLocation?(annotationID)
    case .dropoffLocation:
      onSelectDropoffLocation?(annotationID) 
    case .availableRide:
      return
    }

  }

}
