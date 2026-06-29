//
//  BaseViewController.swift
//  demo
//
//  Created by Kvell on 15.10.2020.
//  Copyright © 2020 Kvell. All rights reserved.
//

import UIKit
class BaseViewController: UIViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
    }
}
