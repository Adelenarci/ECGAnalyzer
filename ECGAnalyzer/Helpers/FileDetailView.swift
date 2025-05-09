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

    var body: some View {
        VStack(spacing: 20) {
            if let fileURL = fileURL {
                Button("Share File") {
                    prepareFileURL()
                    if fileURL != nil {
                        showShareSheet = true
                    }
                }
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

                Button("Move File") {
                    if let fileName = location.file {
                        let moved = FileManagerHelper.shared.moveCSVFile(
                            named: fileName,
                            from: location.folder,
                            to: selectedFolder
                        )
                        if moved {
                            onRefresh()
                        }
                    }
                }
                .disabled(selectedFolder.isEmpty)
            } else {
                Text("File not available.")
                    .onAppear {
                        prepareFileURL()
                    }
            }
        }
        .onAppear {
            let all = FileManagerHelper.shared.listSubfolders()
            folders = all.filter { $0 != location.folder }
            selectedFolder = folders.first ?? ""
        }
        .navigationTitle("Export CSV")
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
        } else {
            print("File not found: \(path)")
        }
    }
}
