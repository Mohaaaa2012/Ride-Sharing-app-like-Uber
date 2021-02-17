//
//  SignTitleLabel.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 01/02/2021.
//

import UIKit

class SignTitleLabel: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        text = "UBER"
        font = UIFont(name: "Avenir-Light", size: 36)
        textColor = UIColor(white: 1, alpha: 0.8)
    }
    
}
