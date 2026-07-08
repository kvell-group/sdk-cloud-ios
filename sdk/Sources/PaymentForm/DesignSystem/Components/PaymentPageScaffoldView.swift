//
//  PaymentPageScaffoldView.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

final class PaymentPageScaffoldView: UIView {

    let scrollView = UIScrollView()
    let orderDetails = OrderDetailsView()
    let footer = PaymentPageFooterView()

    private let contentContainer = UIView()
    private var contentView: UIView?

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
        backgroundColor = KvellDesign.Color.surface

        scrollView.backgroundColor = KvellDesign.Color.surface
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate(scrollView.pinToSuperviewEdges())

        let contentLayoutView = UIView()
        contentLayoutView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentLayoutView)

        NSLayoutConstraint.activate([
            contentLayoutView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentLayoutView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentLayoutView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentLayoutView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentLayoutView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [
            orderDetails,
            DashedDividerView(),
            contentContainer,
            DashedDividerView(),
            footer
        ])
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentLayoutView.addSubview(stack)
        NSLayoutConstraint.activate(stack.pinToSuperviewEdges())
    }

    func setContent(_ view: UIView) {
        contentView?.removeFromSuperview()
        contentView = view

        view.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(view)
        NSLayoutConstraint.activate(view.pinToSuperviewEdges())
    }
}
