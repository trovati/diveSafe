import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let depthType = HKQuantityType.quantityType(forIdentifier: .depth),
              let directionType = HKQuantityType.quantityType(forIdentifier: .directionOfTravel) else {
            return
        }
        
        healthStore.requestAuthorization(
            toShare: [hrType, depthType, directionType],
            read: [hrType, depthType, directionType]
        ) { success, error in
            if let error = error {
                print("⚠️ Erro autorização HealthKit: \(error.localizedDescription)")
            } else {
                print("✅ Autorização concedida")
            }
        }
    }
    
    func saveHeartRate(_ bpm: Double, date: Date) {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let quantity = HKQuantity(unit: .init(from: "count/min"), doubleValue: bpm)
        let sample = HKQuantitySample(type: hrType, quantity: quantity, start: date, end: date)
        healthStore.save(sample) { _,_ in }
    }
    
    func saveDepth(_ depth: Double, date: Date) {
        guard let depthType = HKQuantityType.quantityType(forIdentifier: .depth) else { return }
        let quantity = HKQuantity(unit: .meter(), doubleValue: depth)
        let sample = HKQuantitySample(type: depthType, quantity: quantity, start: date, end: date)
        healthStore.save(sample) { _,_ in }
    }
    
    func saveDirection(_ degrees: Double, date: Date) {
        guard let directionType = HKQuantityType.quantityType(forIdentifier: .directionOfTravel) else { return }
        let quantity = HKQuantity(unit: .degreeAngle(), doubleValue: degrees)
        let sample = HKQuantitySample(type: directionType, quantity: quantity, start: date, end: date)
        healthStore.save(sample) { _,_ in }
    }
}
