import Foundation
import HealthKit

class WorkoutManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    @Published var heartRate: Double?
    @Published var isWorkoutActive: Bool = false
    
    // Armazena histórico temporário
    private(set) var heartRateSamples: [(Date, Double)] = []
    
    override init() {
        super.init()
    }

    func startDivingWorkout() {
        let config = HKWorkoutConfiguration()
        config.activityType = .underwaterDiving
        config.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            
            session?.delegate = self
            builder?.delegate = self
            
            session?.startActivity(with: Date())
            builder?.beginCollection(withStart: Date()) { _, _ in
                DispatchQueue.main.async {
                    self.isWorkoutActive = true
                }
            }
        } catch {
            print("Erro ao iniciar treino: \(error.localizedDescription)")
        }
    }
    
    func stopWorkout() {
        session?.end()
        builder?.endCollection(withEnd: Date()) { _, _ in
            self.builder?.finishWorkout { _, _ in
                DispatchQueue.main.async {
                    self.isWorkoutActive = false
                }
                // Enviar amostras coletadas para iPhone
                ConnectivityManager.shared.sendHeartRateSamples(self.heartRateSamples)
            }
        }
    }
}
