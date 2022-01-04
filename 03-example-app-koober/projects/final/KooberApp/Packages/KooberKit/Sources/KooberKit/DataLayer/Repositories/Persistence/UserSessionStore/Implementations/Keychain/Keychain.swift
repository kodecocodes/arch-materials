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

class Keychain {

  // MARK: - Methods
  static func findItem(query: KeychainItemQuery) throws -> Data? {
    var queryResult: AnyObject?
    let status = withUnsafeMutablePointer(to: &queryResult) {
      SecItemCopyMatching(query.asDictionary(), UnsafeMutablePointer($0))
    }

    if status == errSecItemNotFound {
      return nil
    }
    guard status == noErr else {
      throw KeychainUserSessionDataStoreError.unknown
    }
    guard let itemData = queryResult as? Data else {
      throw KeychainUserSessionDataStoreError.typeCast
    }

    return itemData
  }

  static func save(item: KeychainItemWithData) throws {
    let status = SecItemAdd(item.asDictionary(), nil)
    guard status == noErr else {
      throw KeychainUserSessionDataStoreError.unknown
    }
  }

  static func update(item: KeychainItemWithData) throws {
    let status = SecItemUpdate(item.attributesAsDictionary(), item.dataAsDictionary())
    guard status == noErr else {
      throw KeychainUserSessionDataStoreError.unknown
    }
  }

  static func delete(item: KeychainItem) throws {
    let status = SecItemDelete(item.asDictionary())
    guard status == noErr || status == errSecItemNotFound else {
      throw KeychainUserSessionDataStoreError.unknown
    }
  }
}
