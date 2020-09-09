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
import KooberUIKit
import KooberKit

class SignUpRootView: NiblessView {

  // MARK: - Properties
  let userInteractions: SignUpUserInteractions

  var hierarchyNotReady = true

  let scrollView: UIScrollView = UIScrollView()
  let contentView: UIView = UIView()

  lazy var inputStack: UIStackView = {
    let stack = UIStackView(arrangedSubviews: [
      fullNameInputStack,
      nicknameInputStack,
      emailInputStack,
      mobileNumberInputStack,
      passwordInputStack
    ])
    stack.axis = .vertical
    stack.spacing = 10
    return stack
  }()

  lazy var fullNameInputStack: UIStackView = {
    let stack = UIStackView(arrangedSubviews: [fullNameIcon, fullNameField])
    stack.axis = .horizontal
    return stack
  }()

  let fullNameIcon: UIImageView = {
    let imageView = UIImageView()
    imageView.heightAnchor
      .constraint(equalToConstant: 40)
      .isActive = true
    imageView.widthAnchor
      .constraint(equalToConstant: 40)
      .isActive = true
    imageView.image = #imageLiteral(resourceName: "person_icon")
    imageView.contentMode = .center
    return imageView
  }()

  let fullNameField: UITextField = {
    let field = UITextField()
    field.placeholder = "Full Name"
    field.backgroundColor = Color.background
    field.autocorrectionType = .no
    field.autocapitalizationType = .words
    field.textColor = .white
    return field
  }()

  lazy var nicknameInputStack: UIStackView = {
    let stack = UIStackView(arrangedSubviews: [nicknameIcon, nicknameField])
    stack.axis = .horizontal
    return stack
  }()

  let nicknameIcon: UIImageView = {
    let imageView = UIImageView()
    imageView.heightAnchor
      .constraint(equalToConstant: 40)
      .isActive = true
    imageView.widthAnchor
      .constraint(equalToConstant: 40)
      .isActive = true
    imageView.image = #imageLiteral(resourceName: "tag_icon")
    imageView.contentMode = .center
    return imageView
  }()

  let nicknameField: UITextField = {
    let field = UITextField()
    field.placeholder = "What should we call you?"
    field.backgroundColor = Color.background
    field.textColor = .white
    field.autocorrectionType = .no
    field.autocapitalizationType = .words
    return field
  }()

  lazy var emailInputStack: UIStackView = {
    let stack = UIStackView(arrangedSubviews: [emailIcon, emailField])
    stack.axis = .horizontal
    return stack
  }()

  let emailIcon: UIImageView = {
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

  lazy var mobileNumberInputStack: UIStackView = {
    let stack = UIStackView(arrangedSubviews: [mobileNumberIcon, mobileNumberField])
    stack.axis = .horizontal
    return stack
  }()

  let mobileNumberIcon: UIImageView = {
    let imageView = UIImageView()
    imageView.heightAnchor
      .constraint(equalToConstant: 40)
      .isActive = true
    imageView.widthAnchor
      .constraint(equalToConstant: 40)
      .isActive = true
    imageView.image = #imageLiteral(resourceName: "mobile_icon")
    imageView.contentMode = .center
    return imageView
  }()

  let mobileNumberField: UITextField = {
    let field = UITextField()
    field.placeholder = "Mobile Number"
    field.backgroundColor = Color.background
    field.textColor = .white
    field.keyboardType = .phonePad
    field.autocapitalizationType = .none
    field.autocorrectionType = .no
    return field
  }()

  lazy var passwordInputStack: UIStackView = {
    let stack = UIStackView(arrangedSubviews: [passwordIcon, passwordField])
    stack.axis = .horizontal
    return stack
  }()

  let passwordIcon: UIImageView = {
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
    field.backgroundColor = Color.background
    field.isSecureTextEntry = true
    field.textColor = .white
    return field
  }()

  let signUpButton: UIButton = {
    let button = UIButton(type: .custom)
    button.setTitle("Sign Up", for: .normal)
    button.titleLabel?.font = .boldSystemFont(ofSize: 18)
    button.backgroundColor = Color.darkButtonBackground
    return button
  }()

  // MARK: - Methods
  init(frame: CGRect = .zero,
       userInteractions: SignUpUserInteractions) {
    self.userInteractions = userInteractions
    super.init(frame: frame)
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
    contentView.addSubview(signUpButton)
    addSubview(scrollView)
  }

  func activateConstraints() {
    activateConstraintsScrollView()
    activateConstraintsContentView()
    activateConstraintsInputStack()
    activateConstraintsSignUpButton()
  }

  func wireController() {
    signUpButton.addTarget(self, action: #selector(signUp), for: .touchUpInside)
  }

  @objc
  func signUp() {
    endEditing(true)
    let newAccount = NewAccount(fullName: fullNameField.text ?? "",
                                nickname: nicknameField.text ?? "",
                                email: emailField.text ?? "",
                                mobileNumber: mobileNumberField.text ?? "",
                                password: passwordField.text ?? "")
    userInteractions.signUp(newAccount)
  }

  func configureViewAfterLayout() {
    resetScrollViewContentInset()
  }
  
  func resetScrollViewContentInset() {
    let scrollViewBounds = scrollView.bounds
    let contentViewHeight = CGFloat(330.0)

    var scrollViewInsets = UIEdgeInsets.zero
    scrollViewInsets.top = scrollViewBounds.size.height / 2.0;
    scrollViewInsets.top -= contentViewHeight / 2.0;

    scrollViewInsets.bottom = scrollViewBounds.size.height / 2.0
    scrollViewInsets.bottom -= contentViewHeight / 2.0

    scrollView.contentInset = scrollViewInsets
  }
  
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

  func activateConstraintsSignUpButton() {
    signUpButton.translatesAutoresizingMaskIntoConstraints = false
    let leading = signUpButton.leadingAnchor
      .constraint(equalTo: contentView.leadingAnchor)
    let trailing = signUpButton.trailingAnchor
      .constraint(equalTo: contentView.trailingAnchor)
    let top = signUpButton.topAnchor
      .constraint(equalTo: inputStack.bottomAnchor, constant: 20)
    let bottom = contentView.bottomAnchor
      .constraint(equalTo: signUpButton.bottomAnchor, constant: 20)
    let height = signUpButton.heightAnchor
      .constraint(equalToConstant: 50)
    NSLayoutConstraint.activate([leading, trailing, top, bottom, height])
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
