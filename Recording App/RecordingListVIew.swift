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


    var body: some View {
        NavigationView {
            List {
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
            do {
                try FileManager.default.removeItem(at: url)
                let transcriptURL = url.deletingPathExtension().appendingPathExtension("txt")
                try? FileManager.default.removeItem(at: transcriptURL)
            } catch {
                print("Failed to delete: \(error)")
            }
        }
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
