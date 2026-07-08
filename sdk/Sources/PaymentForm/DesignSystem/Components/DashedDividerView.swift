//
//  DashedDividerView.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

final class DashedDividerView: UIView {

    private let dashLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        isUserInteractionEnabled = false

        dashLayer.strokeColor = KvellDesign.Color.divider.cgColor
        dashLayer.fillColor = nil
        dashLayer.lineWidth = 1
        dashLayer.lineDashPattern = [4, 4]
        layer.addSublayer(dashLayer)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 1)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        dashLayer.frame = bounds

        let path = UIBezierPath()
        let y = bounds.height / 2
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: bounds.width, y: y))
        dashLayer.path = path.cgPath
    }
}
