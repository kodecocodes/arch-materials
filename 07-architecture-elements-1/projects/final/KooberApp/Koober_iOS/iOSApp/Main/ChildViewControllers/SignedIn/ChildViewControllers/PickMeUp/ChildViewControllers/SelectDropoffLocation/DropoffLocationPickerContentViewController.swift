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
  // Observers
  let observer: Observer

  // User interface
  let userInterface: DropoffLocationPickerUserInterfaceView

  // State
  let pickupLocation: Location
  var subscriptions = Set<AnyCancellable>()

  // Factories
  let searchDropoffLocationsUseCaseFactory: SearchDropoffLocationsUseCaseFactory
  let selectDropoffLocationUseCaseFactory: SelectDropoffLocationUseCaseFactory
  let cancelDropoffLocationPickerUseCaseFactory: CancelDropoffLocationPickerUseCaseFactory
  let makeFinishedPresentingErrorUseCase: FinishedPresentingErrorUseCaseFactory

  // MARK: - Methods
  init(pickupLocation: Location,
       observer: Observer,
       userInterface: DropoffLocationPickerUserInterfaceView,
       searchDropoffLocationsUseCaseFactory: SearchDropoffLocationsUseCaseFactory,
       selectDropoffLocationUseCaseFactory: SelectDropoffLocationUseCaseFactory,
       cancelDropoffLocationPickerUseCaseFactory: CancelDropoffLocationPickerUseCaseFactory,
       finishedPresentingErrorUseCaseFactory: @escaping FinishedPresentingErrorUseCaseFactory) {
    self.pickupLocation = pickupLocation
    self.observer = observer
    self.userInterface = userInterface
    self.searchDropoffLocationsUseCaseFactory = searchDropoffLocationsUseCaseFactory
    self.selectDropoffLocationUseCaseFactory = selectDropoffLocationUseCaseFactory
    self.cancelDropoffLocationPickerUseCaseFactory = cancelDropoffLocationPickerUseCaseFactory
    self.makeFinishedPresentingErrorUseCase = finishedPresentingErrorUseCaseFactory

    super.init()

    self.navigationItem.title = "Where To?"
    self.navigationItem.largeTitleDisplayMode = .automatic
    self.navigationItem.leftBarButtonItem =
      UIBarButtonItem(barButtonSystemItem: .cancel,
                      target: self,
                      action: #selector(cancelDropoffLocationPicker))
  }

  public override func loadView() {
    view = userInterface
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    setUpSearchController()
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    observer.startObserving()
  }

  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    observer.stopObserving()
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    searchForDropoffLocations(using: "", for: pickupLocation)
  }

  func setUpSearchController() {
    let pickupLocationCopy = self.pickupLocation
    let searchController = ObservableUISearchController(searchResultsController: nil)
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchTextPublisher
      .receive(on: DispatchQueue.main)
      .debounce(for: .milliseconds(900), scheduler: DispatchQueue.main)
      .sink { [weak self] query in
        self?.searchForDropoffLocations(using: query, for: pickupLocationCopy)
      }
      .store(in: &subscriptions)

    navigationItem.searchController = searchController
    definesPresentationContext = true
  }

  func searchForDropoffLocations(using query: String, for pickupLocation: Location) {
    let useCase =
      searchDropoffLocationsUseCaseFactory
        .makeSearchDropoffLocationsUseCase(
          query: query, pickupLocation:
          pickupLocation
        )
    useCase.start()
  }

  @objc
  func cancelDropoffLocationPicker() {
    let useCase = cancelDropoffLocationPickerUseCaseFactory.makeCancelDropoffLocationPickerUseCase()
    useCase.start()
  }

  func finishedPresenting(_ errorMessage: ErrorMessage) {
    let useCase = makeFinishedPresentingErrorUseCase(errorMessage)
    useCase.start()
  }
}

extension DropoffLocationPickerContentViewController: ObserverForSelectDropoffLocationEventResponder {

  func received(newDropoffLocationPickerState dropoffLocationPickerState: DropoffLocationPickerViewControllerState) {
    userInterface.render(searchResults: dropoffLocationPickerState.searchResults)
  }

  func received(newErrorMessage errorMessage: ErrorMessage) {
    if let presentedViewController = self.presentedViewController {
      presentedViewController.present(errorMessage: errorMessage) { [ weak self] in
        self?.finishedPresenting(errorMessage)
      }
    } else {
      present(errorMessage: errorMessage) { [weak self] in
        self?.finishedPresenting(errorMessage)
      }
    }
  }
}

extension DropoffLocationPickerContentViewController: DropoffLocationPickerIxResponder {

  func select(dropoffLocation: Location) {
    navigationItem.searchController?.isActive = false
    let useCase =
      selectDropoffLocationUseCaseFactory
        .makeSelectDropoffLocationUseCase(dropoffLocation: dropoffLocation)
    useCase.start()
  }
}
