//
//  MediaMixVBS25App.swift
//  MediaMixVBS25
//
//  Created by Rahel Arnold on 24.12.2024.
//

import SwiftUI

@main
struct MediaMixVBS25App: App {
    
    @StateObject private var resultsManager = ResultsManager()

        var body: some Scene {
            WindowGroup("Main Window") {
                QuerySystemView()
                    .environmentObject(resultsManager)
            }.defaultSize(width: 800, height: 600)

            WindowGroup("Results Window", id: "resultsWindow") {
                        ResultsView()
                            .environmentObject(resultsManager)
                    }
                    .defaultSize(width: 800, height: 600) // Set an appropriate size for visionOS
        }
               
    }

