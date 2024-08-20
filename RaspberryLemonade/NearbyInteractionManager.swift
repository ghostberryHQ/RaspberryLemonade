//
//  NearbyInteractionManager.swift
//  RaspberryLemonade
//
//  Created by Joey Kerper on 8/19/24.
//

import Foundation
import NearbyInteraction
import MultipeerConnectivity
import Combine
import CoreGraphics

class NearbyInteractionManager: NSObject, ObservableObject, NISessionDelegate, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    private var niSession: NISession?
    private var mcSession: MCSession?
    private var mcPeerID: MCPeerID?
    private var mcAdvertiser: MCNearbyServiceAdvertiser?
    private var mcBrowser: MCNearbyServiceBrowser?
    
    @Published var nearbyRocks: [NINearbyObject] = []
    @Published var positions: [CGPoint] = []
    
    override init() {
        super.init()
        startMultipeerSession()
        startNISession()
    }
    
    // MARK: - Nearby Interaction Setup
    private func startNISession() {
        niSession = NISession()
        niSession?.delegate = self
        print("NISession started")
    }
    
    // MARK: - Multipeer Connectivity Setup
    private func startMultipeerSession() {
        mcPeerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: mcPeerID!, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
        print("MCSession started with peerID: \(mcPeerID!.displayName)")
        
        mcAdvertiser = MCNearbyServiceAdvertiser(peer: mcPeerID!, discoveryInfo: nil, serviceType: "pet-rocks")
        mcAdvertiser?.delegate = self
        mcAdvertiser?.startAdvertisingPeer()
        print("Started advertising peer")
        
        mcBrowser = MCNearbyServiceBrowser(peer: mcPeerID!, serviceType: "pet-rocks")
        mcBrowser?.delegate = self
        mcBrowser?.startBrowsingForPeers()
        print("Started browsing for peers")
    }
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Received invitation from peer: \(peerID.displayName)")
        invitationHandler(true, mcSession)
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        mcBrowser?.invitePeer(peerID, to: mcSession!, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
    
    // MARK: - MCSessionDelegate
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected to peer: \(peerID.displayName)")
            sendDiscoveryToken(to: peerID)
        case .connecting:
            print("Connecting to peer: \(peerID.displayName)")
        case .notConnected:
            print("Disconnected from peer: \(peerID.displayName)")
        @unknown default:
            print("Unknown state for peer: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("Received data from peer: \(peerID.displayName)")
        if let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) {
            let config = NINearbyPeerConfiguration(peerToken: token)
            niSession?.run(config)
            print("Running NISession with received token")
        } else {
            print("Failed to unarchive discovery token from data")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    // MARK: - NISessionDelegate
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        print("NISession updated with nearby objects")
        DispatchQueue.main.async {
            self.nearbyRocks = nearbyObjects
            self.updatePositions()
        }
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        print("NISession invalidated with error: \(error.localizedDescription)")
    }
    
    func sessionWasSuspended(_ session: NISession) {
        print("NISession was suspended")
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        print("NISession suspension ended, restarting session")
        startNISession() // Restart session after suspension
    }
    
    // MARK: - Helper Methods
    private func sendDiscoveryToken(to peerID: MCPeerID) {
        guard let token = niSession?.discoveryToken else {
            print("Failed to retrieve discovery token")
            return
        }
        if let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
            do {
                try mcSession?.send(tokenData, toPeers: [peerID], with: .reliable)
                print("Sent discovery token to peer: \(peerID.displayName)")
            } catch {
                print("Failed to send discovery token: \(error.localizedDescription)")
            }
        } else {
            print("Failed to archive discovery token")
        }
    }
    
    private func updatePositions() {
        positions = nearbyRocks.compactMap { nearbyObject in
            guard let distance = nearbyObject.distance, let direction = nearbyObject.direction else {
                print("Missing distance or direction in nearby object")
                return nil
            }
            
            let x = CGFloat(direction.x) * CGFloat(distance) * 200 // Scale factor for x-axis
            let y = CGFloat(direction.y) * CGFloat(distance) * 200 // Scale factor for y-axis
            return CGPoint(x: x + UIScreen.main.bounds.midX, y: y + UIScreen.main.bounds.midY)
        }
        print("Updated positions: \(positions)")
    }
}
