//
//  LogsViewController.swift
//  demo
//
//  Экран просмотра dev-логов (сырые HTTP request/response из LoggingNetworkDispatcher).
//  Дублирует то, что печатается в консоль Xcode, — чтобы лог был виден
//  прямо на устройстве/симуляторе. Только для тестирования.
//

import UIKit
import KvellDevKit

final class LogsViewController: UIViewController {

    private let textView: UITextView = {
        let view = UITextView()
        view.isEditable = false
        view.alwaysBounceVertical = true
        view.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Logs"
        view.backgroundColor = .systemBackground

        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareLog)),
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(clearLog))
        ]

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(logDidChange),
            name: DevLogStore.didChangeNotification,
            object: nil
        )

        reload()
    }

    @objc private func logDidChange() {
        DispatchQueue.main.async { [weak self] in
            self?.reload()
        }
    }

    private func reload() {
        let text = DevLogStore.shared.text
        textView.text = text.isEmpty ? "Лог пуст. Запустите оплату в режиме Dev backend." : text
        scrollToBottom()
    }

    private func scrollToBottom() {
        // NSRange считает в UTF-16, String.count — в графемах: на эмодзи/кириллице разъедутся.
        let length = (textView.text as NSString).length
        guard length > 0 else { return }
        textView.scrollRangeToVisible(NSRange(location: length - 1, length: 1))
    }

    @objc private func shareLog() {
        let activity = UIActivityViewController(
            activityItems: [DevLogStore.shared.text],
            applicationActivities: nil
        )
        activity.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?.first
        present(activity, animated: true)
    }

    @objc private func clearLog() {
        DevLogStore.shared.clear()
    }
}
