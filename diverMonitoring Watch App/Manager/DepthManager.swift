import Foundation
import HealthKit

class DepthManager: ObservableObject {
    @Published var depth: Double = 0.0
    private let healthStore = HKHealthStore()
    private var query: HKAnchoredObjectQuery?
    
    init() {
        startDepthQuery()
    }
    
    private func startDepthQuery() {
        guard let depthType = HKQuantityType.quantityType(forIdentifier: .depth) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        query = HKAnchoredObjectQuery(type: depthType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { _,_,_,_,_ in }
        
        query?.updateHandler = { [weak self] _, samples, _, _, _ in
            guard let self = self,
                  let samples = samples as? [HKQuantitySample],
                  let last = samples.last else { return }
            
            let value = last.quantity.doubleValue(for: .meter())
            DispatchQueue.main.async { self.depth = value }
        }
        
        if let q = query {
            healthStore.execute(q)
        }
    }
}
