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
import PromiseKit

public class RideOptionDataStoreDiskUserPrefs: RideOptionDataStore {

  // MARK: - Properties
  let accessQueue = DispatchQueue(label: "com.razeware.kooberkit.rideoptiondatastore.userprefs.access")
  var locationIDs: Set<LocationID> = []

  // MARK: - Methods
  public init() {}

  public func update(rideOptions: [RideOption], availableAt pickupLocationID: LocationID) -> Promise<[RideOption]> {
    return Promise { seal in
      self.accessQueue.async {
        let dictionaries = rideOptions.map(RideOption.asDictionary)
        UserDefaults.standard.set(dictionaries,
                                  forKey: pickupLocationID.userPreferencesKey)
        self.locationIDs.insert(pickupLocationID)
        seal.fulfill(rideOptions)
      }
    }
  }

  public func read(availableAt pickupLocationID: LocationID) -> Promise<[RideOption]> {
    return Promise { seal in
      self.accessQueue.async {
        let key = pickupLocationID.userPreferencesKey
        guard let dictionaries = UserDefaults.standard.array(forKey: key) as? [[String: Any]] else {
          seal.fulfill([])
          return
        }
        let rideOptions = dictionaries.map(RideOption.make(withEncodedDictionary:))
        seal.fulfill(rideOptions)
      }
    }
  }

  public func flush() {
    self.accessQueue.async {
      self.locationIDs.forEach(self.flush(availableAt:))
      self.locationIDs.removeAll()
    }
  }

  private func flush(availableAt pickupLocationID: LocationID) {
    UserDefaults.standard.removeObject(forKey: pickupLocationID.userPreferencesKey)
  }
}

private extension LocationID {

  var userPreferencesKey: String {
    return "ride_options_at_\(self)"
  }
}

extension RemoteImage {

  static func make(withEncodedDictionary dictionary: [String: String]) -> RemoteImage {
    let at1xURL = URL(string: dictionary["at1xURL"]!)!
    let at2xURL = URL(string: dictionary["at2xURL"]!)!
    let at3xURL = URL(string: dictionary["at3xURL"]!)!
    return RemoteImage(at1xURL: at1xURL, at2xURL: at2xURL, at3xURL: at3xURL)
  }

  func asDictionary() -> [String: String] {
    return ["at1xURL" : at1xURL.absoluteString,
            "at2xURL" : at2xURL.absoluteString,
            "at3xURL" : at3xURL.absoluteString]
  }
}

extension RideOption {
  
  static func make(withEncodedDictionary dictionary: [String: Any]) -> RideOption {
    let id = dictionary["id"]! as! String
    let name = dictionary["name"]! as! String
    let buttonRemoteImages = (RemoteImage.make(withEncodedDictionary: dictionary["buttonSelectedRemoteImage"] as! [String: String]), RemoteImage.make(withEncodedDictionary: dictionary["buttonRemoteImage"] as! [String: String]))
    let availableMapMarkerRemoteImage = RemoteImage.make(withEncodedDictionary: dictionary["availableMapMarkerRemoteImage"] as! [String: String])
    return RideOption(id: id,
                      name: name,
                      buttonRemoteImages: buttonRemoteImages,
                      availableMapMarkerRemoteImage: availableMapMarkerRemoteImage)
  }

  func asDictionary() -> [String: Any] {
    return ["id": id,
            "name": name,
            "buttonRemoteImage": buttonRemoteImages.unselected.asDictionary(),
            "buttonSelectedRemoteImage": buttonRemoteImages.selected.asDictionary(),
            "availableMapMarkerRemoteImage": availableMapMarkerRemoteImage.asDictionary()]
    
  }
}
