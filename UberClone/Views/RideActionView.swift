//
//  RideActionView.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 06/02/2021.
//

import UIKit
import MapKit

protocol RideActionViewDelegate {
    func userUploadTrip(_ view: RideActionView)
    func observeUserCurrentTrip()
    func userCancelTrip()
    func pickupPassenger()
    func dropOffPassenger()
}

enum RideActionViewConfiguration {
    case requestRide
    case tripAccepted
    case driverArrived
    case pickupPassenger
    case tripInProgress
    case endTrip

    init() {
        self = .requestRide
    }
}

enum ButtonAction: CustomStringConvertible {
    case requestRide
    case cancel
    case getDirections
    case pickup
    case dropoff
    
    var description: String {
        switch self {
        case .requestRide:
            return "CONFIRM UBERX"
        case .cancel:
            return "CANCEL RIDE"
        case .getDirections:
            return "GET DIRECTIONS"
        case .pickup:
            return "PICKUP PASSENGER"
        case .dropoff:
            return "DROP OFF PASSENGER"
        }
    }
    init() {
        self = .requestRide
    }
}



class RideActionView: UIView {


    //MARK: - Properties
    
    var destination: MKPlacemark?
    
    var rideActionConfig = RideActionViewConfiguration() {
        didSet {
            configureUI(withConfig: rideActionConfig)
        }
    }
    
    var buttonAction = ButtonAction()
    
    var user: User?
    
    var delegate: RideActionViewDelegate?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = .lightGray
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, addressLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var infoView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
  
        view.addSubview(infoViewLabel)
        infoViewLabel.centerX(inView: view)
        infoViewLabel.centerY(inView: view)
        return view
    }()
    
    private let infoViewLabel: UILabel = {
        let label = UILabel()
        label.text = "X"
        label.font = UIFont.systemFont(ofSize: 30)
        label.textColor = .white
        return label
    }()
    
    private let uberXLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = "UBER X"
        label.textAlignment = .center
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .black
        button.setTitle("CONFIRM UBERX", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    
    //MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Helper Functions
    private func configureUI() {
        backgroundColor = .white
        addShadow()
        addSubview(stackView)
        stackView.centerX(inView: self)
        stackView.anchor(top: topAnchor, paddingTop: 12)
        
        addSubview(infoView)
        infoView.centerX(inView: self)
        infoView.anchor(top: stackView.bottomAnchor, paddingTop: 16, width: 60 , height: 60)
        infoView.layer.cornerRadius = 60 / 2
        
        addSubview(uberXLabel)
        uberXLabel.anchor(top: infoView.bottomAnchor, paddingTop: 8)
        uberXLabel.centerX(inView: self)
        
        let separatorView = UIView()
        separatorView.backgroundColor = .lightGray
        addSubview(separatorView)
        separatorView.anchor(top: uberXLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 4, height: 0.75)
        
        addSubview(actionButton)
        actionButton.anchor(left: leftAnchor, bottom: safeAreaLayoutGuide.bottomAnchor, right: rightAnchor, paddingLeft: 12, paddingBottom: 12, paddingRight: 12, height: 50)
    }
    
    //MARK: - Selectors

    @objc func actionButtonPressed() {
        
        switch buttonAction {
        case .requestRide:
            delegate?.userUploadTrip(self)
            delegate?.observeUserCurrentTrip()
            
        case .cancel:
            delegate?.userCancelTrip()
            
        case .getDirections:
            print("Get directions")
            
        case .pickup:
            delegate?.pickupPassenger()
            
        case .dropoff:
            delegate?.dropOffPassenger()
        }
    }
    
    
    //MARK: - Helper Functions
    
    private func configureUI(withConfig config: RideActionViewConfiguration) {
        switch config {
        
        case .requestRide:
            titleLabel.text = destination?.name
            addressLabel.text = destination?.address
            buttonAction = .requestRide
            actionButton.setTitle(buttonAction.description, for: .normal)
            
        case .tripAccepted:
            guard let user = user else { return }
            infoViewLabel.text = String(user.fullname.first ?? "X")
            uberXLabel.text = user.fullname
            if user.accountType == .passenger {
                titleLabel.text = "En Route To Passenger"
                buttonAction = .getDirections
                actionButton.setTitle(buttonAction.description, for: .normal)
            } else {
                titleLabel.text = "Driver En Route"
                addressLabel.text = ""
                buttonAction = .cancel
                actionButton.setTitle(buttonAction.description, for: .normal)
            }
            
        case .driverArrived:
            guard let user = user else { return }
            if user.accountType == .driver {
                titleLabel.text = "Driver Has Arrived"
                addressLabel.text = ""
                addressLabel.text = "Please meet driver at pickup location"
            }
            
        case .pickupPassenger:
            titleLabel.text = "Arrived At Passenger Location"
            buttonAction = .pickup
            actionButton.setTitle(buttonAction.description, for: .normal)
            
        case .tripInProgress:
            guard let user = user else { return }
            titleLabel.text = "En Route To Destination"
            addressLabel.text = ""
            if user.accountType == .passenger {
                actionButton.setTitle("Trip In Progress", for: .normal)
                actionButton.isEnabled = false
            } else {
                buttonAction = .getDirections
                actionButton.setTitle(buttonAction.description, for: .normal)
            }
            
        case .endTrip:
            titleLabel.text = "Arrived at Destination"
            guard let user = user else { return }
            if user.accountType == .passenger {
                buttonAction = .dropoff
                actionButton.setTitle(buttonAction.description, for: .normal)
                actionButton.isEnabled = true
            } else {
                actionButton.setTitle("Arrived At Destination", for: .normal)
                actionButton.isEnabled = false
            }
        }
    }
}
