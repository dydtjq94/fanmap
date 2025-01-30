//
//  HapticStyle.swift
//  Storyworld
//
//  Created by peter on 1/30/25.
//


import UIKit

enum HapticStyle {
    case light, medium, heavy, soft, rigid

    var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        case .soft: return .soft
        case .rigid: return .rigid
        }
    }
}

extension UIImpactFeedbackGenerator {
    static func trigger(_ style: HapticStyle) {
        let generator = UIImpactFeedbackGenerator(style: style.impactStyle)
        generator.prepare()  // 미리 준비 (더 부드러운 피드백 제공)
        generator.impactOccurred()
    }
}