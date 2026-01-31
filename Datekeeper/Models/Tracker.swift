//
//  Tracker.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import Foundation
import FirebaseFirestore


struct Tracker: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var targetDate: Date
    var type: String // "since" | "till"
    var category: String
    var colorTheme: String
    var gradientConfig: GradientConfig?
    var imageUrl: String?
    var displayUnits: [String]? // e.g. ["years", "months", "days"]
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case targetDate = "target_date"
        case type
        case category
        case colorTheme = "color_theme"
        case gradientConfig = "gradient_config"
        case imageUrl = "image_url"
        case displayUnits = "display_units"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
