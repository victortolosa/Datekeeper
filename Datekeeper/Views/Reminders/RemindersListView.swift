//
//  RemindersListView.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import SwiftUI

struct RemindersListView: View {
    @StateObject private var viewModel = RemindersViewModel()
    @State private var isShowingAdd = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.reminders.isEmpty {
                    ProgressView()
                } else if viewModel.reminders.isEmpty {
                    ContentUnavailableView(
                        "No Reminders",
                        systemImage: "bell.slash",
                        description: Text("Stay on track by adding a reminder.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.reminders) { reminder in
                                ReminderCardView(reminder: reminder)
                                    .contextMenu {
                                        Button("Delete", role: .destructive) {
                                            if let id = reminder.id {
                                                viewModel.delete(id: id)
                                            }
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Remember")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isShowingAdd = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAdd) {
                AddReminderView(viewModel: viewModel)
            }
        }
    }
}
struct ReminderCardView: View {
    let reminder: Reminder
    
    var hasGradient: Bool {
        reminder.gradientConfig != nil
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(reminder.title)
                    .font(.headline)
                    .foregroundColor(hasGradient ? .white : .primary)
                Text(reminder.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(hasGradient ? .white.opacity(0.9) : .secondary)
            }
            
            Spacer()
        }
        .padding()
        .background {
            if let config = reminder.gradientConfig {
                MeshGradientView(config: config)
            } else {
                Color(uiColor: .secondarySystemBackground)
            }
        }
        .cornerRadius(12)
    }
}
