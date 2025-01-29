//
//  DropView.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import UIKit

final class DropView: UIView {
    let dropImageView = UIImageView()
    let playButton = UIButton()  // 중앙에 배치될 play 버튼
    
    var onPlayButtonTapped: (() -> Void)?  // 클릭 이벤트 클로저
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
        
        // Play Icon View (중앙에 SF Symbol 추가)
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 36, weight: .bold)
        let playImage = UIImage(systemName: "play.fill", withConfiguration: largeConfig)
        
        playButton.setImage(playImage, for: .normal)
        playButton.tintColor = .white
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        addSubview(playButton)
        
        // Drop Image View (썸네일 이미지)
        dropImageView.contentMode = .scaleAspectFill
        dropImageView.layer.cornerRadius = 10
        dropImageView.clipsToBounds = true
        dropImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dropImageView)
        
        // Layout 설정
        NSLayoutConstraint.activate([
            dropImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
            dropImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
            dropImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
            dropImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16),
            
            // playButton 중앙 배치
            playButton.centerXAnchor.constraint(equalTo: dropImageView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: dropImageView.centerYAnchor),
        ])
    }
    
    func dropSettingView(genre: String, rarity: String) {
        
        let randomImageNumber = Int.random(in: 1...11)
        let imageName = "image\(randomImageNumber)"
        dropImageView.image = UIImage(named: imageName)
        
        if UIImage(named: imageName) != nil {
            // 원하는 가로/세로 비율 설정 (330:185)
            let widthRatio: CGFloat = 330
            let heightRatio: CGFloat = 185
            let aspectRatio = heightRatio / widthRatio
            
            NSLayoutConstraint.activate([
                dropImageView.heightAnchor.constraint(equalTo: dropImageView.widthAnchor, multiplier: aspectRatio),
            ])
        }
        
        // 기존 블러 뷰 제거 (중복 방지)
        self.subviews.forEach { subview in
            if subview is UIVisualEffectView {
                subview.removeFromSuperview()
            }
        }
        
        // 블러 효과 추가
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        //        blurEffectView.alpha = 0.8  // 불투명도 조절 (0.0 ~ 1.0)
        blurEffectView.layer.cornerRadius = 10
        blurEffectView.clipsToBounds = true
        
        // DropView에 블러 뷰 추가 (dropImageView의 크기와 일치하도록)
        self.addSubview(blurEffectView)
        
        // 블러 뷰의 크기를 dropImageView에 맞춤
        NSLayoutConstraint.activate([
            blurEffectView.leadingAnchor.constraint(equalTo: dropImageView.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: dropImageView.trailingAnchor),
            blurEffectView.topAnchor.constraint(equalTo: dropImageView.topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: dropImageView.bottomAnchor)
        ])
        
        // 아이콘을 최상단으로 배치
        self.bringSubviewToFront(playButton)
    }
    
    @objc private func playButtonTapped() {
        print("Play button tapped!")
        onPlayButtonTapped?()  // 클로저 호출
    }
}

