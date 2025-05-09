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

    var body: some View {
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
            files = FileManagerHelper.shared.listCSVFiles(in: folderURL)
        }
    }
}
