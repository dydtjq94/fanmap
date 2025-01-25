//
//  VideoGenre.swift
//  Storyworld
//
//  Created by peter on 1/17/25.
//

import UIKit

enum VideoGenre: String, Codable {
    case entertainment = "entertainment"
    case talk = "talk"
    case music = "music"
    case sports = "sports"
    case vlog = "vlog"
    case fashion = "fashion"
    case food = "food"
    case education = "education"
    case game = "game"

    func localized() -> String {
        switch self {
        case .entertainment: return "예능&웹드라마"
        case .talk: return "토크"
        case .music: return "음악&영화"
        case .sports: return "스포츠&운동"
        case .vlog: return "브이로그&여행"
        case .fashion: return "패션&뷰티"
        case .food: return "음식"
        case .education: return "교육&뉴스"
        case .game: return "게임"
        }
    }

    var imageName: String {
        switch self {
        case .entertainment: return "entertainment_icon"
        case .talk: return "talk_icon"
        case .music: return "music_icon"
        case .sports: return "sports_icon"
        case .vlog: return "vlog_icon"
        case .fashion: return "fashion_icon"
        case .food: return "food_icon"
        case .education: return "education_icon"
        case .game: return "game_icon"
        }
    }

    var uiColor: UIColor {
        switch self {
        case .entertainment: return UIColor(hex: "#FFA600")
        case .talk: return UIColor(hex: "#00D800")
        case .music: return UIColor(hex: "#EDED00")
        case .sports: return UIColor(hex: "#00B2FF")
        case .vlog: return UIColor(hex: "#DA5F00")
        case .fashion: return UIColor(hex: "#00F7F7")
        case .food: return UIColor(hex: "#FF5858")
        case .education: return UIColor(hex: "#FF94B7")
        case .game: return UIColor(hex: "#4D4D4D")
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .entertainment: return UIColor(hex: "#8A5A00")
        case .talk: return UIColor(hex: "#003200")
        case .music: return UIColor(hex: "#666600")
        case .sports: return UIColor(hex: "#11233D")
        case .vlog: return UIColor(hex: "#451E00")
        case .fashion: return UIColor(hex: "#004545")
        case .food: return UIColor(hex: "#5A0000")
        case .education: return UIColor(hex: "#804D5E")
        case .game: return UIColor(hex: "#E2E2E2")
        }
    }
}
