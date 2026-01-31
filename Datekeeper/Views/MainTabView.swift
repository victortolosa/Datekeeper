//
//  MainTabView.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TrackersListView(trackerType: "since")
                .tabItem {
                    Label("Milestones", systemImage: "flag")
                }

            TrackersListView(trackerType: "till")
                .tabItem {
                    Label("Countdowns", systemImage: "timer")
                }

            RemindersListView()
                .tabItem {
                    Label("Remember", systemImage: "bell")
                }
        }
    }
}

#Preview {
    MainTabView()
}
