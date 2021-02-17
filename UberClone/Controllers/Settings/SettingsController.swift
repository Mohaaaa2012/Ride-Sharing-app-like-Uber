//
//  SettingsController.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 15/02/2021.
//

import UIKit
import MapKit

enum LocationType: Int, CaseIterable, CustomStringConvertible {
    case home
    case work
    
    var description: String {
        switch self {
        case .home: return "Home"
        case .work: return "Work"
        }
    }
    
    var subTitle: String {
        switch self {
        case .home: return "Add Home"
        case .work: return "Add Work"
        }
    }
}

protocol SettingsControllerDelegate: class {
    func updateUser(_ controller: SettingsController)
}

private let reuseIdenifier = "LocationCell"

class SettingsController: UITableViewController {

    //MARK: - Properties
    
    private lazy var userInfoHeader: UserInfoHeader = {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 100)
        let view = UserInfoHeader(user: user, frame: frame)
        return view
    }()
    
    private let sectionHeader: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundColor
        
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 16)
        title.textColor = .white
        title.text = "Favorites"
        
        view.addSubview(title)
        title.centerY(inView: view)
        title.anchor(left: view.leftAnchor, paddingLeft: 16)
        return view
    }()
    
    var user: User
    
    private let locationManager = LocationHandler.shared.locationManager
    
    weak var delegate: SettingsControllerDelegate?
    
    private var userInfoUpdated = false
    
    //MARK: - Lifecycle
    
    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.navigationBar.sizeToFit()
        }
    }
    
    //MARK: - API
    
    //MARK: - Selectors
    
    @objc func handleDismiss() {
        if userInfoUpdated {
            delegate?.updateUser(self)
        }
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Helper Functions
    
    func configureTableView() {
        tableView.rowHeight = 60
        tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdenifier)
        tableView.backgroundColor = .white
        tableView.tableHeaderView = userInfoHeader
        tableView.tableFooterView = UIView()
        
    }
    
    func configureNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = .backgroundColor
        navigationItem.title = "Settings"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "baseline_clear_white_36pt_2x").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleDismiss))
    }
    
    func locationText(forType type: LocationType) -> String{
        switch type {
        case .home:
            return user.homeLocation ?? type.subTitle
        case .work:
            return user.workLocation ?? type.subTitle
        }
    }
    
}


//MARK: - UITableViewDelegate/DataSource

extension SettingsController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LocationType.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdenifier, for: indexPath) as! LocationCell
        
        guard let type = LocationType(rawValue: indexPath.row) else { return cell }
        cell.titleLabel.text = type.description
        cell.addressLabel.text = locationText(forType: type)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return sectionHeader
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let type = LocationType(rawValue: indexPath.row) else { return }
        guard let location = locationManager?.location else { return }
        let addLocationController = AddLocationController(type: type, location: location)
        addLocationController.delegate = self
        let nav = UINavigationController(rootViewController: addLocationController)
        present(nav, animated: true, completion: nil)
        
    }
    
}

//MARK: - AddLocationControllerDelegate

extension SettingsController: AddLocationControllerDelegate {
    
    func updateLocation(locationString: String, type: LocationType) {
        PassengerService.shared.saveFavoriteLocations(locationString: locationString, type: type) { (error, ref) in
            if let error = error {
                print("Failed to save location with error: \(error)")
                return
            }
            switch type {
            case .home:
                self.user.homeLocation = locationString
            case .work:
                self.user.workLocation = locationString
            }
            self.userInfoUpdated = true
            self.tableView.reloadData()
            self.dismiss(animated: true, completion: nil)
        }
    }

}
