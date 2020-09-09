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

public class DropoffLocationPickerContentViewController: NiblessViewController {
  
  // MARK: - Properties
  // State
  let pickupLocation: Location
  private var subscriptions = Set<AnyCancellable>()

  // View Model
  let viewModel: DropoffLocationPickerViewModel

  // Root View
  var rootView: DropoffLocationPickerContentRootView {
    return view as! DropoffLocationPickerContentRootView
  }

  // MARK: - Methods
  init(pickupLocation: Location,
       viewModel: DropoffLocationPickerViewModel) {
    self.pickupLocation = pickupLocation
    self.viewModel = viewModel
    super.init()
    self.navigationItem.title = "Where To?"
    self.navigationItem.largeTitleDisplayMode = .automatic
    self.navigationItem.leftBarButtonItem =
      UIBarButtonItem(barButtonSystemItem: .cancel,
                      target: viewModel,
                      action: #selector(DropoffLocationPickerViewModel.cancelDropoffLocationSelection))
  }

  public override func loadView() {
    view = DropoffLocationPickerContentRootView(viewModel: viewModel)
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    setUpSearchController(with: viewModel)
    observeErrorMessages()
  }

  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    navigationItem.searchController?.isActive = false
  }

  func setUpSearchController(with viewModel: DropoffLocationPickerViewModel) {
    let searchController = ObservableUISearchController(searchResultsController: nil)
    searchController.obscuresBackgroundDuringPresentation = false

    searchController
      .searchTextPublisher
      .debounce(for: .milliseconds(900), scheduler: DispatchQueue.main)
      .assign(to: \.searchInput, on: viewModel)
      .store(in: &subscriptions)

    navigationItem.searchController = searchController
    definesPresentationContext = true
  }

  func observeErrorMessages() {
    viewModel
      .errorMessages
      .receive(on: DispatchQueue.main)
      .sink { [weak self] errorMessage in
        self?.routePresentation(forErrorMessage: errorMessage)
      }.store(in: &subscriptions)
  }

  func routePresentation(forErrorMessage errorMessage: ErrorMessage) {
    if let presentedViewController = presentedViewController {
      presentedViewController.present(errorMessage: errorMessage)
    } else {
      present(errorMessage: errorMessage)
    }
  }
}

protocol DropoffLocationViewModelFactory {
  
  func makeDropoffLocationPickerViewModel() -> DropoffLocationPickerViewModel
}
