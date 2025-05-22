//
//  FileManagerHelper.swift
//  ECGAnalyzer
//
//  Created by Ali Kaan Karagözgil on 8.05.2025.
//

import Foundation
import Compression
import ZIPFoundation

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
    
    func fileExistsInAnyFolder(named fileName: String) -> Bool {
        let allFolders = listSubfolders()
        for folder in allFolders {
            let filePath = ecgBaseFolder.appendingPathComponent(folder).appendingPathComponent("\(fileName).csv")
            if fileManager.fileExists(atPath: filePath.path) {
                return true
            }
        }
        return false
    }

    // MARK: - Save ECG as CSV
    func saveECGCSV(_ csv: String, for date: Date) -> Bool {
        guard let folder = createSubfolder(named: "Uncategorized") else {
            return false
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = formatter.string(from: date)

        if fileExistsInAnyFolder(named: fileName) {
            print("File with name \(fileName) already exists in some folder.")
            return false
        }
        return saveCSV(data: csv, to: folder, fileName: fileName)
    }

    func saveCSV(data: String, to folder: URL, fileName: String) -> Bool {
        let fileURL = folder.appendingPathComponent("\(fileName).csv")
        
        // Avoid overwriting
        if fileManager.fileExists(atPath: fileURL.path) {
            print("File already exists: \(fileURL.lastPathComponent)")
            return false
        }
        
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

    func listCSVFiles(in folder: URL, ascending: Bool = true) -> [String] {
        do {
            let items = try fileManager.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            let csvFiles = items.filter { $0.pathExtension == "csv" }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"

            let sorted = csvFiles.sorted {
                let date1 = dateFormatter.date(from: $0.deletingPathExtension().lastPathComponent) ?? .distantPast
                let date2 = dateFormatter.date(from: $1.deletingPathExtension().lastPathComponent) ?? .distantPast
                return ascending ? (date1 < date2) : (date1 > date2)
            }

            return sorted.map { $0.lastPathComponent }
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

    // MARK: - Folder Integrity Check
    func validateFileSystemIntegrity() {
        FileManagerHelper.shared.createECGBaseFolderIfNeeded()

        let existingFolders = FileManagerHelper.shared.listSubfolders()
        if !existingFolders.contains("Uncategorized") {
            _ = FileManagerHelper.shared.createSubfolder(named: "Uncategorized")
        }
    }

    //MARK: - ZIP MAKER
    func exportFolderAsZip(named folderName: String) -> URL? {
        let folderURL = ecgBaseFolder.appendingPathComponent(folderName)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let zipFileName = "\(folderName)_\(timestamp).zip"
        let destinationURL = ecgBaseFolder.appendingPathComponent(zipFileName)

        guard fileManager.fileExists(atPath: folderURL.path) else {
            print("Folder does not exist: \(folderURL.path)")
            return nil
        }

        do {
            let existingItems = try fileManager.contentsOfDirectory(at: ecgBaseFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            for item in existingItems {
                if item.pathExtension == "zip" && item.lastPathComponent.hasPrefix(folderName + "_") {
                    try fileManager.removeItem(at: item)
                }
            }

            try fileManager.zipItem(at: folderURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Failed to zip folder: \(error)")
            return nil
        }
    }
}
