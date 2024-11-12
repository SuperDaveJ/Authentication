//
//  PinEntryDotsView.swift
//  Authentication
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import UIKit

protocol PinEntryDotsViewDelegate: class {
    func pinEntryKeyInput(_ sender: PinEntryDotsView, didChangeText text: String)
    func pinEntryKeyInputPinCount() -> Int
}

/// This class stores, validates, and displays the user's PIN entry
class PinEntryDotsView: UIStackView, UIKeyInput {
    private var pinText = ""

    weak var delegate: PinEntryDotsViewDelegate?
    var isEnabled = true
    var keyboardType: UIKeyboardType = .numberPad

    var hasText: Bool { return pinText.count > 0 }
    override var canBecomeFirstResponder: Bool { return true }

    func insertText(_ text: String) {
        let candidateText = pinText + text
        let pinEntryKeyInputCount = delegate?.pinEntryKeyInputPinCount() ?? 0

        guard isEnabled,
            !text.contains("\n"),
            candidateText.count <= pinEntryKeyInputCount
        else {
                return
        }

        pinText.append(text)
        delegate?.pinEntryKeyInput(self, didChangeText: candidateText)
    }

    func deleteBackward() {
        guard pinText.count > 0 else { return }
        pinText.removeLast()
        delegate?.pinEntryKeyInput(self, didChangeText: pinText)
    }

    func clear() {
        pinText.removeAll()
        delegate?.pinEntryKeyInput(self, didChangeText: pinText)
    }
}
