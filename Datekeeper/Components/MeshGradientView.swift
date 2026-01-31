//
//  MeshGradientView.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/31/26.
//

import SwiftUI

struct MeshGradientView: View {
    let config: GradientConfig
    
    var body: some View {
        if #available(iOS 18.0, *) {
            NativeMeshGradient(config: config)
        } else {
            MeshGradientFallbackView(config: config)
        }
    }
}

// MARK: - iOS 18 Native Implementation
@available(iOS 18.0, *)
struct NativeMeshGradient: View {
    let config: GradientConfig
    
    private var meshColors: [Color] {
        // Ensure we strictly have 4 colors for a 2x2 grid
        let inputColors = config.colors.map { Color(hex: $0) }
        guard !inputColors.isEmpty else { return [.gray, .gray, .gray, .gray] }
        
        var result = inputColors
        // Pad with the last color if we have fewer than 4
        while result.count < 4 {
            result.append(result.last ?? .gray)
        }
        // Truncate to 4 if we have more
        return Array(result.prefix(4))
    }
    
    var body: some View {
        MeshGradient(
            width: 2,
            height: 2,
            points: [
                .init(0, 0), .init(1, 0),
                .init(0, 1), .init(1, 1)
            ],
            colors: meshColors
        )
        .ignoresSafeArea()
    }
}

// MARK: - iOS 17 Fallback Implementation
struct MeshGradientFallbackView: View {
    let config: GradientConfig
    
    private var distinctColors: [Color] {
        let inputColors = config.colors.map { Color(hex: $0) }
        guard !inputColors.isEmpty else { return [.gray] }
        return inputColors
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Background base
                distinctColors.first ?? .black
                
                // Overlay organic blobs
                if distinctColors.count > 1 {
                    ForEach(1..<min(distinctColors.count, 4), id: \.self) { index in
                        Circle()
                            .fill(distinctColors[index])
                            .blur(radius: 60)
                            .opacity(0.8)
                            .frame(width: proxy.size.width * 0.8, height: proxy.size.height * 0.8)
                            .position(
                                x: position(for: index, in: proxy.size).x,
                                y: position(for: index, in: proxy.size).y
                            )
                    }
                }
            }
            .background(distinctColors.first ?? .black)
        }
        .ignoresSafeArea()
    }
    
    func position(for index: Int, in size: CGSize) -> CGPoint {
        // Simple static distribution for fallback
        switch index {
        case 1: return CGPoint(x: size.width * 0.8, y: size.height * 0.2)
        case 2: return CGPoint(x: size.width * 0.2, y: size.height * 0.8)
        case 3: return CGPoint(x: size.width * 0.8, y: size.height * 0.8)
        default: return CGPoint(x: size.width / 2, y: size.height / 2)
        }
    }
}

#Preview {
    let sampleConfig = GradientConfig(
        colors: ["#0a565c", "#18126e", "#430d0a", "#282b08"],
        seed: 253378
    )
    
    return MeshGradientView(config: sampleConfig)
}
