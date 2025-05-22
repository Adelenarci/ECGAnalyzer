//
//  ContentView.swift
//  ECGAnalyzer
//
//  Created by Ali Kaan Karagözgil on 8.05.2025.
//

import SwiftUI

struct FileLocation: Hashable {
    let folder: String
    let file: String?
}

struct ContentView: View {
    @State private var uncategorizedCSVs: [String] = []
    @State private var folders: [String] = []
    @State private var availableFolders: [String] = []
    @State private var selectedFolder: String = ""
    @State private var newFolderName = ""
    @State private var hkAuthorized = false
    @State private var sortAscending = false

    private var baseURL: URL { FileManagerHelper.shared.ecgBaseFolder }
    private var uncURL: URL { baseURL.appendingPathComponent("Uncategorized") }

    var body: some View {
        NavigationStack {
            Picker("Sort by date", selection: $sortAscending) {
                Text("Newest First").tag(false)
                Text("Oldest First").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.horizontal, .top])
            .onChange(of: sortAscending) {
                loadLists()
            }
            
            List {
                Section(header: Text("Uncategorized ECGs")) {
                    if uncategorizedCSVs.isEmpty {
                        Text("No ECGs yet").foregroundColor(.secondary)
                    } else {
                        ForEach(uncategorizedCSVs, id: \.self) { file in
                            ECGFileRowView(file: file)
                        }
                    }
                }

                Section("Folders") {
                    if folders.isEmpty {
                        Text("No folders").foregroundColor(.secondary)
                    } else {
                        ForEach(folders, id: \.self) { f in
                            NavigationLink(f, value: FileLocation(folder: f, file: nil))
                        }
                    }
                }

                Section("Actions") {
                    Button("Authorize HealthKit") {
                        print("Authorize HealthKit button tapped")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            HealthKitManager.shared.requestAuthorization { success in
                                DispatchQueue.main.async {
                                    print("Authorization result: \(success)")
                                }
                            }
                        }
                    }

                    Button("Export All ECGs") {
                        HealthKitManager.shared.fetchAllECGs { ecgs in
                            for ecg in ecgs {
                                HealthKitManager.shared.exportECGToCSV(ecg: ecg) { success in
                                    if success {
                                        print("ECG exported at \(ecg.startDate)")
                                    } else {
                                        print("Failed to export ECG")
                                    }
                                }
                            }
                        }
                    }
                    
                    Button("Refresh List") {
                        loadLists()
                    }

                    HStack {
                        TextField("New folder name", text: $newFolderName)
                            .textFieldStyle(.roundedBorder)
                        Button("Create") {
                            guard !newFolderName.isEmpty else { return }
                            _ = FileManagerHelper.shared.createSubfolder(named: newFolderName)
                            loadLists()
                            newFolderName = ""
                        }
                    }
                }
            }
            .navigationTitle("ECG Files")
            .navigationDestination(for: FileLocation.self) { loc in
                if loc.file != nil {
                    FileDetailView(location: loc) { loadLists() }
                } else {
                    FolderDetailView(folderName: loc.folder) { loadLists() }
                }
            }
            .onAppear {
                FileManagerHelper.shared.createECGBaseFolderIfNeeded()
                loadLists()
            }
        }
    }

    private func loadLists() {
        uncategorizedCSVs = FileManagerHelper.shared.listCSVFiles(in: uncURL, ascending: sortAscending)
        folders = FileManagerHelper.shared.listSubfolders().filter { $0 != "Uncategorized" }
    }
}

struct ECGFileRowView: View {
    let file: String

    var body: some View {
        NavigationLink(file, value: FileLocation(folder: "Uncategorized", file: file))
            .padding(.vertical, 4)
    }
}
