//
//  Recording_AppApp.swift
//  Recording App
//
//  Created by Bhargav  S on 15/07/25.
//

import SwiftUI

@main
struct Recording_AppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RecordingTranscriptionApp()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
            
        }
    }
}
