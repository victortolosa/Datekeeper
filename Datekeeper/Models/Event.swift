//
//  Event.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import Foundation
import FirebaseFirestore


struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var startDate: Date
    var recurrenceRule: String // iCal RRULE format
    var category: String
    var colorTheme: String
    var gradientConfig: GradientConfig?
    @ServerTimestamp var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case startDate = "start_date"
        case recurrenceRule = "recurrence_rule"
        case category
        case colorTheme = "color_theme"
        case gradientConfig = "gradient_config"
        case createdAt = "created_at"
    }
}
