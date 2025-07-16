//
//  ContentView.swift
//  Recording App
//
//  Created by Bhargav  S on 16/07/25.
//

import SwiftUI
import Combine
import AVFoundation
import Speech

enum RecordingState {
    case idle, recording, paused, playing
}

class AudioRecorder: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioFile: AVAudioFile?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private let writeQueue = DispatchQueue(label: "audio.write.queue")
    private var lastTranscriptUpdate = Date()

    @Published var state: RecordingState = .idle
    @Published var recordingDuration: String = "00:00"
    @Published var transcript: String = ""
    @Published var fileURL: URL?
    @Published var showShareSheet = false
    @Environment(\.managedObjectContext) private var viewContext

    private var seconds = 0 {
        didSet {
            let mins = seconds / 60
            let secs = seconds % 60
            DispatchQueue.main.async {
                self.recordingDuration = String(format: "%02d:%02d", mins, secs)
            }
        }
    }

    override init() {
        super.init()
        requestPermissions()
        configureAudioSession()
    }

    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            print("Speech authorization: \(status)")
        }
        AVAudioApplication.requestRecordPermission { granted in
            print("Mic permission: \(granted)")
        }
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error.localizedDescription)")
        }
    }

    func startRecording() {
        guard state != .recording else { return }

        resetRecording()
        state = .recording

        let inputNode = audioEngine.inputNode

        // ✅ Use hardware format to avoid crash
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        setupAudioFile(format: recordingFormat)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        guard let recognitionRequest else {
            print("Unable to create recognition request")
            return
        }

        setupRecognitionTask(with: recognitionRequest)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self else { return }

            // Append to recognition
            self.recognitionRequest?.append(buffer)

            // Write audio on background queue
            self.writeQueue.async {
                do {
                    try self.audioFile?.write(from: buffer)
                } catch {
                    print("Audio write failed: \(error)")
                }
            }
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            DispatchQueue.main.async {
                self.startTimer()
                self.state = .recording
            }
        } catch {
            print("Audio engine failed to start: \(error)")
            stopRecording()
        }
    }

    private func setupAudioFile(format: AVAudioFormat) {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Recordings")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let url = folder.appendingPathComponent(UUID().uuidString + ".caf")
        self.fileURL = url

        do {
            audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
        } catch {
            print("Failed to setup audio file: \(error.localizedDescription)")
        }
    }

    private func setupRecognitionTask(with request: SFSpeechAudioBufferRecognitionRequest) {
        lastTranscriptUpdate = Date()

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result = result {
                let now = Date()
                if now.timeIntervalSince(self.lastTranscriptUpdate) > 0.5 {
                    self.lastTranscriptUpdate = now
                    DispatchQueue.main.async {
                        self.transcript = result.bestTranscription.formattedString
                    }
                }
            }

            if let error = error {
                print("Speech recognition error: \(error.localizedDescription)")
                self.stopRecording()
            }
        }
    }

    func pauseRecording() {
        guard state == .recording else { return }
        audioEngine.pause()
        stopTimer()
        DispatchQueue.main.async { self.state = .paused }
    }

    func resumeRecording() {
        guard state == .paused else { return }
        do {
            try audioEngine.start()
            startTimer()
            DispatchQueue.main.async { self.state = .recording }
        } catch {
            print("Failed to resume recording: \(error)")
        }
    }

    func stopRecording() {
        audioEngine.inputNode.removeTap(onBus: 0)
        if audioEngine.isRunning {
            do {
                try audioEngine.stop()
            } catch {
                print("Error stopping engine: \(error)")
            }
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        stopTimer()
        DispatchQueue.main.async {
            self.seconds = 0
            self.state = .idle
        }
        saveTranscriptToCoreData(text: transcript)
    }
    
    private func saveTranscriptToCoreData(text: String) {
        let viewContext = PersistenceController.shared.container.viewContext
        let newItem = Item(context: viewContext)
        newItem.id = UUID()
        newItem.date = Date()
        newItem.text = text

        do {
            try viewContext.save()
            print("✅ Transcript saved to Core Data")
        } catch {
            print("❌ Failed to save transcript: \(error.localizedDescription)")
        }
    }


    private func resetRecording() {
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        transcript = ""
        seconds = 0
        stopTimer()
    }

    // MARK: - Playback

    func playRecording() {
        guard let url = fileURL else {
            print("No recording found")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            DispatchQueue.main.async { self.state = .playing }
        } catch {
            print("Playback failed: \(error.localizedDescription)")
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        DispatchQueue.main.async { self.state = .idle }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.state = .idle }
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.seconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Share

    func shareRecording() {
        DispatchQueue.main.async {
            self.showShareSheet = true
        }
    }
}
