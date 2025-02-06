//
//  ImageCache.swift
//  Storyworld
//
//  Created by peter on 2/6/25.
//


import UIKit

class ImageCache {
    static let shared = ImageCache()
    private init() {}

    private var cache = NSCache<NSString, UIImage>()

    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}