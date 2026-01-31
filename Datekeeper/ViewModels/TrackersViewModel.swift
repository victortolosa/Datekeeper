//
//  TrackersViewModel.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class TrackersViewModel: ObservableObject {
    @Published var trackers: [Tracker] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service = FirestoreService<Tracker>(collectionPath: "trackers")
    private var listenerRegistration: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initial fetch or setup listener
        if let userId = AuthService.shared.currentUser?.uid {
            setupListener(for: userId)
        }

        // Listen for auth changes to re-fetch if user changes/logs in
        AuthService.shared.$currentUser
            .compactMap { $0?.uid }
            .removeDuplicates()
            .sink { [weak self] userId in
                self?.setupListener(for: userId)
            }
            .store(in: &cancellables)
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func setupListener(for userId: String) {
        isLoading = true
        listenerRegistration?.remove() // Remove existing listener if any

        print("🔍 TrackersViewModel: Setting up listener for userId: \(userId)")

        listenerRegistration = service.listen(for: userId) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false

            switch result {
            case .success(let trackers):
                print("✅ TrackersViewModel: Fetched \(trackers.count) trackers")
                for tracker in trackers {
                    print("   - \(tracker.title) (type: \(tracker.type), id: \(tracker.id ?? "nil"))")
                }
                self.trackers = trackers
            case .failure(let error):
                print("❌ TrackersViewModel: Error fetching trackers: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func signOut() {
        try? AuthService.shared.signOut()
    }
}
