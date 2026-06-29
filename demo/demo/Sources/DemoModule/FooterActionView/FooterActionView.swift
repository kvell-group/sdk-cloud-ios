//
//  FooterActionView.swift
//  demo
//
//  Created by Kvell on 27.06.2023.
//  Copyright © 2023 Kvell. All rights reserved.
//

import UIKit
import Foundation

class FooterActionView: UIView {
    @IBOutlet weak var demoActionButton: UIButton!
    @IBOutlet weak var demoActionSwitch: UISwitch!
    @IBOutlet weak var demoLabel: UILabel!
    
    // MARK: - Init
    override init(frame: CGRect) { super.init(frame: frame)
        setupXib()
        setupLayoutForButton()
    }
    
    required init?(coder: NSCoder) { super.init(coder: coder)
        setupXib()
    }
    
    // MARK: - Private methods
    private func setupLayoutForButton() {
        demoActionButton.layer.cornerRadius = 8
    }
    
    private func setupXib() {
        let arrayView = Bundle.main.loadNibNamed(FooterActionView.identifier, owner: self)
        if let view = arrayView?.first as? UIView  {
            view.frame = bounds
            addSubview(view)
        }
    }
    
    func addTarget(target: Any?, action: Selector, _ type: ButtonType) {
        switch type {
        case .demo:
            demoActionButton.addTarget(target, action: action, for: .touchUpInside)
        }
    }
}

extension FooterActionView {
    enum ButtonType {
        case demo
    }
}
