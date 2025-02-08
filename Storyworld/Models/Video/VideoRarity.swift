//
//  VideoRarity.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import Foundation
import UIKit

enum VideoRarity: String, Codable, CaseIterable  {
    case silver = "Silver"
    case gold = "Gold"
    case diamond = "Diamond"
    case ruby = "Ruby"
    
    var imageName: String {
        switch self {
        case .silver:
            return "silver_rarity"
        case .gold:
            return "gold_rarity"
        case .diamond:
            return "diamond_rarity"
        case .ruby:
            return "ruby_rarity"
        }
    }
    
    /// 등급에 따른 색상 반환 (추후 UI에서 사용 가능)
    var uiColor: UIColor {
        switch self {
        case .silver:
            return UIColor(hex: "#E6E6E6")
        case .gold:
            return UIColor(hex: "#EECE00")
        case .diamond:
            return UIColor(hex: "#6989BB")
        case .ruby:
            return UIColor(hex: "#CC001F")
        }
    }
    
    var backgroundColor: UIColor{
        switch self {
        case .silver:
            return UIColor(hex: "#8F8F8F")
        case .gold:
            return UIColor(hex: "#443E19")
        case .diamond:
            return UIColor(hex: "#F3FDFF")
        case .ruby:
            return UIColor(hex: "#56111D")
        }
    }
    
    var dropBackgroundColor: UIColor{
        switch self {
        case .silver:
            return UIColor(hex: "#232222")
        case .gold:
            return UIColor(hex: "#25220D")
        case .diamond:
            return UIColor(hex: "#101F22")
        case .ruby:
            return UIColor(hex: "#31121C")
        }
        
    }
    
    /// 확률 값 추가
    var probability: Double {
        switch self {
        case .silver:
            return 0.8
        case .gold:
            return 0.17
        case .diamond:
            return 0.029
        case .ruby:
            return 0.001
        }
    }
}
