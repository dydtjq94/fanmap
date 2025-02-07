//
//  VideoChannel.swift
//  Storyworld
//
//  Created by peter on 2/7/25.
//

import UIKit

enum VideoChannel: String, Codable, CaseIterable {
    case chimchakMan = "UCUj6rrhMTR9pipbAWBAMvUQ"
    case wowakGood = "UCBkyj16n2snkRg1BAzpovXQ"
    case wooJungIng = "UCW945UjEs6Jm3rVNvPEALdg"
    case bokyeomTV = "UCu9BCtGIEr73LXZsKmoujKw"
    case baduners = "UC5xLohcPE65Y-U62X6snmRQ"
    case pisikUniversity = "UCGX5sP4ehBkihHwt5bs5wvg"
    case channel15ya = "UCQ2O-iftmnlfrBuNsUUTofQ"
    case byeolNoms = "UCXTQWsvCnuKxqnbBFMYhrSA"
    case beautifulNerd = "UCe9f9MVu4WVCA3tVWtgSswA"
    case miMiMiNu = "UCyNHdF4hMxHUFSsPbY24p6A"
    case baekJongWon = "UCyn-K7rZLXjGl7VXGweIlcA"
    case spotv = "UCtm_QoN2SIxwCE-59shX7Qg"
    case malWangTV = "UCYJDUekoQz0-bo8al1diLWQ"
    case fitvely = "UC3hRpIQ4x5niJDwjajQSVPg"
    case kwakTube = "UClRNDVO8093rmRTtLe4GEPw"
    case paniBottle = "UCNhofiqfw5nl-NeDJkXtPvw"
    case gamst = "UCbFzvzDu17eDZ3RIeaLRswQ"
    case syukaWorld = "UCsJ6RuBiTVWRX156FVbeaGg"
    case unrealScience = "UCMc4EmuDxnHPc6pgGW-QWvQ"
    case itSub = "UCdUcjkyZtf-1WJyPPiETF1g"
    case ohBunSoonSak = "UC9idb-NIhZrI6wkPesc3MUg"
    case chongMyeotMyeong = "UCRuSxVu4iqTK5kCh90ntAgA"
    case bbangBbangDaily = "UCI2T1_bAtgnKKzfhw3Qib9w"
    case zzalToon = "UCszFjh7CEfwDb7UUGb4RzCQ"
    
    func localized() -> String {
        switch self {
        case .chimchakMan: return "침착맨"
        case .wowakGood: return "우왁굳"
        case .wooJungIng: return "우정잉"
        case .bokyeomTV: return "보겸TV"
        case .baduners: return "빠더너스 BDNS"
        case .pisikUniversity: return "피식대학"
        case .channel15ya: return "채널십오야"
        case .byeolNoms: return "별놈들"
        case .beautifulNerd: return "뷰티풀너드"
        case .miMiMiNu: return "미미미누"
        case .baekJongWon: return "백종원"
        case .spotv: return "SPOTV"
        case .malWangTV: return "말왕TV"
        case .fitvely: return "핏블리"
        case .kwakTube: return "곽튜브"
        case .paniBottle: return "빠니보틀"
        case .gamst: return "감스트GAMST"
        case .syukaWorld: return "슈카월드"
        case .unrealScience: return "안될과학"
        case .itSub: return "ITSub잇섭"
        case .ohBunSoonSak: return "오분순삭"
        case .chongMyeotMyeong: return "총몇명"
        case .bbangBbangDaily: return "빵빵이의 일상"
        case .zzalToon: return "짤툰"
        }
    }
    
    
    var imageName: String {
        return "\(self)_profile"
    }
    
    static func getChannelName(by channelId: String) -> String {
        return VideoChannel(rawValue: channelId)?.localized() ?? "침착맨"
    }
    
    static func getChannelImageName(by channelId: String) -> String {
        return VideoChannel(rawValue: channelId)?.imageName ?? "default_profile"
    }
}
