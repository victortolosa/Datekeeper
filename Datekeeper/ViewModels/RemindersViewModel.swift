//
//  RemindersViewModel.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class RemindersViewModel: ObservableObject {
    @Published var reminders: [Reminder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service = FirestoreService<Reminder>(collectionPath: "reminders")
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        if let userId = AuthService.shared.currentUser?.uid {
            setupListener(for: userId)
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func setupListener(for userId: String) {
        isLoading = true
        listenerRegistration = service.listen(for: userId) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let reminders):
                self.reminders = reminders.sorted { $0.date < $1.date }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func addReminder(title: String, date: Date, description: String = "") async -> Bool {
        guard let userId = AuthService.shared.currentUser?.uid else { return false }
        
        let reminder = Reminder(
            id: nil,
            userId: userId,
            title: title,
            description: description.isEmpty ? nil : description,
            date: date,
            category: "General",
            colorTheme: "blue",
            gradientConfig: nil
        )
        
        do {
            try service.add(reminder)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func delete(id: String) {
        Task {
            do {
                try await service.delete(id: id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
