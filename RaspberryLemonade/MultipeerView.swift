//
//  MultipeerView.swift
//  RaspberryLemonade
//
//  Created by Joey Kerper on 8/19/24.
//

import SwiftUI

struct MultipeerView: View {
    @StateObject private var multipeerManager = MultipeerManager(rockName: "Rocky")  // Example rock name
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            // Convert keys to an array and sort them
            let sortedPeers = multipeerManager.peerPositions.keys.sorted(by: { $0.displayName < $1.displayName })
            
            ForEach(sortedPeers, id: \.self) { peerID in
                if let position = multipeerManager.peerPositions[peerID],
                   let rockName = multipeerManager.peerRockNames[peerID] {  // Use rock name
                    VStack {
                        Text(rockName)  // Display the rock name
                            .foregroundColor(.white)
                            .padding(.bottom, 5)
                        Circle()
                            .fill(peerID == multipeerManager.peerID ? Color.blue : Color.green)
                            .frame(width: 50, height: 50)
                    }
                    .position(position)
                }
            }
        }
    }
}

struct MultipeerView_Previews: PreviewProvider {
    static var previews: some View {
        MultipeerView()
    }
}
