//
//  MultipeerManager.swift
//  RaspberryLemonade
//
//  Created by Joey Kerper on 8/19/24.
//

import Foundation
import MultipeerConnectivity
import Combine
import CoreLocation

class MultipeerManager: NSObject, ObservableObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, CLLocationManagerDelegate {
    
    private let serviceType = "bt-rocks"
    
    let peerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser
    private var browser: MCNearbyServiceBrowser
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var peerPositions: [MCPeerID: CGPoint] = [:]
    @Published var peerRockNames: [MCPeerID: String] = [:]  // Store the rock names
    
    private var locationManager: CLLocationManager
    private var currentLocation: CLLocation?
    
    @Published var rockName: String  // Rock name for the local device

    init(rockName: String) {
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.rockName = rockName
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: ["rockName": rockName], serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        self.locationManager = CLLocationManager()
        
        super.init()
        
        self.session.delegate = self
        self.advertiser.delegate = self
        self.browser.delegate = self
        self.locationManager.delegate = self
        
        self.advertiser.startAdvertisingPeer()
        self.browser.startBrowsingForPeers()
        
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    // Update the rock name and notify connected peers
    func updateRockName(_ newName: String) {
        self.rockName = newName
        self.peerRockNames[peerID] = newName
        
        // Stop advertising and start again with the new name
        self.advertiser.stopAdvertisingPeer()
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: ["rockName": newName], serviceType: serviceType)
        self.advertiser.delegate = self
        self.advertiser.startAdvertisingPeer()
        
        // Notify connected peers of the name change
        sendRockNameUpdate(newName)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")  // Log the location data
        currentLocation = location
        sendCurrentPosition()
    }
    
    private func sendCurrentPosition() {
        guard let location = currentLocation else { return }
        
        // Convert CLLocation to a CGPoint for display
        let position = convertLocationToScreenPosition(location)
        
        peerPositions[peerID] = position
        
        if let positionData = try? NSKeyedArchiver.archivedData(withRootObject: position, requiringSecureCoding: false) {
            do {
                try session.send(positionData, toPeers: session.connectedPeers, with: .reliable)
                print("Sent position data: \(position)")
            } catch {
                print("Error sending data: \(error.localizedDescription)")
            }
        }
    }
    
    private func convertLocationToScreenPosition(_ location: CLLocation) -> CGPoint {
        // Normalize latitude and longitude to the range of 0.0 to 1.0
        let normalizedLatitude = (location.coordinate.latitude + 90) / 180
        let normalizedLongitude = (location.coordinate.longitude + 180) / 360
        
        // Scale normalized coordinates to the screen size
        let x = normalizedLongitude * UIScreen.main.bounds.width
        let y = (1 - normalizedLatitude) * UIScreen.main.bounds.height
        
        // Ensure the position stays within the screen bounds
        let constrainedX = min(max(x, 0), UIScreen.main.bounds.width)
        let constrainedY = min(max(y, 0), UIScreen.main.bounds.height)
        
        print("Converted and constrained position: \(constrainedX), \(constrainedY)")
        return CGPoint(x: constrainedX, y: constrainedY)
    }
    
    private func sendRockNameUpdate(_ newName: String) {
        if let nameData = try? NSKeyedArchiver.archivedData(withRootObject: newName, requiringSecureCoding: false) {
            try? session.send(nameData, toPeers: session.connectedPeers, with: .reliable)
        }
    }
    
    // MARK: - MCSessionDelegate
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectedPeers.append(peerID)
                print("Connected: \(peerID.displayName)")
                self.sendRockNameUpdate(self.rockName)  // Send the current rock name to the connected peer
            case .connecting:
                print("Connecting: \(peerID.displayName)")
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                self.peerPositions.removeValue(forKey: peerID)
                print("Not Connected: \(peerID.displayName)")
            @unknown default:
                print("Unknown state for peer: \(peerID.displayName)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let receivedName = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? String {
            DispatchQueue.main.async {
                self.peerRockNames[peerID] = receivedName
            }
        } else if let position = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? CGPoint {
            DispatchQueue.main.async {
                self.peerPositions[peerID] = position
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Received invitation from \(peerID.displayName)")
        invitationHandler(true, session)
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        if let rockName = info?["rockName"] {
            peerRockNames[peerID] = rockName
        }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
}
