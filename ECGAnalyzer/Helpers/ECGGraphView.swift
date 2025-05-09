import SwiftUI
import Charts

struct ECGGraphView: View {
    let csvData: [(time: Double, voltage: Double)]

    var body: some View {
        Chart(csvData, id: \.time) { point in
            LineMark(
                x: .value("Time", point.time),
                y: .value("Voltage", point.voltage)
            )
        }
        .chartXAxisLabel("Time (s)")
        .chartYAxisLabel("Voltage (mV)")
        .padding()
    }
}