//
//  LoginController.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 30/01/2021.
//

import UIKit
import Firebase

class LoginController: UIViewController {
    
    
    // MARK: - Properties
    
    private let titleLabel = SignTitleLabel()
    
    private lazy var emailContainerView = LoginContainerView(image: #imageLiteral(resourceName: "ic_mail_outline_white_2x"), textField: emailTextfield)
    
    private let emailTextfield = SignTextField(withPlaceHolder: "Email", isSecured: false)
    
    private lazy var passwordContainerView = LoginContainerView(image: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), textField: passwordTextField)
    
    private let passwordTextField = SignTextField(withPlaceHolder: "Password", isSecured: true)
    
    private let loginButton: SignButton = {
        let button = SignButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        return button
    }()
    
    private lazy var stackView = SignStackView(views: emailContainerView, passwordContainerView, loginButton)
    
    private let dontHaveAccountButton: DoOrDontHaveAccountButton = {
        let button = DoOrDontHaveAccountButton(fisrtTitle: "Don't have an account?  ", secondTitle: "Sign Up")
        button.addTarget(self, action: #selector(handleShowSignup), for: .touchUpInside)
        return button
    }()

    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        passwordTextField.text = "123456"
    }
    
    
    // MARK:- Selectors
    
    @objc func handleLogin() {
        
        guard let email = emailTextfield.text, email.count != 0 else { return }
        guard let password = passwordTextField.text, password.count != 0 else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("Failed to login with error \(error)")
                return
            }
            print("successfully user login")
            guard let controller = UIApplication.shared.keyWindow?.rootViewController as? ContainerController else { return }
            controller.configure()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    @objc func handleShowSignup() {
        let signupVC = SignUpController()
        navigationController?.pushViewController(signupVC, animated: true)
    }
    
    
    // MARK:- Helper Functions
    
    private func configureUI() {
        configureNavigationBar()
        view.backgroundColor = .backgroundColor
        
        view.addSubview(titleLabel)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
        titleLabel.centerX(inView: view)
        
        view.addSubview(stackView)
        stackView.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16, height: 200)
        
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.centerX(inView: view)
        dontHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingBottom: 0, height: 32)
    }
    
    private func configureNavigationBar() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
    }
}
