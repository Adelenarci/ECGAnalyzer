//
//  FileDetailView.swift
//  ECGAnalyzer
//
//  Created by Ali Kaan Karagözgil on 8.05.2025.
//

import SwiftUI

struct FileDetailView: View {
    let location: FileLocation
    var onRefresh: () -> Void

    @State private var showShareSheet = false
    @State private var fileURL: URL?
    @State private var folders: [String] = []
    @State private var selectedFolder: String = ""
    @State private var parsedECG: [(Double, Double)] = []
    @State private var showGraph = false
    @State private var showMoveSuccess = false
    @State private var aiComment: String = ""
    @State private var isGeneratingComment = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let fileURL = fileURL {
                    if showGraph {
                        ECGGraphView(csvData: parsedECG)
                            .frame(height: 300)
                    }

                    if !aiComment.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                Text("AI Comment")
                                    .font(.headline)
                            } icon: {
                                Image(systemName: "brain.head.profile")
                            }
                            ScrollView {
                                Text(aiComment)
                                    .font(.body)
                                    .padding()
                            }
                            .frame(maxHeight: 200)
                        }
                    }

                    Button {
                        prepareFileURL()
                        showGraph = true
                    } label: {
                        Label("Show Graph", systemImage: "waveform.path.ecg")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        isGeneratingComment = true
                        HealthKitManager.shared.getUserInfo { height, weight, sex in
                            let csvLines = parsedECG.map { String(format: "%.4f;%.5f", $0.0, $0.1) }
                            let ecgCSV = "Time;Voltage\nsec;mV\n" + csvLines.joined(separator: "\n")
                            OpenAIManager.shared.generateECGComment(ecgCSV: ecgCSV, height: height, weight: weight, sex: sex) { comment in
                                DispatchQueue.main.async {
                                    aiComment = comment ?? "No comment generated."
                                    isGeneratingComment = false
                                }
                            }
                        }
                    } label: {
                        Label("Generate AI Comment", systemImage: "brain.head.profile")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isGeneratingComment)

                    Button {
                        prepareFileURL()
                        showShareSheet = true
                    } label: {
                        Label("Share File", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .sheet(isPresented: $showShareSheet) {
                        ShareSheet(activityItems: [fileURL])
                    }

                    Divider()

                    Picker("Move to folder", selection: $selectedFolder) {
                        ForEach(folders, id: \.self) { folder in
                            Text(folder)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Button {
                        if let fileName = location.file {
                            let moved = FileManagerHelper.shared.moveCSVFile(
                                named: fileName,
                                from: location.folder,
                                to: selectedFolder
                            )
                            if moved {
                                showMoveSuccess = true
                                onRefresh()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showMoveSuccess = false
                                }
                            }
                        }
                    } label: {
                        Label("Move File", systemImage: "folder.fill.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedFolder.isEmpty)

                    if showMoveSuccess {
                        Label("File moved successfully", systemImage: "checkmark.circle")
                            .foregroundColor(.green)
                    }
                } else {
                    Text("File not available.")
                        .onAppear {
                            prepareFileURL()
                        }
                }
            }
            .padding(.top, 40)
            .padding(.horizontal)
        }
        .onAppear {
            let all = FileManagerHelper.shared.listSubfolders()
            folders = all.filter { $0 != location.folder }
            selectedFolder = folders.first ?? ""
        }
        .navigationTitle("Details of ECG File")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func prepareFileURL() {
        guard let file = location.file else { return }

        let path = FileManagerHelper.shared
            .ecgBaseFolder
            .appendingPathComponent(location.folder)
            .appendingPathComponent(file)

        if FileManager.default.fileExists(atPath: path.path) {
            self.fileURL = path
            self.parsedECG = parseCSV(fileURL: path)
        } else {
            print("File not found: \(path)")
        }
    }

    private func parseCSV(fileURL: URL) -> [(Double, Double)] {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines).dropFirst(2)
            return lines.compactMap { line in
                let parts = line.split(whereSeparator: { $0 == "," || $0 == ";" })
                guard parts.count == 2,
                      let time = Double(parts[0]),
                      let voltage = Double(parts[1]) else { return nil }
                return (time, voltage)
            }
        } catch {
            print("CSV parse error: \(error)")
            return []
        }
    }
}
