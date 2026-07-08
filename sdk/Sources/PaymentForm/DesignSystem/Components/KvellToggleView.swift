//
//  KvellToggleView.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

final class KvellToggleView: UIControl {

    var onToggle: ((Bool) -> Void)?

    private let track = UIView()
    private let knob = UIView()
    private var knobLeadingConstraint: NSLayoutConstraint!
    private var knobTrailingConstraint: NSLayoutConstraint!

    private var _isOn = false
    var isOn: Bool {
        get { _isOn }
        set { setOn(newValue, animated: false) }
    }

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
        widthAnchor.constraint(equalToConstant: 28).isActive = true
        heightAnchor.constraint(equalToConstant: 16).isActive = true

        track.isUserInteractionEnabled = false
        track.layer.cornerRadius = 8
        track.translatesAutoresizingMaskIntoConstraints = false
        addSubview(track)

        knob.isUserInteractionEnabled = false
        knob.backgroundColor = .white
        knob.layer.cornerRadius = 6
        knob.layer.shadowColor = UIColor(red: 20, green: 21, blue: 26, alpha: 0.05).cgColor
        knob.layer.shadowOffset = CGSize(width: 0, height: 1)
        knob.layer.shadowRadius = 2
        knob.layer.shadowOpacity = 1
        knob.translatesAutoresizingMaskIntoConstraints = false
        addSubview(knob)

        NSLayoutConstraint.activate([
            track.topAnchor.constraint(equalTo: topAnchor),
            track.bottomAnchor.constraint(equalTo: bottomAnchor),
            track.leadingAnchor.constraint(equalTo: leadingAnchor),
            track.trailingAnchor.constraint(equalTo: trailingAnchor),

            knob.widthAnchor.constraint(equalToConstant: 12),
            knob.heightAnchor.constraint(equalToConstant: 12),
            knob.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        knobLeadingConstraint = knob.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2)
        knobTrailingConstraint = knob.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2)
        knobLeadingConstraint.isActive = true

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        applyState(animated: false)
    }

    @objc private func handleTap() {
        setOn(!_isOn, animated: true)
        onToggle?(_isOn)
    }

    func setOn(_ on: Bool, animated: Bool) {
        _isOn = on
        applyState(animated: animated)
    }

    private func applyState(animated: Bool) {
        knobLeadingConstraint.isActive = !_isOn
        knobTrailingConstraint.isActive = _isOn

        let updates = {
            self.track.backgroundColor = self._isOn ? KvellDesign.Color.buttonPrimary : KvellDesign.Color.toggleOff
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: updates)
        } else {
            updates()
        }
    }
}
