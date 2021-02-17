//
//  LocationCell.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 02/02/2021.
//

import UIKit
import MapKit

class LocationCell: UITableViewCell {

    //MARK: - Properties

    static let cellId = String(describing: LocationCell.self)
    
    var placeMark: MKPlacemark? {
        didSet {
            titleLabel.text = placeMark?.name
            // get address from extension
            addressLabel.text = placeMark?.address
        }
    }
    
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        //label.text = "123 Main street"
        return label
    }()
    
    var addressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        //label.text = "123 Main street, Washington, DC"
        return label
    }()
    
    private lazy var stack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, addressLabel])
        sv.axis = .vertical
        sv.distribution = .fillEqually
        sv.spacing = 4
        return sv
    }()
        
    
    //MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(stack)
        stack.anchor(left: leftAnchor, paddingLeft: 12)
        stack.centerY(inView: self)
        
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    //MARK: - Helper Functions
    
    //MARK: - Selectors
}
