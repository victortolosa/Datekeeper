//
//  DailyEntry.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import Foundation
import FirebaseFirestore


struct DailyEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var date: Date
    var imageUrl: String?
    var notes: String?
    var moodRating: Int? // 1-5
    @ServerTimestamp var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case imageUrl = "image_url"
        case notes
        case moodRating = "mood_rating"
        case createdAt = "created_at"
    }
}
