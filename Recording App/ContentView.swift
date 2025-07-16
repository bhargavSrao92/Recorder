//
//  ContentView.swift
//  Recording App
//
//  Created by Bhargav  S on 15/07/25.
//

import SwiftUI
import UIKit

struct RecordingTranscriptionApp: View {
    @StateObject private var recorder = AudioRecorder()
    @State private var showList = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            VStack(spacing: 16) {
                navigationViewHeader(patientName: "John Davis")
                transcriptionView
                Spacer()
                controlButtons
            }
        }
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showList) {
            RecordingListView()
        }
    }
    private func navigationViewHeader(patientName: String) -> some View {
        ZStack(alignment: .topLeading) {
            Color.blue
                .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Button(action: {
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.title2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recording Session")
                            .font(.headline)
                            .foregroundColor(.white)
                            .bold()

                        Text("Patient: \(patientName)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.95))
                    }

                    Spacer()
                }

                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .foregroundColor(.white)
                        Text(recorder.recordingDuration)
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }

                    Spacer()

                    Text("● Recording")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.purple.opacity(0.9)))
                }

            }
            .padding(.horizontal)
            .padding(.top, 50) 
        }
        .frame(height: 140)
    }

    private var statusIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
            Text(recorder.recordingDuration)
            Capsule()
                .fill(recorder.state == .recording ? Color.red : Color.gray)
                .frame(width: 10, height: 10)
                .font(.caption)
                .foregroundColor(.purple)
        }
        .padding(8)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    private var transcriptionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Live Transcription")
                .font(.headline)
                .foregroundColor(.black)

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Text(recorder.transcript.isEmpty ? "Listening..." : recorder.transcript)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if recorder.state == .recording {
                        LoadingDots()
                            .padding(.top, 4)
                    }else{
                        Text("")
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .frame(minHeight: 120, maxHeight: 200)
        }
        .padding()
    }
    struct LoadingDots: View {
        @State private var animate = false

        var body: some View {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animate ? 1 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animate
                        )
                }
            }
            .onAppear {
                animate = true
            }
        }
    }
    private var controlButtons: some View {
        HStack(spacing: 24) {
            if recorder.state == .idle || recorder.state == .paused {
                CircleButton(
                    systemName: "play.fill",
                    background: .blue,
                    action: {
                        if recorder.state == .paused {
                            recorder.resumeRecording()
                        } else {
                            recorder.startRecording()
                        }
                    }
                )
                CircleButton(
                    systemName: "list.bullet",
                    background: .red,
                    action: {
                        showList = true
                    }
                )
            } else if recorder.state == .recording {
                CircleButton(
                    systemName: "pause.fill",
                    background: .blue,
                    action: {
                        recorder.pauseRecording()
                    }
                )
                CircleButton(
                    systemName: "stop.fill",
                    background: Color(.darkGray),
                    action: {
                        recorder.stopRecording()
                    }
                )
            }
        }
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
    }
}
struct CircleButton: View {
    let systemName: String
    let background: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(background)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
}
