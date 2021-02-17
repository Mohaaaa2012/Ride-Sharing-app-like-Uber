//
//  SignTextField.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 31/01/2021.
//

import UIKit

class SignTextField: UITextField {
    
    
    init(withPlaceHolder placeHolder: String, isSecured: Bool) {
        super.init(frame: .zero)
        setupUI(placeHolder: placeHolder, secure: isSecured)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupUI(placeHolder: String, secure: Bool) {
        borderStyle = .none
        font = UIFont.systemFont(ofSize: 16)
        textColor = .white
        isSecureTextEntry = secure
        keyboardAppearance = .dark
        attributedPlaceholder = NSAttributedString(string: placeHolder, attributes: [NSAttributedString.Key.foregroundColor :  UIColor.lightGray])
    }
}
