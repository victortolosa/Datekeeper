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
    @State private var selectedImage: UIImage?
    
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
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            } else if let imageUrl = viewModel.existingImageUrl, let url = URL(string: imageUrl) {
                                // Simple AsyncImage for now, could use Nuke later
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Color.gray
                                    }
                                }
                                .frame(width: 40, height: 40)
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
                            if await viewModel.save(trackerId: trackerToEdit?.id, newImage: selectedImage) {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.title.isEmpty)
                }
            }
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
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
    }
    
    func save(trackerId: String?, newImage: UIImage?) async -> Bool {
        guard let userId = AuthService.shared.currentUser?.uid else {
            errorMessage = "User not logged in."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        // 1. Upload Image if new one is selected
        var finalImageUrl: String? = existingImageUrl
        
        if let image = newImage {
            do {
                let filename = "\(UUID().uuidString).jpg"
                let path = "trackers/\(userId)/\(filename)"
                // Delete old image if exists? (Skipping for now for simplicity, can handle later)
                finalImageUrl = try await storageService.uploadImage(image, path: path)
            } catch {
                errorMessage = "Failed to upload image: \(error.localizedDescription)"
                isLoading = false
                return false
            }
        }
        
        // 2. Create/Update Tracker
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
            displayUnits: ["years", "months", "days"]
        )
        
        do {
            if trackerId != nil {
                try firestoreService.update(tracker)
            } else {
                try firestoreService.add(tracker)
            }
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
