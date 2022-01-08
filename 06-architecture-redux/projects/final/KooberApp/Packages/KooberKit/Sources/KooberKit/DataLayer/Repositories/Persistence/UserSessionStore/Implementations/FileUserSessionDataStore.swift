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

public class FileUserSessionDataStore: UserSessionDataStore {

  // MARK: - Properties
  var docsURL: URL? {
    return FileManager
      .default.urls(for: FileManager.SearchPathDirectory.documentDirectory,
                    in: FileManager.SearchPathDomainMask.allDomainsMask).first
  }

  // MARK: - Methods
  public init() {
  }

  public func readUserSession() -> Promise<UserSession?> {
    return Promise() { seal in
      guard let docsURL = docsURL else {
        seal.reject(KooberKitError.any)
        return
      }
      guard let jsonData = try? Data(contentsOf: docsURL.appendingPathComponent("user_session.json")) else {
        seal.fulfill(nil)
        return
      }
      let decoder = JSONDecoder()
      let userSession = try! decoder.decode(UserSession.self, from: jsonData)
      seal.fulfill(userSession)
    }
  }

  public func save(userSession: UserSession) -> Promise<UserSession> {
    return Promise() { seal in
      let encoder = JSONEncoder()
      let jsonData = try! encoder.encode(userSession)

      guard let docsURL = docsURL else {
        seal.reject(KooberKitError.any)
        return
      }
      try? jsonData.write(to: docsURL.appendingPathComponent("user_session.json"))
      seal.fulfill(userSession)
    }
  }

  public func deleteUserSession() -> Promise<Void> {
    return readUserSession()
            .then(delete(userSession:))
  }

  private func delete(userSession: UserSession?) -> Promise<Void> {
    guard let _ = userSession else {
      return .value(())
    }
    return Promise() { seal in
      guard let docsURL = docsURL else {
        seal.reject(KooberKitError.any)
        return
      }
      do {
        try FileManager.default.removeItem(at: docsURL.appendingPathComponent("user_session.json"))
      } catch {
        seal.reject(KooberKitError.any)
        return
      }
      seal.fulfill(())
    }
  }
}
