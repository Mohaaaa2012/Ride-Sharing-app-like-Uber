//
//  LocationInputActivationView.swift
//  UberClone
//
//  Created by Mohamed Mostafa on 01/02/2021.
//

import UIKit

protocol LocationInputActivationViewDelegate {
    func presentLocationInputView()
}

class LocationInputActivationView: UIView {

    //MARK: - Properties
    
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let placeHolderLabel: UILabel = {
        let label = UILabel()
        label.text = "Where to?"
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .darkGray
        return label
    }()
    
    var delegate: LocationInputActivationViewDelegate?
    
    //MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    private func configureUI() {
        backgroundColor = .white
        
        addShadow()
        
        addSubview(indicatorView)
        indicatorView.anchor(left: leftAnchor, paddingLeft: 16, width: 6, height: 6)
        indicatorView.centerY(inView: self)
        
        addSubview(placeHolderLabel)
        placeHolderLabel.anchor(left: indicatorView.rightAnchor, paddingLeft: 20)
        placeHolderLabel.centerY(inView: self)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(presentLocationInputView))
        self.addGestureRecognizer(tap)

    }
    
    //MARK: - Selectors
    
    @objc func presentLocationInputView() {
        delegate?.presentLocationInputView()
    }
}
