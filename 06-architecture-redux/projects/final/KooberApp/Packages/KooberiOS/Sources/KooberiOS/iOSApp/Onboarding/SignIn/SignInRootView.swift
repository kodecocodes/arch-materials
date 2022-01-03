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

import CoreGraphics
import UIKit
import KooberUIKit
import KooberKit

class SignInRootView: NiblessView {

  // MARK: - Properties
  let userInteractions: SignInUserInteractions
  var hierarchyNotReady = true
  var bottomLayoutConstraint: NSLayoutConstraint?

  let scrollView: UIScrollView = UIScrollView()
  let contentView: UIView = UIView()

  lazy var inputStack: UIStackView = {
    let stack = UIStackView(arrangedSubviews: [
      emailInputStack,
      passwordInputStack
    ])
    stack.axis = .vertical
    stack.spacing = 10
    return stack
  }()

  lazy var emailInputStack: UIStackView = {
    let stack = UIStackView(arrangedSubviews: [emailIcon, emailField])
    stack.axis = .horizontal
    return stack
  }()

  let emailIcon: UIView = {
    let imageView = UIImageView()
    imageView.heightAnchor
      .constraint(equalToConstant: 40)
      .isActive = true
    imageView.widthAnchor
      .constraint(equalToConstant: 40)
      .isActive = true
    imageView.image = #imageLiteral(resourceName: "email_icon")
    imageView.contentMode = .center
    return imageView
  }()

  let emailField: UITextField = {
    let field = UITextField()
    field.placeholder = "Email"
    field.backgroundColor = Color.background
    field.textColor = .white
    field.keyboardType = .emailAddress
    field.autocapitalizationType = .none
    field.autocorrectionType = .no
    return field
  }()

  lazy var passwordInputStack: UIStackView = {
    let stack = UIStackView(arrangedSubviews: [passwordIcon, passwordField])
    stack.axis = .horizontal
    return stack
  }()

  let passwordIcon: UIView = {
    let imageView = UIImageView()
    imageView.heightAnchor
      .constraint(equalToConstant: 40)
      .isActive = true
    imageView.widthAnchor
      .constraint(equalToConstant: 40)
      .isActive = true
    imageView.image = #imageLiteral(resourceName: "password_icon")
    imageView.contentMode = .center
    return imageView
  }()

  let passwordField: UITextField = {
    let field = UITextField()
    field.placeholder = "Password"
    field.isSecureTextEntry = true
    field.textColor = .white
    field.backgroundColor = Color.background
    return field
  }()

  let signInButton: UIButton = {
    let button = UIButton(type: .custom)
    button.setTitle("Sign In", for: .normal)
    button.setTitle("", for: .disabled)
    button.titleLabel?.font = .boldSystemFont(ofSize: 18)
    button.backgroundColor = Color.darkButtonBackground
    return button
  }()

  let signInActivityIndicator: UIActivityIndicatorView  = {
    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.hidesWhenStopped = true
    return indicator
  }()

  // MARK: - Methods
  init(frame: CGRect = .zero,
       userInteractions: SignInUserInteractions) {
    self.userInteractions = userInteractions
    super.init(frame: frame)
  }

  func new(state: SignInViewState) {
    emailField.isEnabled = state.emailInputEnabled
    passwordField.isEnabled = state.passwordInputEnabled
    signInButton.isEnabled = state.signInButtonEnabled

    switch state.signInActivityIndicatorAnimating {
    case true:
      signInActivityIndicator.startAnimating()
    case false:
      signInActivityIndicator.stopAnimating()
    }
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()

    guard hierarchyNotReady else {
      return
    }

    backgroundColor = Color.background
    constructHierarchy()
    activateConstraints()
    wireController()
    hierarchyNotReady = false
  }

  func constructHierarchy() {
    scrollView.addSubview(contentView)
    contentView.addSubview(inputStack)
    contentView.addSubview(signInButton)
    signInButton.addSubview(signInActivityIndicator)
    addSubview(scrollView)
  }

  func activateConstraints() {
    activateConstraintsScrollView()
    activateConstraintsContentView()
    activateConstraintsInputStack()
    activateConstraintsSignInButton()
    activateConstraintsSignInActivityIndicator()
  }

