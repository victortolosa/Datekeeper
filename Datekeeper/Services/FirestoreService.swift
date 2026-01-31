//
//  FirestoreService.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import Foundation
import FirebaseFirestore

import Combine

class FirestoreService<T: Codable & Identifiable> where T.ID == String? {
    private let collectionRef: CollectionReference
    
    init(collectionPath: String) {
        self.collectionRef = Firestore.firestore().collection(collectionPath)
    }
    
    // MARK: - Update
    // Helper to allow updating just fields instead of full overwrites
    // Note: This requires mapping the object to a dictionary, or just manual updates
    // For Codable, standard is usually to overwrite or setMerge
    
    func add(_ item: T) throws {
        try collectionRef.addDocument(from: item)
    }
    
    func update(_ item: T) throws {
        guard let id = item.id else { return }
        try collectionRef.document(id).setData(from: item, merge: true)
    }
    
    func delete(id: String) async throws {
        try await collectionRef.document(id).delete()
    }
    
    // MARK: - Fetching
    
    func fetchAll(for userId: String) async throws -> [T] {
        let snapshot = try await collectionRef
            .whereField("user_id", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: T.self)
        }
    }
    
    // DEBUG: Fetch all documents without userId filter
    func debugFetchAll() async {
        print("🐛 DEBUG: Fetching ALL documents from \(collectionRef.path) (no filter)")
        do {
            let snapshot = try await collectionRef.getDocuments()
            print("🐛 DEBUG: Found \(snapshot.documents.count) total documents")
            for doc in snapshot.documents {
                print("   📄 ID: \(doc.documentID)")
                print("      Data: \(doc.data())")
            }
        } catch {
            print("🐛 DEBUG: Error fetching all: \(error)")
        }
    }

    // Real-time listener
    func listen(for userId: String, completion: @escaping (Result<[T], Error>) -> Void) -> ListenerRegistration {
        print("🔥 FirestoreService: Querying \(collectionRef.path) where userId == \(userId)")

        return collectionRef
            .whereField("user_id", isEqualTo: userId)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("🔥 FirestoreService: Query error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    print("🔥 FirestoreService: No documents found")
                    completion(.success([]))
                    return
                }

                print("🔥 FirestoreService: Found \(documents.count) raw documents")
                for doc in documents {
                    print("   📄 Document ID: \(doc.documentID)")
                    print("      Raw data: \(doc.data())")
                }

                let items = documents.compactMap { document -> T? in
                    do {
                        return try document.data(as: T.self)
                    } catch {
                        print("   ⚠️ Failed to decode document \(document.documentID): \(error)")
                        return nil
                    }
                }
                print("🔥 FirestoreService: Successfully decoded \(items.count) items")
                completion(.success(items))
            }
    }
}
