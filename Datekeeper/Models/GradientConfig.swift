//
//  GradientConfig.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import Foundation

struct GradientConfig: Codable, Hashable {
    var colors: [String] // ["#hex", ...]
    var seed: Int?
}
