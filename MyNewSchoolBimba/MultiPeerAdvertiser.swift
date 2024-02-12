//
//  MultiPeerGuest.swift
//  MyNewSchoolBimba
//
//  Created by Giacomo on 05/02/24.
//

import Foundation
import MultipeerConnectivity

class MultiPeerAdvertiser: NSObject, ObservableObject {
    private let serviceType = "mns-service"
    private var myPeerID: MCPeerID
    
    public let serviceAdvertiser: MCNearbyServiceAdvertiser
    //public let serviceBrowser: MCNearbyServiceBrowser
    public let session: MCSession
    
    @Published var paired: Bool = false
    @Published var receivedPoints = 0
    @Published var recvdInvite: Bool = false
    @Published var recvdInviteFrom: MCPeerID? = nil
    @Published var invitationHandler: ((Bool, MCSession?) -> Void)?
    
    override init() {
        myPeerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        
        super.init()
        
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceAdvertiser.startAdvertisingPeer()
        print("😀 start advertising")
    }
    
    deinit {
        serviceAdvertiser.stopAdvertisingPeer()
    }
    
    func sendData(data: String) {
        if !session.connectedPeers.isEmpty {
            print("😀 sto mandando \"\(data)\" a \(self.session.connectedPeers[0].displayName)")
            do {
                try session.send(data.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            } catch {
                print("🤬 errore durante l'invio: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: Session Methods

extension MultiPeerAdvertiser: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .notConnected:
            print("😀 non connesso: \(peerID.displayName)")
            DispatchQueue.main.async {
                self.paired = false
            }
        case .connecting:
            print("😀 in connessione: \(peerID.displayName)")
        case .connected:
            print("😀 connesso: \(peerID.displayName)")
            DispatchQueue.main.async {
                self.paired = true
            }
        @unknown default:
            fatalError()
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let string = String(data: data, encoding: .utf8), let points = Int(string) {
            print("😀 ricevuti \(points) punti!")
            // abbiamo ricevuto dei punti, diciamolo alla View
            DispatchQueue.main.async {
                self.receivedPoints += points
            }
        } else {
            print("🤬 errore durante la ricezione dei punti.")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("🤬 errore la ricezione di streams non è supportata!")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("🤬 errore la ricezione di resources non è supportata!")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("🤬 errore la ricezione di resources non è supportata!")
    }
    
    public func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}

// MARK: Advertiser Methods

extension MultiPeerAdvertiser: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("😀 ricevuto invito da \(peerID.displayName)")
        DispatchQueue.main.async {
            // Tell PairView to show the invitation alert
            self.recvdInvite = true
            // Give PairView the peerID of the peer who invited us
            self.recvdInviteFrom = peerID
            // Give PairView the `invitationHandler` so it can accept/deny the invitation
            self.invitationHandler = invitationHandler
        }
    }
}
