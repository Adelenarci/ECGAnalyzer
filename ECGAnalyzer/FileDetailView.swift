import SwiftUI

struct FileDetailView: View {
  let location: FileLocation
  var reloadAll: ()->Void

  @State private var showingMove = false
  @State private var showingRename = false
  @State private var newName = ""
  @State private var selectedFolder = ""
  @State private var dataPoints: [(time: Double, voltage: Double)] = []

  private var folderURL: URL {
    FileManagerHelper.shared.ecgBaseFolder
      .appendingPathComponent(location.folder)
  }
  private var fileURL: URL {
    folderURL.appendingPathComponent(location.file!)
  }

  var body: some View {
    VStack {
      ECGGraphView(data: dataPoints)
        .frame(height: 200)
        .padding()

      List {
        Button("Move to…") { showingMove = true }
        Button("Rename") { showingRename = true }
      }
    }
    .navigationTitle(location.file ?? "")
    .onAppear(perform: loadAndParse)
    .sheet(isPresented: $showingMove) {
      MoveSheet(currentFolder: location.folder,
                folders: FileManagerHelper.shared.listSubfolders(),
                onMove: moveFile)
    }
    .alert("Rename File", isPresented: $showingRename, actions: {
      TextField("New name (no .csv)", text: $newName)
      Button("OK") { renameFile() }
      Button("Cancel", role: .cancel) {}
    })
  }

  func loadAndParse() {
    do {
      let content = try String(contentsOf: fileURL, encoding: .utf8)
      let lines = content
        .split(separator: "\n")
        .dropFirst()             // skip header
      dataPoints = lines.compactMap { line in
        let parts = line.split(separator: ",")
        guard parts.count==2,
              let t = Double(parts[0]),
              let v = Double(parts[1]) else { return nil }
        return (time: t, voltage: v)
      }
    } catch {
      dataPoints = []
    }
  }

  func moveFile(to destFolder: String) {
    let dstURL = FileManagerHelper.shared.ecgBaseFolder
      .appendingPathComponent(destFolder)
    do {
      try FileManagerHelper.shared.moveCSV(
        named: location.file!,
        from: folderURL,
        to: dstURL
      )
      reloadAll()
    } catch {
      print("Move error", error)
    }
    showingMove = false
  }

  func renameFile() {
    do {
      try FileManagerHelper.shared.renameCSV(
        oldName: location.file!,
        to: newName,
        in: folderURL
      )
      reloadAll()
    } catch {
      print("Rename error", error)
    }
    showingRename = false
  }
}

// Sheet to pick destination folder
struct MoveSheet: View {
  let currentFolder: String
  let folders: [String]
  var onMove: (_ to: String)->Void

  @Environment(\.dismiss) var dismiss
  @State private var selection: String = ""

  var body: some View {
    NavigationView {
      Form {
        Picker("Destination", selection: $selection) {
          ForEach(folders, id:\.self) { f in
            if f != currentFolder {
              Text(f).tag(f)
            }
          }
        }
      }
      .navigationTitle("Move to")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Move") {
            onMove(selection)
            dismiss()
          }
        }
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
    }
  }
}