//
//  AddReminderView.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import SwiftUI

struct AddReminderView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: RemindersViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                
                DatePicker("Date", selection: $date)
                
                TextField("Description (Optional)", text: $description)
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        Task {
                            if await viewModel.addReminder(title: title, date: date, description: description) {
                                dismiss()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }
}
