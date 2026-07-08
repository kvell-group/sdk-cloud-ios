//
//  KvellDesign.swift
//  sdk
//
//  Created by Kvell on 08.07.2026.
//  Copyright © 2026 Kvell. All rights reserved.
//

import UIKit

enum KvellDesign {

    enum Color {
        static let textPrimary = UIColor(red: 0x14, green: 0x15, blue: 0x1A, alpha: 1)
        static let textSecondary = UIColor(red: 15, green: 19, blue: 36, alpha: 0.6)
        static let textTertiary = UIColor(red: 13, green: 17, blue: 38, alpha: 0.4)
        static let textInverted = UIColor.white

        static let borderNormal = UIColor(red: 0xDE, green: 0xE0, blue: 0xE3, alpha: 1)
        static let borderAlpha = UIColor(red: 10, green: 15, blue: 41, alpha: 0.08)
        static let divider = UIColor(red: 0xE9, green: 0xEA, blue: 0xEC, alpha: 1)

        static let surface = UIColor.white
        static let buttonPrimary = UIColor(red: 0x14, green: 0x15, blue: 0x1A, alpha: 1)
        static let buttonTertiary = UIColor(red: 10, green: 15, blue: 41, alpha: 0.04)
        static let toggleOff = UIColor(red: 0xBA, green: 0xBD, blue: 0xC5, alpha: 1)
        static let surfaceWarning = UIColor(red: 0xFE, green: 0xF4, blue: 0xEC, alpha: 1)

        static let kvellPayGradientTop = UIColor(red: 0xFF, green: 0xF1, blue: 0x84, alpha: 1)
        static let kvellPayGradientBottom = UIColor(red: 0xFF, green: 0xE7, blue: 0x6D, alpha: 1)

        static let iconSecondary = textSecondary
        static let iconStatusSuccess = UIColor(red: 0x26, green: 0xBD, blue: 0x6C, alpha: 1)
    }

    enum Radius {
        static let md: CGFloat = 8
        static let lg: CGFloat = 10
        static let xl: CGFloat = 12
        static let xxxl: CGFloat = 24
    }

    enum Font {

        enum Weight {
            case regular, medium, semiBold, bold

            fileprivate var postscriptName: String {
                switch self {
                case .regular: return "Onest-Regular"
                case .medium: return "Onest-Medium"
                case .semiBold: return "Onest-SemiBold"
                case .bold: return "Onest-Bold"
                }
            }

            fileprivate var systemWeight: UIFont.Weight {
                switch self {
                case .regular: return .regular
                case .medium: return .medium
                case .semiBold: return .semibold
                case .bold: return .bold
                }
            }
        }

        struct Style {
            let font: UIFont
            let lineHeight: CGFloat
            let letterSpacing: CGFloat
        }

        static func onest(_ weight: Weight, size: CGFloat) -> UIFont {
            KvellFontRegistrar.registerIfNeeded()
            if let font = UIFont(name: weight.postscriptName, size: size) {
                return font
            }
            return .systemFont(ofSize: size, weight: weight.systemWeight)
        }

        static let bodyLBold = Style(font: onest(.bold, size: 20), lineHeight: 28, letterSpacing: -0.2)
        static let bodyMMedium = Style(font: onest(.medium, size: 18), lineHeight: 26, letterSpacing: -0.2)

        static let bodySRegular = Style(font: onest(.regular, size: 16), lineHeight: 24, letterSpacing: -0.2)
        static let bodySMedium = Style(font: onest(.medium, size: 16), lineHeight: 24, letterSpacing: -0.2)
        static let bodySSemiBold = Style(font: onest(.semiBold, size: 16), lineHeight: 24, letterSpacing: -0.2)
        static let bodySBold = Style(font: onest(.bold, size: 16), lineHeight: 24, letterSpacing: -0.2)

        static let captionLRegular = Style(font: onest(.regular, size: 14), lineHeight: 20, letterSpacing: -0.1)
        static let captionLMedium = Style(font: onest(.medium, size: 14), lineHeight: 20, letterSpacing: -0.1)

        static let captionMRegular = Style(font: onest(.regular, size: 12), lineHeight: 16, letterSpacing: 0)
    }
}

extension UILabel {

    func setStyledText(_ text: String?, style: KvellDesign.Font.Style, color: UIColor? = nil) {
        if let color {
            textColor = color
        }

        guard let text else {
            attributedText = nil
            return
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = style.lineHeight
        paragraphStyle.maximumLineHeight = style.lineHeight
        paragraphStyle.alignment = textAlignment
        paragraphStyle.lineBreakMode = lineBreakMode

        let baselineOffset = (style.lineHeight - style.font.lineHeight) / 4

        font = style.font
        attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: style.font,
                .kern: style.letterSpacing,
                .paragraphStyle: paragraphStyle,
                .baselineOffset: baselineOffset,
                .foregroundColor: textColor ?? .black
            ]
        )
    }
}
