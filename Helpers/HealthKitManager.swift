//
//  HealthKitManager.swift
//  ECGAnalyzer
//
//  Created by Ali Kaan Karagözgil on 8.05.2025.
//
//
//  HealthKitManager.swift
//  ECGAnalyzer
//
//  Created by Ali Kaan Karagözgil on 8.05.2025.
//

import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        print("Starting HealthKit request")
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available")
            completion(false)
            return
        }

        let ecgType = HKObjectType.electrocardiogramType()
        let heightType = HKObjectType.quantityType(forIdentifier: .height)!
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        let sexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex)!

        let typesToRead: Set<HKObjectType> = [ecgType, heightType, weightType, sexType]

        print("Requesting HealthKit permissions for:")
        print("- ECG (\(ecgType))")
        print("- Height (\(heightType))")
        print("- Weight (\(weightType))")
        print("- Biological Sex (\(sexType))")

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            print("HealthKit callback: success=\(success), error=\(String(describing: error))")
            if success {
                print("Authorized to read: ECG, Height, Weight, Biological Sex")
            }
            completion(success)
        }
    }
    
    func fetchAllECGs(completion: @escaping ([HKElectrocardiogram]) -> Void) {
        let ecgType = HKObjectType.electrocardiogramType()
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: ecgType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, results, error in
            guard let ecgs = results as? [HKElectrocardiogram], error == nil else {
                print("Failed to fetch ECGs: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            print("ECGs fetched: \(ecgs.count)")
            completion(ecgs)
        }

        HKHealthStore().execute(query)
    }
    // Converts an ECG object to a CSV string and saves it
    func exportECGToCSV(ecg: HKElectrocardiogram, completion: @escaping (Bool) -> Void) {
        let healthStore = HKHealthStore()
        let voltageUnit = HKUnit.voltUnit(with: .milli)
        let samplingFrequency = ecg.samplingFrequency?.doubleValue(for: .hertz()) ?? 512.0
        let timeIncrement = 1.0 / samplingFrequency
        var time: Double = 0.00000
        var csv = "Time;Voltage\nsec;mV\n"

        let query = HKElectrocardiogramQuery(electrocardiogram: ecg) { _, measurement, done, error in
            if let error = error {
                print("ECG measurement error: \(error.localizedDescription)")
                completion(false)
                return
            }

            if let measurement = measurement,
               let quantity = measurement.quantity(for: .appleWatchSimilarToLeadI) {
                let voltage = quantity.doubleValue(for: voltageUnit)
                csv += String(format: "%.4f;%.5f\n", time, voltage)
                time += timeIncrement
            }

            if done {
                let success = FileManagerHelper.shared.saveECGCSV(csv, for: ecg.startDate)
                completion(success)
            }
        }

        healthStore.execute(query)
    }

    func getUserInfo(completion: @escaping (_ height: Double?, _ weight: Double?, _ sex: String?) -> Void) {
        var height: Double?
        var weight: Double?
        var sex: String?

        if let biologicalSex = try? healthStore.biologicalSex().biologicalSex {
            switch biologicalSex {
            case .male: sex = "Male"
            case .female: sex = "Female"
            default: sex = "Other"
            }
        }

        let group = DispatchGroup()

        if let heightType = HKQuantityType.quantityType(forIdentifier: .height) {
            group.enter()
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, results, _ in
                if let sample = results?.first as? HKQuantitySample {
                    height = sample.quantity.doubleValue(for: .meter())
                }
                group.leave()
            }
            healthStore.execute(query)
        }

        if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            group.enter()
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, results, _ in
                if let sample = results?.first as? HKQuantitySample {
                    weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                }
                group.leave()
            }
            healthStore.execute(query)
        }

        group.notify(queue: .main) {
            completion(height, weight, sex)
        }
    }
}
