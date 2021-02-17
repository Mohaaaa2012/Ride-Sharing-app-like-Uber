//
//  ContainerView.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 14/02/2021.
//

import UIKit
import Firebase

class ContainerController: UIViewController {

    //MARK: - Properties
    
    private var homeController = HomeController()
    private var menucontroller: MenuController!
    
    private let blackView = UIView()
    
    private var isExpanded = false
    private lazy var xOrigin = self.view.frame.width - 80
    
    var user: User? {
        didSet{
            guard let user = user else { return }
            configureMenuController(withUser: user)
            homeController.user = user
            print("Container user: \(user)")
        }
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Container view did load")
        checkIsUserLoggedIn()
        configureHomeController()
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return isExpanded
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    //MARK: - API
    
    func checkIsUserLoggedIn() {
        let uid = Auth.auth().currentUser?.uid
        if uid == nil {
            print("User not Loged in")
            presentLoginController()
        } else {
            print("User Loged in")
            configure()
        }
    }
    
    func fetchUserData() {
        print("Fetch user data")
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        SharedService.shared.fetchUserDate(uid: currentUid) { (user) in
            self.user = user
        }
    }
    
    func userSignout() {
        do {
            try Auth.auth().signOut()
            presentLoginController()
        } catch let error {
            print("Failed to signout with error : \(error)")
        }
    }
    
    
    //MARK: - Selectors
    
    @objc func dismissMenu() {
        isExpanded = false
        animateMenu(shouldExpand: isExpanded)
    }
    
    
    //MARK: - Helper Functions
    
    func presentLoginController() {
        DispatchQueue.main.async {
            let nav = UINavigationController(rootViewController: LoginController())
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        }
    }
    
    func configure() {
        print("configure")
        fetchUserData()
    }
    
    func configureHomeController() {
        print("Configure Home")
        view.backgroundColor = .white
        addChild(homeController)
        homeController.didMove(toParent: self)
        view.addSubview(homeController.view)
        homeController.delegate = self
    }
    
    
    func configureMenuController(withUser user: User) {
        menucontroller = MenuController(user: user)
        addChild(menucontroller)
        menucontroller.didMove(toParent: self)
        view.insertSubview(menucontroller.view, at: 0)
        menucontroller.delegate = self
        configureBlackView()
    }
    
    
    func configureBlackView() {
        blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        blackView.alpha = 0
        view.addSubview(blackView)
        blackView.frame = CGRect(x: xOrigin, y: 0, width: 80, height: view.frame.height)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissMenu))
        blackView.addGestureRecognizer(tap)
    }
    
    
    func animateMenu(shouldExpand: Bool, completion: ((Bool)-> Void)? = nil) {
        if shouldExpand {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = self.xOrigin
                self.blackView.alpha = 1
            }, completion: nil)
            
        }else {
            self.blackView.alpha = 0
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = 0
            }, completion: completion)
        }
        
        animateStatusBar()
    }
    
    func animateStatusBar() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)
    }
}

//MARK: - HomeControllerDelegate

extension ContainerController: HomeControllerDelegate {
    
    func handleMenuToggle() {
        isExpanded.toggle()
        animateMenu(shouldExpand: isExpanded)
    }
}


//MARK: - MenuControllerDelegate

extension ContainerController: MenuControllerDelegate {
    
    func didSelect(option: MenuOptions) {
        isExpanded.toggle()
        animateMenu(shouldExpand: isExpanded) { _ in
            switch option {
            case .yourTrips:
                break
            case .settings:
                guard let user = self.user else { return }
                let settingsController = SettingsController(user: user)
                settingsController.delegate = self
                let nav = UINavigationController(rootViewController: settingsController)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            case .logout:
                let alert = UIAlertController(title: nil, message: "Are you sure you want to log out?", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
                    self.userSignout()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

//MARK: - SettingsControllerDelegate

extension ContainerController: SettingsControllerDelegate {
    
    func updateUser(_ controller: SettingsController) {
        self.user = controller.user
    }
}
