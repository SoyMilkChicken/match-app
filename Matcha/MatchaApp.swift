// MatchaApp.swift
// Matcha

import SwiftUI
import SwiftData

@main
struct MatchaApp: App {
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            Sticker.self,
            DrinkLog.self,
            UserStats.self,
            CustomDrink.self,
            PlacedSticker.self
        ])
        
        // CRITICAL FIX: Set cloudKitDatabase to .none
        // This prevents SwiftData from trying to sync with the misconfigured iCloud container
        let config = ModelConfiguration(
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("⚠️ ModelContainer failed: \(error)")
            print("⚠️ Attempting to reset database...")
            
            // Delete existing store and retry
            do {
                let url = URL.applicationSupportDirectory.appending(path: "default.store")
                let fileManager = FileManager.default
                
                // Remove all associated files (wal, shm)
                let storePaths = [
                    url,
                    url.deletingPathExtension().appendingPathExtension("store-shm"),
                    url.deletingPathExtension().appendingPathExtension("store-wal")
                ]
                
                for path in storePaths {
                    if fileManager.fileExists(atPath: path.path) {
                        try fileManager.removeItem(at: path)
                    }
                }

                // Retry with the same local-only config
                container = try ModelContainer(for: schema, configurations: [config])
                print("✅ Database reset successful")
            } catch {
                // If this fails, we really can't recover, but the local-only config usually fixes it.
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
