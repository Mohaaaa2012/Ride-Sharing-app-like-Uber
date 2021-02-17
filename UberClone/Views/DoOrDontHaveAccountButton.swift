//
//  DontHaveAccountButton.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 01/02/2021.
//

import UIKit

class DoOrDontHaveAccountButton: UIButton {
    
    
    init(fisrtTitle: String, secondTitle: String) {
        super.init(frame: .zero)
        setupUI(firstTitle: fisrtTitle, secondTitle: secondTitle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(firstTitle: String, secondTitle: String) {
        
        let attributedTitle = NSMutableAttributedString(string: firstTitle,
                attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16),
                             NSAttributedString.Key.foregroundColor : UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: secondTitle,
                 attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16),
                              NSAttributedString.Key.foregroundColor : UIColor.mainBlueTint]))
        
        setAttributedTitle(attributedTitle, for: .normal)
    }
}
