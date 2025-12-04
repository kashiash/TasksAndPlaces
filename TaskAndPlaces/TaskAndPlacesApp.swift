//
//  TaskAndPlacesApp.swift
//  TaskAndPlaces
//
//  Created by Jacek Kosiński on 04/12/2025.
//

import SwiftUI
import SwiftData

@main
struct TaskAndPlacesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Location.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // Inicjalizacja loadera danych
    @MainActor
    private func seedData() {
        DataLoader.shared.seedData(context: sharedModelContainer.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    seedData()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
