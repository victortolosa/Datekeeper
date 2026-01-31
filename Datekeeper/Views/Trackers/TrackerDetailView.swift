//
//  TrackerDetailView.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import SwiftUI
import Combine

struct TrackerDetailView: View {
    @State var tracker: Tracker
    @State private var timeString: String = ""
    @State private var isShowingEdit = false
    
    // Timer to update the display every second (or minute)
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            VStack {
                Spacer()
                
                Text(tracker.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.bottom, 8)
                
                Text(timeString)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text(tracker.targetDate.formatted(date: .long, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
        }
        .onReceive(timer) { _ in
            updateTime()
        }
        .onAppear {
            updateTime()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isShowingEdit = true
                }
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            EditTrackerView(trackerToEdit: tracker, defaultType: tracker.type)
        }
    }
    
    private var backgroundView: some View {
        // Placeholder for Mesh Gradient or Image
        Color(tracker.colorTheme == "blue" ? .systemBlue :
              tracker.colorTheme == "red" ? .systemRed :
              tracker.colorTheme == "green" ? .systemGreen :
              tracker.colorTheme == "orange" ? .systemOrange :
              tracker.colorTheme == "purple" ? .systemPurple : .systemGray)
        .opacity(0.1)
        .ignoresSafeArea()
    }
    
    private func updateTime() {
        timeString = TimeFormatterUtils.formattedString(
            from: tracker.type == "since" ? tracker.targetDate : Date(),
            to: tracker.type == "since" ? Date() : tracker.targetDate,
            type: tracker.type
        )
    }
}
