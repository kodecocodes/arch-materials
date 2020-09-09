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

public typealias RideOptionID = String

public struct RideOption: Equatable, Identifiable, Decodable {

  // MARK: - Properties
  public var id: RideOptionID
  public var name: String
  public var buttonRemoteImages: (selected: RemoteImage, unselected: RemoteImage)
  public var availableMapMarkerRemoteImage: RemoteImage

  // MARK: - Methods
  public init(id: RideOptionID,
              name: String,
              buttonRemoteImages: (RemoteImage, RemoteImage),
              availableMapMarkerRemoteImage: RemoteImage) {
    self.id = id
    self.name = name
    self.buttonRemoteImages = buttonRemoteImages
    self.availableMapMarkerRemoteImage = availableMapMarkerRemoteImage
  }

  public static func ==(lhs: RideOption, rhs: RideOption) -> Bool {
    return lhs.id == rhs.id
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case segmentSelectedImageLocation
    case segmentImageLocation
    case availableMapMarkerImageLocation
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    id =
      try values.decode(RideOptionID.self, forKey: .id)
    name =
      try values.decode(String.self, forKey: .name)

    let selectedImage =
      try values.decode(RemoteImage.self, forKey: .segmentSelectedImageLocation)
    let unselectedImage =
      try values.decode(RemoteImage.self, forKey: .segmentImageLocation)
    buttonRemoteImages = (selectedImage, unselectedImage)

    availableMapMarkerRemoteImage =
      try values.decode(RemoteImage.self, forKey: .availableMapMarkerImageLocation)
  }
}


