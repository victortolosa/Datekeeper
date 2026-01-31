//
//  TimeFormatterUtils.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import Foundation

struct TimeFormatterUtils {
    
    struct TimeComponents {
        var years: Int
        var months: Int
        var days: Int
    }
    
    static func calculateComponents(from start: Date, to end: Date) -> TimeComponents {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: start, to: end)
        
        return TimeComponents(
            years: abs(components.year ?? 0),
            months: abs(components.month ?? 0),
            days: abs(components.day ?? 0)
        )
    }
    
    static func formattedString(from start: Date, to end: Date, type: String) -> String {
        let components = calculateComponents(from: start, to: end)
        var parts: [String] = []
        
        if components.years > 0 {
            parts.append("\(components.years) year\(components.years == 1 ? "" : "s")")
        }
        
        if components.months > 0 {
            parts.append("\(components.months) month\(components.months == 1 ? "" : "s")")
        }
        
        if components.days > 0 {
            parts.append("\(components.days) day\(components.days == 1 ? "" : "s")")
        }
        
        if parts.isEmpty {
            return "Today"
        }
        
        let timeString = parts.joined(separator: ", ")
        
        if type == "since" {
            return "\(timeString) ago"
        } else {
            return "in \(timeString)"
        }
    }
}
