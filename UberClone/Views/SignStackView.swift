//
//  SignStackView.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 31/01/2021.
//

import UIKit

class SignStackView: UIStackView {
    
    init(views: UIView...) {
        super.init(frame: .zero)
        setupUI(views: views)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(views: [UIView]) {
        for view in views {
            addArrangedSubview(view)
        }
        axis = .vertical
        distribution = .fillEqually
        spacing = 16
    }
}
