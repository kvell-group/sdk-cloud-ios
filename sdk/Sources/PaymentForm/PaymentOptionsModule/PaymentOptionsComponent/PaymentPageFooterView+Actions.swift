//
//  PaymentPageFooterView+Actions.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

extension PaymentPageFooterView {

    func configureDefaultActions() {
        onPhoneTap = {
            guard let url = URL(string: "tel://+74951202250") else { return }
            UIApplication.shared.open(url)
        }
        onEmailTap = {
            guard let url = URL(string: "mailto:support@kvell.ru") else { return }
            UIApplication.shared.open(url)
        }
        onKvellTap = {
            guard let url = URL(string: "https://kvell.group") else { return }
            UIApplication.shared.open(url)
        }
    }
}
