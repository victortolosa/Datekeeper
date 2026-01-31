//
//  ImageProcessor.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/31/26.
//

import UIKit

struct ImageProcessor {

    /// Resizes an image to fit within a maximum width while maintaining aspect ratio.
    /// - Parameters:
    ///   - image: The source image to resize.
    ///   - maxWidth: The maximum width for the resized image (default 1200px).
    /// - Returns: A resized UIImage.
    static func resize(_ image: UIImage, maxWidth: CGFloat = 1200) -> UIImage {
        let originalSize = image.size

        // If image is already smaller than maxWidth, return as-is
        guard originalSize.width > maxWidth else {
            return image
        }

        let scale = maxWidth / originalSize.width
        let newSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage
    }

    /// Compresses an image to JPEG data.
    /// - Parameters:
    ///   - image: The source image to compress.
    ///   - quality: The JPEG compression quality (0.0 to 1.0, default 0.8).
    /// - Returns: JPEG data or nil if compression fails.
    static func compress(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }

    /// Crops an image to the specified rect.
    /// - Parameters:
    ///   - image: The source image to crop.
    ///   - rect: The crop rectangle in the image's coordinate space.
    /// - Returns: The cropped UIImage, or nil if cropping fails.
    static func crop(_ image: UIImage, to rect: CGRect) -> UIImage? {
        // Handle image orientation by drawing to a normalized context first
        let normalizedImage = normalizeOrientation(image)

        guard let cgImage = normalizedImage.cgImage else { return nil }

        // Ensure rect is within bounds
        let imageRect = CGRect(origin: .zero, size: normalizedImage.size)
        let clampedRect = rect.intersection(imageRect)

        guard !clampedRect.isEmpty,
              let croppedCGImage = cgImage.cropping(to: clampedRect) else {
            return nil
        }

        return UIImage(cgImage: croppedCGImage, scale: normalizedImage.scale, orientation: .up)
    }

    /// Normalizes the image orientation to .up.
    /// - Parameter image: The source image.
    /// - Returns: An image with orientation normalized to .up.
    static func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(at: .zero)
        }
    }

    /// Processes an image for upload: resizes and compresses.
    /// - Parameters:
    ///   - image: The source image.
    ///   - maxWidth: Maximum width (default 1200px).
    ///   - quality: JPEG quality (default 0.8).
    /// - Returns: Processed UIImage ready for upload.
    static func processForUpload(_ image: UIImage, maxWidth: CGFloat = 1200) -> UIImage {
        let normalized = normalizeOrientation(image)
        return resize(normalized, maxWidth: maxWidth)
    }
}
