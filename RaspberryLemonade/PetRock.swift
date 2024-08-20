//
//  PetRock.swift
//  RaspberryLemonade
//
//  Created by Joey Kerper on 8/19/24.
//

import Foundation
import Combine

class PetRock: ObservableObject {
    @Published var name: String
    @Published var level: Int
    @Published var hunger: Int
    @Published var timesFed: Int
    
    private var cancellables = Set<AnyCancellable>()
    
    private let lastStepCountKey = "lastStepCountKey"
    private let nameKey = "nameKey"
    private let levelKey = "levelKey"
    private let hungerKey = "hungerKey"
    private let timesFedKey = "timesFedKey"
    
    init(name: String = "Rocky", level: Int = 1, hunger: Int = 0, timesFed: Int = 0, healthManager: HealthManager) {
        self.name = UserDefaults.standard.string(forKey: nameKey) ?? name
        self.level = UserDefaults.standard.integer(forKey: levelKey)
        self.hunger = UserDefaults.standard.integer(forKey: hungerKey)
        self.timesFed = UserDefaults.standard.integer(forKey: timesFedKey)
        
        // Subscribe to step updates
        healthManager.$stepsToday
            .sink { [weak self] steps in
                self?.updateHunger(steps: steps)
            }
            .store(in: &cancellables)
    }
    
    func feed() {
        if hunger > 0 {
            hunger -= 1
            timesFed += 1
            saveStats()
        } else {
            print("\(name) is not hungry!")
        }
    }
    
    func levelUp() {
        level += 1
        saveStats()
    }
    
    private func updateHunger(steps: Int) {
        let lastStepCount = UserDefaults.standard.integer(forKey: lastStepCountKey)
        if steps > lastStepCount {
            let newHungerPoints = (steps - lastStepCount) / 1000 // Example: 1 hunger point per 1000 steps
            hunger += newHungerPoints
            UserDefaults.standard.set(steps, forKey: lastStepCountKey)
            saveStats()
        }
    }
    
    private func saveStats() {
        UserDefaults.standard.set(name, forKey: nameKey)
        UserDefaults.standard.set(level, forKey: levelKey)
        UserDefaults.standard.set(hunger, forKey: hungerKey)
        UserDefaults.standard.set(timesFed, forKey: timesFedKey)
    }
}