  func wireController() {
    signInButton.addTarget(self,
                           action: #selector(signIn),
                           for: .touchUpInside)
  }

  @objc
  func signIn() {
    userInteractions.signIn(email: emailField.text ?? "",
                            password: passwordField.text ?? "")
  }
  
  func configureViewAfterLayout() {
    resetScrollViewContentInset()
  }
  
  func resetScrollViewContentInset() {
    let scrollViewBounds = scrollView.bounds
    let contentViewHeight = CGFloat(180.0)
    
    var scrollViewInsets = UIEdgeInsets.zero
    scrollViewInsets.top = scrollViewBounds.size.height / 2.0;
    scrollViewInsets.top -= contentViewHeight / 2.0;
    
    scrollViewInsets.bottom = scrollViewBounds.size.height / 2.0
    scrollViewInsets.bottom -= contentViewHeight / 2.0
    
    scrollView.contentInset = scrollViewInsets
  }
  
  func moveContentForDismissedKeyboard() {
    resetScrollViewContentInset()
  }
  
  func moveContent(forKeyboardFrame keyboardFrame: CGRect) {
    var insets = scrollView.contentInset
    insets.bottom = keyboardFrame.height
    scrollView.contentInset = insets
  }
}

// MARK: - Layout
extension SignInRootView {

  func activateConstraintsScrollView() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    let leading = scrollView.leadingAnchor
      .constraint(equalTo: layoutMarginsGuide.leadingAnchor)
    let trailing = scrollView.trailingAnchor
      .constraint(equalTo: layoutMarginsGuide.trailingAnchor)
    let top = scrollView.topAnchor
      .constraint(equalTo: safeAreaLayoutGuide.topAnchor)
    let bottom = scrollView.bottomAnchor
      .constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
    NSLayoutConstraint.activate(
      [leading, trailing, top, bottom])
  }

  func activateConstraintsContentView() {
    contentView.translatesAutoresizingMaskIntoConstraints = false
    let width = contentView.widthAnchor
      .constraint(equalTo: scrollView.widthAnchor)
    let leading = contentView.leadingAnchor
      .constraint(equalTo: scrollView.leadingAnchor)
    let trailing = contentView.trailingAnchor
      .constraint(equalTo: scrollView.trailingAnchor)
    let top = contentView.topAnchor
      .constraint(equalTo: scrollView.topAnchor)
    let bottom = contentView.bottomAnchor
      .constraint(equalTo: scrollView.bottomAnchor)
    NSLayoutConstraint.activate(
      [width, leading, trailing, top, bottom])
  }

  func activateConstraintsInputStack() {
    inputStack.translatesAutoresizingMaskIntoConstraints = false
    let leading = inputStack.leadingAnchor
      .constraint(equalTo: contentView.leadingAnchor)
    let trailing = inputStack.trailingAnchor
      .constraint(equalTo: contentView.trailingAnchor)
    let top = inputStack.topAnchor
      .constraint(equalTo: contentView.topAnchor)
    NSLayoutConstraint.activate(
      [leading, trailing, top])
  }

  func activateConstraintsSignInButton() {
    signInButton.translatesAutoresizingMaskIntoConstraints = false
    let leading = signInButton.leadingAnchor
      .constraint(equalTo: contentView.leadingAnchor)
    let trailing = signInButton.trailingAnchor
      .constraint(equalTo: contentView.trailingAnchor)
    let top = signInButton.topAnchor
      .constraint(equalTo: inputStack.bottomAnchor, constant: 20)
    let bottom = contentView.bottomAnchor
      .constraint(equalTo: signInButton.bottomAnchor, constant: 20)
    let height = signInButton.heightAnchor
      .constraint(equalToConstant: 50)
    NSLayoutConstraint.activate(
      [leading, trailing, top, bottom, height])
  }

  func activateConstraintsSignInActivityIndicator() {
    signInActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
    let centerX = signInActivityIndicator.centerXAnchor
      .constraint(equalTo: signInButton.centerXAnchor)
    let centerY = signInActivityIndicator.centerYAnchor
      .constraint(equalTo: signInButton.centerYAnchor)
    NSLayoutConstraint.activate(
      [centerX, centerY])
  }
}
