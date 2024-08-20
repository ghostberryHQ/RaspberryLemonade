//
//  HealthManager.swift
//  RaspberryLemonade
//
//  Created by Joey Kerper on 8/19/24.
//

import HealthKit
import Combine

class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var stepsToday: Int = 0
    
    init() {
        requestAuthorization { [weak self] success in
            if success {
                self?.fetchSteps()
            }
        }
    }
    
    private func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let typesToRead: Set<HKObjectType> = [stepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if !success {
                print("Authorization failed: \(String(describing: error))")
            }
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func fetchSteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch steps: \(String(describing: error))")
                return
            }
            
            DispatchQueue.main.async {
                self.stepsToday = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }
        
        healthStore.execute(query)
    }
}
