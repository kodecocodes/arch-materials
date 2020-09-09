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
import KooberUIKit
import KooberKit
import Combine

enum CellIdentifier: String {

  case cell
}

class DropoffLocationPickerContentRootView: NiblessView {

  // MARK: - Properties
  let viewModel: DropoffLocationPickerViewModel
  private var subscriptions = Set<AnyCancellable>()

  @Published public private(set) var searchResults: [NamedLocation] = []

  let tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier.cell.rawValue)
    tableView.insetsContentViewsToSafeArea = true
    tableView.contentInsetAdjustmentBehavior = .automatic
    return tableView
  }()

  // MARK: - Methods
  init(frame: CGRect = .zero,
       viewModel: DropoffLocationPickerViewModel) {
    self.viewModel = viewModel

    super.init(frame: frame)

    addSubview(tableView)
    tableView.dataSource = self
    tableView.delegate = self

    viewModel
      .$searchResults
      .receive(on: DispatchQueue.main)
      .assign(to: \.searchResults, on: self)
      .store(in: &subscriptions)

    viewModel
      .$searchResults
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.tableView.reloadData()
      }.store(in: &subscriptions)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    tableView.frame = bounds
  }
}

extension DropoffLocationPickerContentRootView: UITableViewDataSource {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return searchResults.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.cell.rawValue)
    cell?.textLabel?.text = searchResults[indexPath.row].name
    return cell!
  }
}

extension DropoffLocationPickerContentRootView: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let selectedLocation = searchResults[indexPath.row]
    viewModel.select(dropoffLocation: selectedLocation)
  }
}
