//
//  ContentView.swift
//  RaspberryLemonade
//
//  Created by Joey Kerper on 8/19/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var healthManager = HealthManager()
    @StateObject private var petRock: PetRock
    
    init() {
        let healthManager = HealthManager()
        _healthManager = StateObject(wrappedValue: healthManager)
        _petRock = StateObject(wrappedValue: PetRock(healthManager: healthManager))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Meet \(petRock.name)!")
                    .font(.largeTitle)
                    .padding()
                
                Text("Level: \(petRock.level)")
                    .font(.title2)
                    .padding()
                
                Text("Hunger: \(petRock.hunger)")
                    .font(.title2)
                    .padding()
                
                Text("Times Fed: \(petRock.timesFed)")
                    .font(.title2)
                    .padding()
                
                HStack {
                    Button(action: {
                        petRock.feed()
                    }) {
                        Text("Feed \(petRock.name)")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        petRock.levelUp()
                    }) {
                        Text("Level Up")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
                
                NavigationLink(destination: MapView()) {
                    Text("Show Nearby Rocks")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
