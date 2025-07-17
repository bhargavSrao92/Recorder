//
//  RecordingListVIew.swift
//  Recording App
//
//  Created by Bhargav  S on 15/07/25.
//
import SwiftUI
import AVFoundation
import Speech


struct RecordingListView: View {
    @State private var recordings: [URL] = []
    @State private var player: AVAudioPlayer?
    
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.date, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>
    @Environment(\.managedObjectContext) var context


    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink {
                        TranscriptListView()
                    } label: {
                        Text("Transcript")
                    }
                }

                Section(header: Text("Recordings")) {
                    ForEach(recordings, id: \.self) { url in
                        let fileName = url.deletingPathExtension().lastPathComponent
                        let matchingTranscript = items.first(where: {
                            ($0.date?.formattedFileName() ?? "") == fileName
                        })

                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(fileName)
                                    .font(.headline)
                                    .lineLimit(1)
                                    .truncationMode(.middle)

                                if let transcript = matchingTranscript?.text {
                                    Text(transcript)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()

                            Button(action: {
                                play(url: url)
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                            }

                            Button(action: {
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .onDelete(perform: deleteRecording)
                }
            }
            .navigationTitle("Recordings")
            .onAppear(perform: loadRecordings)
        }
    }


    func loadRecordings() {
        guard let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Recordings") else {
            recordings = []
            return
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            recordings = files
                .filter { $0.pathExtension == "caf" }
                .sorted {
                    $0.deletingPathExtension().lastPathComponent > $1.deletingPathExtension().lastPathComponent
                }
        } catch {
            print("Failed to load recordings: \(error)")
            recordings = []
        }
    }

    func deleteRecording(at offsets: IndexSet) {
        for index in offsets {
            let url = recordings[index]
            let fileName = url.deletingPathExtension().lastPathComponent
            
            // Delete the .caf audio file
            do {
                try FileManager.default.removeItem(at: url)
                
                // Optional: Delete .txt file if used
                let transcriptURL = url.deletingPathExtension().appendingPathExtension("txt")
                try? FileManager.default.removeItem(at: transcriptURL)
            } catch {
                print("Failed to delete file: \(error)")
            }
            
            // 🧠 Delete matching Core Data transcript
            if let match = items.first(where: {
                ($0.date?.formattedFileName() ?? "") == fileName
            }) {
                context.delete(match)
            }
        }

        // 💾 Save Core Data changes
        do {
            try context.save()
        } catch {
            print("Failed to save context after deletion: \(error)")
        }

        // 🔁 Refresh the UI
        loadRecordings()
    }


    func play(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("Playback error: \(error)")
        }
    }

}

extension Date {
    func formattedFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: self)
    }
}
