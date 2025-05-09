//
//   Create ECGSelectionView.swift
//  ECGAnalyzer
//
//  Created by Ali Kaan Karagözgil on 8.05.2025.
//
import SwiftUI
import HealthKit

struct ECGSelectionView: View {
    @State private var ecgs: [HKElectrocardiogram] = []
    @State private var selected: Set<HKElectrocardiogram> = []
    @State private var statusMessage: String?

    var body: some View {
        VStack {
            if ecgs.isEmpty {
                Text("No ECGs available.")
                    .padding()
            } else {
                List {
                    ForEach(ecgs, id: \.uuid) { ecg in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { selected.contains(ecg) },
                                set: { isSelected in
                                    if isSelected {
                                        selected.insert(ecg)
                                    } else {
                                        selected.remove(ecg)
                                    }
                                }
                            )) {
                                Text(dateString(from: ecg.startDate))
                            }
                        }
                    }
                }

                Button("Export Selected ECGs to CSV") {
                    if selected.isEmpty {
                        statusMessage = "No ECG selected."
                        return
                    }

                    var exportedCount = 0
                    for ecg in selected {
                        HealthKitManager.shared.exportECGToCSV(ecg: ecg) { success in
                            if success {
                                exportedCount += 1
                            }
                            if exportedCount == selected.count {
                                statusMessage = "\(exportedCount) ECG(s) exported."
                            }
                        }
                    }
                }
                .padding()
            }

            if let msg = statusMessage {
                Text(msg)
                    .foregroundColor(.gray)
                    .padding(.top)
            }
        }
        .navigationTitle("Select ECGs")
        .onAppear {
            HealthKitManager.shared.fetchAllECGs { list in
                DispatchQueue.main.async {
                    ecgs = list
                }
            }
        }
    }

    private func dateString(from date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }
}
