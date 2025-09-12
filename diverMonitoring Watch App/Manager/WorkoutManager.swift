import Foundation
import HealthKit

class WorkoutManager: NSObject, ObservableObject {
    private var healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    @Published var heartRate: Double = 0.0
    private var collectedSamples: [(Date, Double)] = []
    
    func startWorkout() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = workoutSession?.associatedWorkoutBuilder()
            
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                          workoutConfiguration: config)
            
            workoutSession?.delegate = self
            builder?.delegate = self
            
            workoutSession?.startActivity(with: Date())
            builder?.beginCollection(withStart: Date()) { _, _ in }
        } catch {
            print("Erro ao iniciar workout: \(error)")
        }
    }
    
    func stopWorkout() {
        workoutSession?.end()
    }
    
    private func handleHeartRate(_ value: Double) {
        DispatchQueue.main.async {
            self.heartRate = value
            self.collectedSamples.append((Date(), value))
        }
    }
    
    /// Envia amostras acumuladas
    func flushSamples() {
        ConnectivityManager.shared.sendHeartRateSamples(collectedSamples)
        collectedSamples.removeAll()
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {}
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Erro na sessão: \(error.localizedDescription)")
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf types: Set<HKSampleType>) {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        if types.contains(hrType),
           let statistics = workoutBuilder.statistics(for: hrType) {
            let bpm = statistics.mostRecentQuantity()?.doubleValue(for: .init(from: "count/min")) ?? 0
            handleHeartRate(bpm)
        }
    }
}
