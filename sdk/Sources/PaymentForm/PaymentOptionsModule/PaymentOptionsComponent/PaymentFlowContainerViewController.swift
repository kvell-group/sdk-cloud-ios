//
//  PaymentFlowContainerViewController.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

final class PaymentFlowContainerViewController: BaseViewController {

    let header = PaymentPageHeaderView()

    var navigation: UINavigationController { childNavigationController }

    var onClose: (() -> Void)? {
        didSet { header.onClose = onClose }
    }

    private let statusBarBackdrop = UIView()
    private let divider = UIView()
    private let contentContainerView = UIView()
    private let childNavigationController: UINavigationController
    private let sessionDeadline: Date?
    private var countdown: PaymentSessionCountdownTimer?

    init(rootViewController: UIViewController, sessionDeadline: Date?) {
        self.childNavigationController = UINavigationController(rootViewController: rootViewController)
        self.sessionDeadline = sessionDeadline
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        countdown?.stop()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = KvellDesign.Color.surface
        setupLayout()
        setupChildNavigation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCountdownIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        countdown?.stop()
    }

    func setCloseEnabled(_ enabled: Bool) {
        header.setCloseEnabled(enabled)
    }

    private func setupLayout() {
        statusBarBackdrop.backgroundColor = KvellDesign.Color.surface
        statusBarBackdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusBarBackdrop)

        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        divider.backgroundColor = KvellDesign.Color.divider
        divider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(divider)

        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentContainerView)

        NSLayoutConstraint.activate([
            statusBarBackdrop.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarBackdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBarBackdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBarBackdrop.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            divider.topAnchor.constraint(equalTo: header.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            contentContainerView.topAnchor.constraint(equalTo: divider.bottomAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupChildNavigation() {
        childNavigationController.isNavigationBarHidden = true
        childNavigationController.view.backgroundColor = .clear

        addChild(childNavigationController)
        childNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(childNavigationController.view)
        NSLayoutConstraint.activate(childNavigationController.view.pinToSuperviewEdges())
        childNavigationController.didMove(toParent: self)
    }

    private func startCountdownIfNeeded() {
        if let countdown {
            countdown.start()
            return
        }

        guard let sessionDeadline else {
            header.setRemainingTime(nil)
            return
        }

        let newCountdown = PaymentSessionCountdownTimer(deadline: sessionDeadline) { [weak self] text in
            self?.header.setRemainingTime(text)
        }
        countdown = newCountdown
        newCountdown.start()
    }
}
