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

    var body: some View {
        NavigationView {
            List {
                ForEach(recordings, id: \.self) { url in
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                             Text(url.deletingPathExtension().lastPathComponent)

                                .font(.headline)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                        Spacer()

                        Button(action: {
                            play(url: url)
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        }
                        .buttonStyle(BorderlessButtonStyle())

                        Button(action: {
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.vertical, 12) // 🔼 Increase row height
                }
                .onDelete(perform: deleteRecording) // ✅ Swipe to delete
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

    func share(url: URL) {
        
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
    struct ShareSheet: UIViewControllerRepresentable {
        let activityItems: [Any]
        
        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
            // no update needed
        }
    }
}
