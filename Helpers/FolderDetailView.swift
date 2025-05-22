//
//  FolderDetailView.swift
//  ECGAnalyzer
//
//  Created by Ali Kaan Karagözgil on 8.05.2025.
//

import SwiftUI

struct FolderDetailView: View {
    let folderName: String
    var onRefresh: () -> Void

    @State private var files: [String] = []
    @State private var sortAscending = false
    
    @State private var showShareSheet = false
    @State private var exportURL: URL?

    var body: some View {
        Picker("Sort", selection: $sortAscending) {
            Text("Newest First").tag(false)
            Text("Oldest First").tag(true)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)

        List {
            if files.isEmpty {
                Text("No files in folder").foregroundColor(.secondary)
            } else {
                ForEach(files, id: \.self) { file in
                    NavigationLink(file, value: FileLocation(folder: folderName, file: file))
                }
            }
        }
        .navigationTitle(folderName)
        .onAppear {
            let folderURL = FileManagerHelper.shared.ecgBaseFolder.appendingPathComponent(folderName)
            files = FileManagerHelper.shared.listCSVFiles(in: folderURL, ascending: sortAscending)
        }
        .onChange(of: sortAscending) {
            let folderURL = FileManagerHelper.shared.ecgBaseFolder.appendingPathComponent(folderName)
            files = FileManagerHelper.shared.listCSVFiles(in: folderURL, ascending: sortAscending)
        }
        
        Button {
            if let zipURL = FileManagerHelper.shared.exportFolderAsZip(named: folderName) {
                exportURL = zipURL
                showShareSheet = true
            }
        } label: {
            Label("Download Folder", systemImage: "arrow.down.circle")
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
}
