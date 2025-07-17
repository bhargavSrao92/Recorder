//
//  TranscriptView.swift
//  Recording App
//
//  Created by Bhargav  S on 17/07/25.
//

import SwiftUI
import Foundation
import CoreData

struct TranscriptListView: View {
    @FetchRequest(
        entity: Item.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.date, ascending: false)]
    ) var items: FetchedResults<Item>

    var body: some View {
        NavigationView {
            List {
                ForEach(groupedTranscripts.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(formattedDate(date))) {
                        let uniqueItems = Array(Set(groupedTranscripts[date] ?? []))
                        ForEach(uniqueItems, id: \.self) { item in
                            Text(item.text ?? "No transcript")
                                .font(.body)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }

            .navigationTitle("Transcripts")
        }
    }

    var groupedTranscripts: [Date: [Item]] {
        var seen: Set<String> = []
        let uniqueItems = items.filter { item in
            guard let text = item.text, let date = item.date else { return false }
            let key = "\(text)-\(date)"
            if seen.contains(key) {
                return false
            } else {
                seen.insert(key)
                return true
            }
        }
        
        return Dictionary(grouping: uniqueItems) { item in
            item.date?.stripTime() ?? Date.distantPast
        }
    }


    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

extension Date {
    func stripTime() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(from: components) ?? self
    }
}
