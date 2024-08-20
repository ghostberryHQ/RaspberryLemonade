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
    
    @State private var showingRenameAlert = false
    @State private var newRockName = ""
    
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
                    .onTapGesture {
                        newRockName = petRock.name  // Prepopulate with the current name
                        showingRenameAlert = true
                    }
                    .alert("Rename Your Rock", isPresented: $showingRenameAlert) {
                        TextField("Rock Name", text: $newRockName)
                        Button("Save") {
                            petRock.name = newRockName
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Enter a new name for your rock.")
                    }
                
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
                
                NavigationLink(destination: MultipeerView()) {
                    Text("Show Nearby Rocks")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
