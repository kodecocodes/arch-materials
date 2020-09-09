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

class KeychainItem {

  // MARK: - Properties
  let service: NSString = "KooberCloud"
  let itemClass = kSecClass as String
  let itemService = kSecAttrService as String

  // MARK: - Methods
  func asDictionary() -> CFDictionary {
    let item: [String: AnyObject] = [itemClass: kSecClassGenericPassword,
                                     itemService: service]
    return item as CFDictionary
  }
}

class KeychainItemWithData: KeychainItem {

  // MARK: - Properties
  let data: AnyObject
  let itemData = kSecValueData as String

  // MARK: - Methods
  init(data: Data) {
    self.data = data as AnyObject
  }

  override func asDictionary() -> CFDictionary {
    let item: [String: AnyObject] = [itemClass: kSecClassGenericPassword,
                                     itemService: service,
                                     itemData: data]
    return item as CFDictionary
  }

  func attributesAsDictionary() -> CFDictionary {
    let attributes: [String: AnyObject] = [itemClass: kSecClassGenericPassword,
                                           itemService: service]
    return attributes as CFDictionary
  }

  func dataAsDictionary() -> CFDictionary {
    let justData: [String: AnyObject] = [itemData: data]
    return justData as CFDictionary
  }
}

class KeychainItemQuery: KeychainItem {

  // MARK: - Properties
  let matchLimit = kSecMatchLimit as String
  let returnData = kSecReturnData as String

  // MARK: - Methods
  override func asDictionary() -> CFDictionary {
    let query: [String: AnyObject] = [itemClass: kSecClassGenericPassword,
                                      itemService: service,
                                      matchLimit: kSecMatchLimitOne,
                                      returnData: kCFBooleanTrue]
    return query as CFDictionary
  }
}
