//
//  MapView.swift
//  RaspberryLemonade
//
//  Created by Joey Kerper on 8/19/24.
//

import SwiftUI

struct MapView: View {
    @StateObject private var nearbyInteractionManager = NearbyInteractionManager()
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            // Represent the current device's rock at the center
            VStack {
                Text("Your Rock")
                    .foregroundColor(.white)
                    .padding(.bottom, 5)
                Circle()
                    .fill(Color.blue) // Different color for the current device's rock
                    .frame(width: 50, height: 50)
            }
            .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
            
            // Represent the nearby device's rock
            ForEach(nearbyInteractionManager.positions.indices, id: \.self) { index in
                VStack {
                    Text("Rock \(index + 1)")
                        .foregroundColor(.white)
                        .padding(.bottom, 5)
                    Circle()
                        .fill(Color.green)
                        .frame(width: 50, height: 50)
                }
                .position(nearbyInteractionManager.positions[index])
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
