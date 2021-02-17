//
//  LoginContainerView.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 31/01/2021.
//

import UIKit

class LoginContainerView: UIView {
    
    
    init(image: UIImage, textField: UITextField? = nil, segmentedControl: UISegmentedControl? = nil) {
        super.init(frame: .zero)
        setupUI(image: image, textField: textField, segmentedControl: segmentedControl)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupUI(image: UIImage, textField: UITextField? = nil, segmentedControl: UISegmentedControl? = nil) {
        
        let imageView = UIImageView()
        imageView.image = image
        imageView.alpha = 0.87
        addSubview(imageView)
        
        if let textField = textField {
            imageView.anchor(left: leftAnchor, width: 24, height: 24)
            imageView.centerY(inView: self)
            
            addSubview(textField)
            textField.anchor(left: imageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 8, paddingBottom: 8)
            textField.centerY(inView: self)
        }
        
        if let sc = segmentedControl {
            imageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: -8, width: 24, height: 24)
            
            addSubview(sc)
            sc.anchor(left: leftAnchor, right: rightAnchor, height: 30)
            sc.centerY(inView: self, constant: 8)
        }
        
        let separatorView = UIView()
        separatorView.backgroundColor = .lightGray
        addSubview(separatorView)
        separatorView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, height: 0.75) 
    }
    
    
}
