//
//  ImageCropperView.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/31/26.
//

import SwiftUI

struct ImageCropperView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onDone: (UIImage) -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var containerSize: CGSize = .zero
    @State private var isProcessing = false

    private let aspectRatio: CGFloat = 4.0 / 3.0

    var body: some View {
        GeometryReader { geometry in
            let cropFrame = calculateCropFrame(in: geometry.size)

            ZStack {
                Color.black.ignoresSafeArea()

                // The image that can be panned and zoomed
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageDisplaySize(in: geometry.size).width,
                           height: imageDisplaySize(in: geometry.size).height)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let newScale = lastScale * value
                                    scale = min(max(newScale, 1.0), 5.0)
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        constrainOffset(cropFrame: cropFrame, imageSize: imageDisplaySize(in: geometry.size))
                                    }
                                },
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        constrainOffset(cropFrame: cropFrame, imageSize: imageDisplaySize(in: geometry.size))
                                    }
                                }
                        )
                    )

                // Overlay with cutout for crop area
                CropOverlay(cropFrame: cropFrame, containerSize: geometry.size)

                // Crop frame border
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: cropFrame.width, height: cropFrame.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    
                if isProcessing {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
            .clipped()
            .onAppear {
                containerSize = geometry.size
            }
            .onChange(of: geometry.size) { _, newSize in
                containerSize = newSize
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
                .foregroundColor(.white)
                .disabled(isProcessing)
            }

            ToolbarItem(placement: .confirmationAction) {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Button("Done") {
                        processCrop()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .interactiveDismissDisabled(isProcessing)
    }

    private func calculateCropFrame(in containerSize: CGSize) -> CGRect {
        let maxWidth = containerSize.width - 40
        let maxHeight = containerSize.height - 160

        var cropWidth = maxWidth
        var cropHeight = cropWidth / aspectRatio

        if cropHeight > maxHeight {
            cropHeight = maxHeight
            cropWidth = cropHeight * aspectRatio
        }

        let originX = (containerSize.width - cropWidth) / 2
        let originY = (containerSize.height - cropHeight) / 2

        return CGRect(x: originX, y: originY, width: cropWidth, height: cropHeight)
    }

    private func imageDisplaySize(in containerSize: CGSize) -> CGSize {
        let imageAspect = image.size.width / image.size.height
        let cropFrame = calculateCropFrame(in: containerSize)

        // Size the image so it at minimum covers the crop frame
        if imageAspect > aspectRatio {
            // Image is wider than crop frame, constrain by height
            let height = max(cropFrame.height, containerSize.height)
            return CGSize(width: height * imageAspect, height: height)
        } else {
            // Image is taller than crop frame, constrain by width
            let width = max(cropFrame.width, containerSize.width)
            return CGSize(width: width, height: width / imageAspect)
        }
    }

    private func constrainOffset(cropFrame: CGRect, imageSize: CGSize) {
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale

        let maxOffsetX = (scaledWidth - cropFrame.width) / 2
        let maxOffsetY = (scaledHeight - cropFrame.height) / 2

        offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
        offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
        lastOffset = offset
    }

    private func processCrop() {
        isProcessing = true
        
        // Capture all necessary values for background processing
        let inputImage = image
        let currentScale = scale
        let currentOffset = offset
        let currentContainerSize = containerSize
        let cropFrame = calculateCropFrame(in: containerSize)
        let displaySize = imageDisplaySize(in: containerSize)
        
        Task {
            let croppedImage = await Task.detached(priority: .userInitiated) {
                return Self.performBackgroundCrop(
                    image: inputImage,
                    scale: currentScale,
                    offset: currentOffset,
                    containerSize: currentContainerSize,
                    cropFrame: cropFrame,
                    displaySize: displaySize
                )
            }.value
            
            await MainActor.run {
                isProcessing = false
                if let cropped = croppedImage {
                    onDone(cropped)
                }
            }
        }
    }
    
    private static func performBackgroundCrop(
        image: UIImage,
        scale: CGFloat,
        offset: CGSize,
        containerSize: CGSize,
        cropFrame: CGRect,
        displaySize: CGSize
    ) -> UIImage? {
        let normalizedImage = ImageProcessor.normalizeOrientation(image)

        guard let cgImage = normalizedImage.cgImage else { return nil }

        // Calculate the visible portion of the image in the crop frame
        let scaledImageWidth = displaySize.width * scale
        let scaledImageHeight = displaySize.height * scale

        // Image center in container coordinates
        let imageCenterX = containerSize.width / 2 + offset.width
        let imageCenterY = containerSize.height / 2 + offset.height

        // Crop frame center
        let cropCenterX = containerSize.width / 2
        let cropCenterY = containerSize.height / 2

        // Offset from image center to crop frame center
        let deltaX = cropCenterX - imageCenterX
        let deltaY = cropCenterY - imageCenterY

        // Convert to image coordinates (normalized to scaled image)
        let visibleX = (scaledImageWidth / 2 + deltaX - cropFrame.width / 2) / scale
        let visibleY = (scaledImageHeight / 2 + deltaY - cropFrame.height / 2) / scale
        let visibleWidth = cropFrame.width / scale
        let visibleHeight = cropFrame.height / scale

        // Convert from display coordinates to actual image coordinates
        let scaleToImage = CGFloat(cgImage.width) / displaySize.width

        let cropRect = CGRect(
            x: visibleX * scaleToImage,
            y: visibleY * scaleToImage,
            width: visibleWidth * scaleToImage,
            height: visibleHeight * scaleToImage
        )

        return ImageProcessor.crop(normalizedImage, to: cropRect)
    }
}

struct CropOverlay: View {
    let cropFrame: CGRect
    let containerSize: CGSize

    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.6)

            // Cut out the crop area
            Rectangle()
                .frame(width: cropFrame.width, height: cropFrame.height)
                .position(x: containerSize.width / 2, y: containerSize.height / 2)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .allowsHitTesting(false)
    }
}

#Preview {
    NavigationStack {
        ImageCropperView(
            image: UIImage(systemName: "photo")!,
            onCancel: {},
            onDone: { _ in }
        )
    }
}
