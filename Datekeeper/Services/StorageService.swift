//
//  StorageService.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import Foundation
import FirebaseStorage
import UIKit

class StorageService {
    static let shared = StorageService()

    // Lazy to ensure Firebase is configured before accessing
    private var storage: StorageReference {
        Storage.storage().reference()
    }

    private init() {}
    
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageConversionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let ref = storage.child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        
        return url.absoluteString
    }
    
    func delete(path: String) async throws {
        try await storage.child(path).delete()
    }

    /// Extracts the storage path from a Firebase Storage download URL.
    /// - Parameter url: The download URL (e.g., "https://firebasestorage.googleapis.com/.../o/trackers%2FuserId%2Ffile.jpg?...")
    /// - Returns: The decoded storage path (e.g., "trackers/userId/file.jpg"), or nil if parsing fails.
    func extractPath(from url: String) -> String? {
        guard let urlComponents = URLComponents(string: url),
              let path = urlComponents.path.split(separator: "/o/").last else {
            return nil
        }
        // The path is URL-encoded, decode it
        return String(path).removingPercentEncoding
    }

    /// Deletes an image using its download URL.
    /// - Parameter url: The Firebase Storage download URL.
    func deleteByUrl(_ url: String) async throws {
        guard let path = extractPath(from: url) else {
            print("StorageService: Could not extract path from URL: \(url)")
            return
        }
        try await delete(path: path)
    }

    /// Uploads both original and cropped versions of an image.
    /// - Parameters:
    ///   - original: The original full-size image.
    ///   - cropped: The 4:3 cropped version.
    ///   - basePath: The base storage path (e.g., "trackers/{userId}").
    /// - Returns: A tuple containing both download URLs.
    func uploadImagePair(
        original: UIImage,
        cropped: UIImage,
        basePath: String
    ) async throws -> (originalUrl: String, croppedUrl: String) {
        let uuid = UUID().uuidString

        // Process and compress images in parallel background tasks
        async let originalDataTask = processAndCompress(original)
        async let croppedDataTask = processAndCompress(cropped)
        
        guard let originalData = await originalDataTask,
              let croppedData = await croppedDataTask else {
            throw NSError(
                domain: "ImageProcessingError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to process images"]
            )
        }

        // Upload both in parallel
        async let originalUrl = uploadData(originalData, path: "\(basePath)/\(uuid)_original.jpg")
        async let croppedUrl = uploadData(croppedData, path: "\(basePath)/\(uuid)_cropped.jpg")

        return try await (originalUrl, croppedUrl)
    }

    private func processAndCompress(_ image: UIImage) async -> Data? {
        return await Task.detached(priority: .userInitiated) {
            let processed = ImageProcessor.processForUpload(image)
            return ImageProcessor.compress(processed, quality: 0.8)
        }.value
    }

    private func uploadData(_ data: Data, path: String) async throws -> String {
        let ref = storage.child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()

        return url.absoluteString
    }
}
