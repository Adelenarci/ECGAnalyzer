//
//  FileManagerHelper.swift
//  ECGAnalyzer
//
//  Created by Ali Kaan Karagözgil on 8.05.2025.
//

import Foundation

class FileManagerHelper {
    static let shared = FileManagerHelper()
    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Base ECG Folder
    var ecgBaseFolder: URL {
        documentsDirectory.appendingPathComponent("ECGFiles")
    }

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func createECGBaseFolderIfNeeded() {
        if !fileManager.fileExists(atPath: ecgBaseFolder.path) {
            do {
                try fileManager.createDirectory(at: ecgBaseFolder, withIntermediateDirectories: true, attributes: nil)
                print("ECG folder created at: \(ecgBaseFolder.path)")
            } catch {
                print("Failed to create ECG folder: \(error)")
            }
        } else {
            print("ECG folder already exists at: \(ecgBaseFolder.path)")
        }

        // Always ensure Uncategorized exists too
        _ = createSubfolder(named: "Uncategorized")
    }

    // MARK: - Subfolder creation
    func createSubfolder(named name: String) -> URL? {
        let folderURL = ecgBaseFolder.appendingPathComponent(name)
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                print("Subfolder created: \(name)")
            } catch {
                print("Error creating subfolder '\(name)': \(error)")
                return nil
            }
        }
        return folderURL
    }

    // MARK: - Save ECG as CSV
    func saveECGCSV(_ csv: String, for date: Date) -> Bool {
        guard let folder = createSubfolder(named: "Uncategorized") else {
            return false
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = formatter.string(from: date)

        return saveCSV(data: csv, to: folder, fileName: fileName)
    }

    func saveCSV(data: String, to folder: URL, fileName: String) -> Bool {
        let fileURL = folder.appendingPathComponent("\(fileName).csv")
        do {
            try data.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Saved CSV to: \(fileURL.path)")
            return true
        } catch {
            print("Failed to save CSV: \(error)")
            return false
        }
    }

    // MARK: - Read folder and file lists
    func listSubfolders() -> [String] {
        do {
            let items = try fileManager.contentsOfDirectory(at: ecgBaseFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            return items.filter { $0.hasDirectoryPath }.map { $0.lastPathComponent }
        } catch {
            print("Failed to list subfolders: \(error)")
            return []
        }
    }

    func listCSVFiles(in folder: URL) -> [String] {
        do {
            let items = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            return items.filter { $0.pathExtension == "csv" }.map { $0.lastPathComponent }
        } catch {
            print("Failed to list CSV files in folder: \(error)")
            return []
        }
    }

    func loadCSVContents(from folder: String, file: String) -> String? {
        let fileURL = ecgBaseFolder.appendingPathComponent(folder).appendingPathComponent(file)
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }
    
    func renameCSVFile(in folder: String, from oldName: String, to newName: String) -> Bool {
        let oldURL = ecgBaseFolder.appendingPathComponent(folder).appendingPathComponent(oldName)
        let newURL = ecgBaseFolder.appendingPathComponent(folder).appendingPathComponent(newName)

        do {
            try fileManager.moveItem(at: oldURL, to: newURL)
            print("Renamed file: \(oldName) -> \(newName)")
            return true
        } catch {
            print("Failed to rename file: \(error)")
            return false
        }
    }
    
    func moveCSVFile(named fileName: String, from sourceFolder: String, to destinationFolder: String) -> Bool {
        let sourceURL = ecgBaseFolder.appendingPathComponent(sourceFolder).appendingPathComponent(fileName)
        let destinationURL = ecgBaseFolder.appendingPathComponent(destinationFolder).appendingPathComponent(fileName)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                print("A file with the same name already exists at destination.")
                return false
            }
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            print("Moved file: \(fileName) from \(sourceFolder) to \(destinationFolder)")
            return true
        } catch {
            print("Failed to move file: \(error)")
            return false
        }
    }
}
