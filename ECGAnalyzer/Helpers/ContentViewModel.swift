import Foundation

class ContentViewModel: ObservableObject {
    @Published var folders: [String] = []

    private let didExportKey = "hasExportedECG"

    init() {
        // 1) Ensure base folders exist
        FileManagerHelper.shared.createECGBaseFolderIfNeeded()

        // 2) Automatically fetch+export ECGs once
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: didExportKey) {
            HealthKitManager.shared.requestAuthorization { success in
                guard success else {
                    print("HealthKit auth failed")
                    DispatchQueue.main.async { self.refreshFolders() }
                    return
                }
                HealthKitManager.shared.fetchAllECGs { ecgs in
                    for ecg in ecgs {
                        HealthKitManager.shared.exportECGToCSV(ecg: ecg) { ok in
                            if !ok {
                                print("Export failed for \(ecg.startDate)")
                            }
                        }
                    }
                    // mark done and reload UI
                    defaults.set(true, forKey: self.didExportKey)
                    DispatchQueue.main.async {
                        self.refreshFolders()
                    }
                }
            }
        } else {
            // Already exported on a prior launch
            refreshFolders()
        }
    }

    func refreshFolders() {
        let all = FileManagerHelper.shared.listSubfolders()
        // keep Uncategorized for the UI even if it's the only one
        self.folders = all.filter { $0 != "Uncategorized" }
    }
}