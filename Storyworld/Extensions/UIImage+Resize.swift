//
//  UIImage+Resize.swift
//  Storyworld
//
//  Created by peter on 2/6/25.
//

import UIKit

extension UIImage {
    // 특정 너비로 크기 조정
    func resized(toWidth width: CGFloat) -> UIImage {
        let scale = width / self.size.width
        let newHeight = self.size.height * scale
        let newSize = CGSize(width: width, height: newHeight)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
