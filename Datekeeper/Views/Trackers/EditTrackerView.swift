//
//  EditTrackerView.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import Combine

struct EditTrackerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = EditTrackerViewModel()
    @State private var isShowingImagePicker = false
    @State private var isShowingCropper = false
    @State private var originalImage: UIImage?
    @State private var croppedImage: UIImage?
    @State private var pendingImageForCrop: UIImage?

    var trackerToEdit: Tracker?
    var defaultType: String

    init(trackerToEdit: Tracker? = nil, defaultType: String = "since") {
        self.trackerToEdit = trackerToEdit
        self.defaultType = defaultType
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $viewModel.title)
                    
                    DatePicker("Date", selection: $viewModel.targetDate, displayedComponents: .date)
                    
                    Picker("Type", selection: $viewModel.type) {
                        Text("Since").tag("since")
                        Text("Until").tag("till")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Category", text: $viewModel.category)
                }
                
                Section(header: Text("Appearance")) {
                    Picker("Color Theme", selection: $viewModel.colorTheme) {
                        Text("Blue").tag("blue")
                        Text("Red").tag("red")
                        Text("Green").tag("green")
                        Text("Orange").tag("orange")
                        Text("Purple").tag("purple")
                    }
                    
                    Button(action: { isShowingImagePicker = true }) {
                        HStack {
                            Text("Background Image")
                            Spacer()
                            if let image = croppedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 30)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            } else if let imageUrl = viewModel.existingCroppedImageUrl ?? viewModel.existingImageUrl,
                                      let url = URL(string: imageUrl) {
                                CachedImage(url: url) {
                                    Color.gray
                                }
                                .frame(width: 40, height: 30)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            } else {
                                Text("None")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(trackerToEdit == nil ? "New Tracker" : "Edit Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await viewModel.save(
                                trackerId: trackerToEdit?.id,
                                originalImage: originalImage,
                                croppedImage: croppedImage
                            ) {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.title.isEmpty)
                }
            }
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $pendingImageForCrop)
            }
            .fullScreenCover(isPresented: $isShowingCropper) {
                if let imageToCrop = pendingImageForCrop {
                    NavigationStack {
                        ImageCropperView(
                            image: imageToCrop,
                            onCancel: {
                                pendingImageForCrop = nil
                                isShowingCropper = false
                            },
                            onDone: { cropped in
                                originalImage = imageToCrop
                                croppedImage = cropped
                                pendingImageForCrop = nil
                                isShowingCropper = false
                            }
                        )
                    }
                }
            }
            .onChange(of: pendingImageForCrop) { _, newValue in
                if newValue != nil {
                    isShowingCropper = true
                }
            }
            .onAppear {
                if let tracker = trackerToEdit {
                    viewModel.load(tracker: tracker)
                } else {
                    viewModel.type = defaultType
                }
            }
        }
    }
}

@MainActor
class EditTrackerViewModel: ObservableObject {
    @Published var title = ""
    @Published var targetDate = Date()
    @Published var type = "since"
    @Published var category = "Life"
    @Published var colorTheme = "blue"
    @Published var existingImageUrl: String?
    @Published var existingCroppedImageUrl: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService<Tracker>(collectionPath: "trackers")
    private let storageService = StorageService.shared

    func load(tracker: Tracker) {
        self.title = tracker.title
        self.targetDate = tracker.targetDate
        self.type = tracker.type
        self.category = tracker.category
        self.colorTheme = tracker.colorTheme
        self.existingImageUrl = tracker.imageUrl
        self.existingCroppedImageUrl = tracker.croppedImageUrl
    }

    func save(
        trackerId: String?,
        originalImage: UIImage?,
        croppedImage: UIImage?
    ) async -> Bool {
        guard let userId = AuthService.shared.currentUser?.uid else {
            errorMessage = "User not logged in."
            return false
        }

        isLoading = true
        errorMessage = nil

        var finalImageUrl: String? = existingImageUrl
        var finalCroppedImageUrl: String? = existingCroppedImageUrl

        // Upload image pair if new images are selected
        if let original = originalImage, let cropped = croppedImage {
            do {
                // Delete old images first (fire and forget, don't block on failure)
                // MOVED: Deletion now happens after successful update to prevent data loss


                let basePath = "trackers/\(userId)"
                let urls = try await storageService.uploadImagePair(
                    original: original,
                    cropped: cropped,
                    basePath: basePath
                )
                finalImageUrl = urls.originalUrl
                finalCroppedImageUrl = urls.croppedUrl
            } catch {
                errorMessage = "Failed to upload image: \(error.localizedDescription)"
                isLoading = false
                return false
            }
        }

        let tracker = Tracker(
            id: trackerId,
            userId: userId,
            title: title,
            targetDate: targetDate,
            type: type,
            category: category,
            colorTheme: colorTheme,
            gradientConfig: nil,
            imageUrl: finalImageUrl,
            croppedImageUrl: finalCroppedImageUrl,
            displayUnits: ["years", "months", "days"]
        )

        do {
            if trackerId != nil {
                try firestoreService.update(tracker)
            } else {
                try firestoreService.add(tracker)
            }
            
            // If we replaced images, delete the old ones now that the new ones are safe
            if originalImage != nil && existingImageUrl != nil {
                 await deleteOldImages()
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    /// Deletes old images from storage when replacing with new ones.
    private func deleteOldImages() async {
        // Delete old original image
        if let oldOriginalUrl = existingImageUrl {
            do {
                try await storageService.deleteByUrl(oldOriginalUrl)
            } catch {
                // Log but don't fail - old image cleanup is best effort
                print("Failed to delete old original image: \(error.localizedDescription)")
            }
        }

        // Delete old cropped image
        if let oldCroppedUrl = existingCroppedImageUrl {
            do {
                try await storageService.deleteByUrl(oldCroppedUrl)
            } catch {
                print("Failed to delete old cropped image: \(error.localizedDescription)")
            }
        }
    }
}
