//
//  Reminder.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import Foundation
import FirebaseFirestore


struct Reminder: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var description: String?
    var date: Date
    var category: String
    var colorTheme: String
    var gradientConfig: GradientConfig?
    @ServerTimestamp var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case date
        case category
        case colorTheme = "color_theme"
        case gradientConfig = "gradient_config"
        case createdAt = "created_at"
    }
}
