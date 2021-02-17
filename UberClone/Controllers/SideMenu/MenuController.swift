//
//  MenuController.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 14/02/2021.
//

import UIKit

//private let reuseIdentifier = "MenuCell"

enum MenuOptions: Int, CaseIterable, CustomStringConvertible {
    case yourTrips
    case settings
    case logout
    
    var description: String {
        switch self {
        case .yourTrips: return "Your Trips"
        case .settings: return "Settings"
        case .logout: return "Logout"
        }
    }
}

protocol MenuControllerDelegate: class {
    func didSelect(option: MenuOptions)
}


class MenuController: UIViewController {

    //MARK: - Properties
    
    private var menuHeader: MenuHeader!
    private let menuTableView = UITableView()

    private let user: User
    
    weak var delegate : MenuControllerDelegate?
    
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
        configureHeaderView()
        configureTableView()
    }
    
    //MARK: - Selectors
    
    
    //MARK: - Helper Functions
    
    private func configureHeaderView() {
        menuHeader = MenuHeader(user: user)
        view.addSubview(menuHeader)
        menuHeader.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: 150)
    }
    
    private func configureTableView() {
        view.addSubview(menuTableView)
        menuTableView.anchor(top: menuHeader.bottomAnchor, left: view.leftAnchor, bottom: view.bottomAnchor,
                                  right: view.rightAnchor)
        
        menuTableView.dataSource = self
        menuTableView.delegate = self
        
        menuTableView.backgroundColor = .systemBackground
        menuTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        menuTableView.isScrollEnabled = false
        menuTableView.rowHeight = 60
        menuTableView.separatorStyle = .none
    }
}

extension MenuController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuOptions.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .systemBackground
        cell.textLabel?.text = MenuOptions(rawValue: indexPath.row)?.description
        return cell
    }
}


extension MenuController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let option = MenuOptions(rawValue: indexPath.row) else { return }
        delegate?.didSelect(option: option)
    }
}
