//
//  TrackersListView.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import SwiftUI

struct TrackersListView: View {
    let trackerType: String // "since" for Milestones, "till" for Countdowns

    @StateObject private var viewModel = TrackersViewModel()
    @State private var isShowingCreate = false
    enum SortField: String, CaseIterable {
        case chronological
        case title
        case category
        case created
    }
    enum SortOrder: String, CaseIterable {
        case ascending
        case descending
    }
    @State private var sortField: SortField = .chronological
    @State private var sortOrder: SortOrder = .descending

    private var filteredTrackers: [Tracker] {
        let filtered = viewModel.trackers.filter { $0.type == trackerType }
        return filtered.sorted { a, b in
            switch sortField {
            case .chronological:
                let lhs = a.targetDate
                let rhs = b.targetDate
                return sortOrder == .ascending ? lhs < rhs : lhs > rhs
            case .title:
                let lhs = a.title.lowercased()
                let rhs = b.title.lowercased()
                return sortOrder == .ascending ? lhs < rhs : lhs > rhs
            case .category:
                let lhs = a.category.lowercased()
                let rhs = b.category.lowercased()
                return sortOrder == .ascending ? lhs < rhs : lhs > rhs
            case .created:
                let lhs = a.createdAt ?? .distantPast
                let rhs = b.createdAt ?? .distantPast
                return sortOrder == .ascending ? lhs < rhs : lhs > rhs
            }
        }
    }

    private var pageTitle: String {
        trackerType == "since" ? "Milestones" : "Countdowns"
    }

    private var emptyStateTitle: String {
        trackerType == "since" ? "No Milestones" : "No Countdowns"
    }

    private var emptyStateDescription: String {
        trackerType == "since"
            ? "Track important dates from your past."
            : "Count down to upcoming events."
    }

    private var emptyStateIcon: String {
        trackerType == "since" ? "flag" : "timer"
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.trackers.isEmpty {
                    ProgressView("Loading...")
                } else if filteredTrackers.isEmpty {
                    ContentUnavailableView(
                        emptyStateTitle,
                        systemImage: emptyStateIcon,
                        description: Text(emptyStateDescription)
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTrackers) { tracker in
                                NavigationLink(destination: TrackerDetailView(tracker: tracker)) {
                                    TrackerCardView(tracker: tracker)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(pageTitle)
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Menu {
                            Menu("Chronological") {
                                Button("Ascending") { sortField = .chronological; sortOrder = .ascending }
                                Button("Descending") { sortField = .chronological; sortOrder = .descending }
                            }
                            Menu("Title") {
                                Button("A-Z") { sortField = .title; sortOrder = .ascending }
                                Button("Z-A") { sortField = .title; sortOrder = .descending }
                            }
                            Menu("Category") {
                                Button("A-Z") { sortField = .category; sortOrder = .ascending }
                                Button("Z-A") { sortField = .category; sortOrder = .descending }
                            }
                            Menu("Date Created") {
                                Button("Ascending") { sortField = .created; sortOrder = .ascending }
                                Button("Descending") { sortField = .created; sortOrder = .descending }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                        
                        Button(action: { isShowingCreate = true }) {
                            Image(systemName: "plus")
                        }
                        
                        Menu {
                            Button("Sign Out", role: .destructive, action: viewModel.signOut)
                        } label: {
                            Image(systemName: "person.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingCreate) {
                EditTrackerView(defaultType: trackerType)
            }
        }
    }
}


struct TrackerCardView: View {
    let tracker: Tracker
    
    var hasVisualBackground: Bool {
        tracker.imageUrl != nil || tracker.gradientConfig != nil
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if tracker.imageUrl != nil {
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(tracker.title)
                        .font(.headline)
                        .foregroundColor(hasVisualBackground ? .white : .primary)
                    Text(tracker.targetDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(hasVisualBackground ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                Text(TimeFormatterUtils.formattedString(from: tracker.type == "since" ? tracker.targetDate : Date(), to: tracker.type == "since" ? Date() : tracker.targetDate, type: tracker.type))
                    .font(.subheadline)
                    .foregroundColor(hasVisualBackground ? .white.opacity(0.9) : .secondary)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .frame(height: tracker.imageUrl != nil ? 250 : nil)
        .background {
            ZStack {
                if let imageUrl = tracker.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            if let config = tracker.gradientConfig {
                                MeshGradientView(config: config)
                            } else {
                                Color(uiColor: .secondarySystemBackground)
                            }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .overlay(Color.black.opacity(0.3))
                        case .failure:
                            if let config = tracker.gradientConfig {
                                MeshGradientView(config: config)
                            } else {
                                Color(uiColor: .secondarySystemBackground)
                            }
                        @unknown default:
                            Color(uiColor: .secondarySystemBackground)
                        }
                    }
                } else if let config = tracker.gradientConfig {
                    MeshGradientView(config: config)
                } else {
                    Color(uiColor: .secondarySystemBackground)
                }
            }
        }
        .cornerRadius(12)
        .clipped() // Ensure image doesn't bleed out of corners
    }
}

#Preview("Milestones") {
    TrackersListView(trackerType: "since")
}

#Preview("Countdowns") {
    TrackersListView(trackerType: "till")
}

