//
//  CachedImage.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/31/26.
//

import SwiftUI

struct CachedImage<Placeholder: View>: View {
    let url: URL?
    let transition: AnyTransition
    let animation: Animation
    let contentMode: ContentMode
    @ViewBuilder let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(
        url: URL?,
        transition: AnyTransition = .opacity.combined(with: .scale(scale: 0.95)),
        animation: Animation = .easeOut(duration: 0.4),
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.transition = transition
        self.animation = animation
        self.contentMode = contentMode
        self.placeholder = placeholder
    }
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(transition)
            } else {
                placeholder()
                    .transition(.opacity)
            }
        }
        .animation(animation, value: image)
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _, _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = url else { return }
        let urlString = url.absoluteString
        
        // 1. Check cache
        if let cached = ImageCacheService.shared.image(forKey: urlString) {
            self.image = cached
            return
        }
        
        // 2. Load from network
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let loadedImage = UIImage(data: data), error == nil else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            // 3. Save to cache
            ImageCacheService.shared.save(loadedImage, forKey: urlString)
            
            DispatchQueue.main.async {
                self.image = loadedImage
                self.isLoading = false
            }
        }.resume()
    }
}

#Preview {
    CachedImage(url: URL(string: "https://example.com/image.jpg")) {
        Color.gray
    }
    .frame(width: 200, height: 200)
    .clipShape(RoundedRectangle(cornerRadius: 12))
}
