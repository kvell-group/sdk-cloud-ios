//
//  PaymentSessionCountdownTimer.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import Foundation

final class PaymentSessionCountdownTimer {

    private let deadline: Date
    private let onTick: (String) -> Void
    private var timer: Timer?

    init(deadline: Date, onTick: @escaping (String) -> Void) {
        self.deadline = deadline
        self.onTick = onTick
    }

    func start() {
        tick()
        timer?.invalidate()
        let newTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let remaining = max(0, Int(deadline.timeIntervalSinceNow.rounded(.up)))
        onTick(String(format: "%02d:%02d", remaining / 60, remaining % 60))
    }
}
