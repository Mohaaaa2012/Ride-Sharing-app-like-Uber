//
//  SignUpController.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 01/02/2021.
//

import UIKit
import Firebase
import GeoFire

class SignUpController: UIViewController{
    
    // MARK: - Properties
    
    var location = LocationHandler.shared.locationManager.location
    
    private let titleLabel = SignTitleLabel()
    
    private lazy var emailContainerView = LoginContainerView(image: #imageLiteral(resourceName: "ic_mail_outline_white_2x"), textField: emailTextfield)
    
    private let emailTextfield = SignTextField(withPlaceHolder: "Email", isSecured: false)
    
    private lazy var fullNameContainerView = LoginContainerView(image: #imageLiteral(resourceName: "ic_person_outline_white_2x"), textField: fullNameTextfield)
    
    private let fullNameTextfield = SignTextField(withPlaceHolder: "Full Name", isSecured: false)
    
    private lazy var passwordContainerView = LoginContainerView(image: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), textField: passwordTextField)
    
    private let passwordTextField = SignTextField(withPlaceHolder: "Password", isSecured: true)
    
    private lazy var accountTypeContainerView = LoginContainerView(image: #imageLiteral(resourceName: "ic_account_box_white_2x"), segmentedControl: accountTypeSegmentedControl)
    
    private let accountTypeSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Rider", "Driver"])
        sc.backgroundColor = .backgroundColor
        sc.tintColor = UIColor(white: 1, alpha: 0.87)
        sc.selectedSegmentIndex = 0
        return sc
    }()
    
    private let signUpButton: SignButton = {
        let button = SignButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.addTarget(self, action: #selector(handleSignup), for: .touchUpInside)
        return button
    }()
    
    private lazy var stackView = SignStackView(views: emailContainerView, fullNameContainerView, passwordContainerView, accountTypeContainerView, signUpButton)
    
    private let alreadyHaveAccountButton: DoOrDontHaveAccountButton = {
        let button = DoOrDontHaveAccountButton(fisrtTitle: "alreadyHaveAnAccount?  ", secondTitle: "Log In")
        button.addTarget(self, action: #selector(handleShowLogin), for: .touchUpInside)
        return button
    }()
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        passwordTextField.text = "123456"
    }
    
    
    // MARK: - Selectors
    
    @objc func handleShowLogin() {
        navigationController?.popViewController(animated: true)
    }
    
    
    @objc func handleSignup() {
        guard let email = emailTextfield.text, email.count != 0 else { return }
        guard let password = passwordTextField.text, password.count != 0 else { return }
        guard let fullName = fullNameTextfield.text, fullName.count != 0 else { return }
        let accountTypeIndex = accountTypeSegmentedControl.selectedSegmentIndex
        
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error { print("Failed register user with error \(error)")
                return }
            
            guard let uid = result?.user.uid else { return }
            let values = ["email": email,
                          "fullname": fullName,
                          "accountType": accountTypeIndex] as [String : Any]
            
            // Check if the created account is a driver..
            if accountTypeIndex == 1 {
                let geoFire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
                guard let location = self.location else { return }
                geoFire.setLocation(location, forKey: uid) { error in
                    if let error = error { print("Failed saving userLocation with error \(error)")
                        return }
                    print("successfully saving user location")
                    self.uploadUserDataAndShowHomeController(uid: uid, values: values)
                }
            }else {
                self.uploadUserDataAndShowHomeController(uid: uid, values: values)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func uploadUserDataAndShowHomeController(uid: String, values: [String: Any]) {
        REF_USERS.child(uid).updateChildValues(values) { (error, ref) in
            if let error = error { print("Failed saving userData with error \(error)")
                return }
            print("successfully user sign up")
            guard let controller = UIApplication.shared.keyWindow?.rootViewController as? ContainerController else { return }
            controller.configure()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func configureUI() {
        view.backgroundColor = .backgroundColor
        
        view.addSubview(titleLabel)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
        titleLabel.centerX(inView: view)
        
        view.addSubview(stackView)
        stackView.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16, height: view.frame.height * 0.45)
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.centerX(inView: view)
        alreadyHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingBottom: 0, height: 32)
    }
}
