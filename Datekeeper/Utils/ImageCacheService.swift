//
//  ImageCacheService.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/31/26.
//

import UIKit
import CryptoKit

class ImageCacheService {
    static let shared = ImageCacheService()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    
    private var diskCacheURL: URL {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ImageCache")
    }
    
    private init() {
        memoryCache.countLimit = 100 // Cache up to 100 images in memory
        memoryCache.totalCostLimit = 1024 * 1024 * 50 // 50 MB limit
        
        if !fileManager.fileExists(atPath: diskCacheURL.path) {
            try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        }
    }
    
    func image(forKey key: String) -> UIImage? {
        // 1. Check Memory Cache
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            return cachedImage
        }
        
        // 2. Check Disk Cache
        let fileURL = diskCacheURL.appendingPathComponent(hashKey(key))
        if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
            // Add back to memory cache
            memoryCache.setObject(image, forKey: key as NSString)
            return image
        }
        
        return nil
    }
    
    func save(_ image: UIImage, forKey key: String) {
        // 1. Save to Memory
        memoryCache.setObject(image, forKey: key as NSString)
        
        // 2. Save to Disk
        DispatchQueue.global(qos: .background).async {
            let fileURL = self.diskCacheURL.appendingPathComponent(self.hashKey(key))
            if let data = image.jpegData(compressionQuality: 0.8) {
                try? data.write(to: fileURL)
            }
        }
    }
    
    private func hashKey(_ key: String) -> String {
        let inputData = Data(key.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: diskCacheURL)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
}
