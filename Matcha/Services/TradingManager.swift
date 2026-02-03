// TradingManager.swift
// Matcha

import Foundation
@preconcurrency import MultipeerConnectivity
import SwiftData
import UIKit

// MARK: - Trade Protocol

enum TradingState: Equatable, Sendable {
    case idle
    case searching
    case connected(peerName: String)
    case trading
}

struct StickerInfo: Codable, Equatable, Sendable {
    let id: UUID
    let name: String
    let rarity: String
    let imageName: String
    
    init(from sticker: Sticker) {
        self.id = sticker.id
        self.name = sticker.name
        self.rarity = sticker.rarity.rawValue
        self.imageName = sticker.imageName
    }
}

enum TradeMessage: Codable, Sendable {
    case offer(StickerInfo)
    case confirm
    case complete
    case cancel
}

// MARK: - TradingManager

@Observable
@MainActor
final class TradingManager: NSObject {
    
    private let serviceType = "matcha-trade"
    private nonisolated(unsafe) var peerID: MCPeerID!
    private nonisolated(unsafe) var session: MCSession!
    private nonisolated(unsafe) var advertiser: MCNearbyServiceAdvertiser!
    private nonisolated(unsafe) var browser: MCNearbyServiceBrowser!
    
    // State
    var state: TradingState = .idle
    var discoveredPeers: [MCPeerID] = []
    var connectedPeer: MCPeerID?
    
    // Trade state
    var myOffer: Sticker?
    var theirOffer: StickerInfo?
    var iConfirmed: Bool = false
    var theyConfirmed: Bool = false
    
    // Callbacks
    var onTradeComplete: ((StickerInfo) -> Void)?
    var onError: ((String) -> Void)?
    
    override init() {
        super.init()
        
        let deviceName = UIDevice.current.name
        peerID = MCPeerID(displayName: "Matcha User [\(deviceName)]")
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }
    
    // MARK: - Public API
    
    func startSearching() {
        guard state == .idle else { return }
        state = .searching
        discoveredPeers = []
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    
    func stopSearching() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        resetTradeState()
        state = .idle
    }
    
    func invitePeer(_ peer: MCPeerID) {
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
    }
    
    func selectOffer(_ sticker: Sticker) {
        guard sticker.ownedCount > 1 else {
            onError?("Cannot trade your last copy!")
            return
        }
        myOffer = sticker
        sendMessage(.offer(StickerInfo(from: sticker)))
    }
    
    func confirmTrade() {
        guard myOffer != nil, theirOffer != nil else { return }
        iConfirmed = true
        sendMessage(.confirm)
        checkTradeCompletion()
    }
    
    func cancelTrade() {
        sendMessage(.cancel)
        resetTradeState()
        if connectedPeer != nil {
            state = .connected(peerName: connectedPeer!.displayName)
        } else {
            state = .searching
        }
    }
    
    // MARK: - Private
    
    private func resetTradeState() {
        myOffer = nil
        theirOffer = nil
        iConfirmed = false
        theyConfirmed = false
        connectedPeer = nil
        discoveredPeers = []
    }
    
    private func sendMessage(_ message: TradeMessage) {
        guard let peer = connectedPeer,
              let data = try? JSONEncoder().encode(message) else { return }
        
        try? session.send(data, toPeers: [peer], with: .reliable)
    }
    
    private func handleMessage(_ message: TradeMessage) {
        switch message {
        case .offer(let info):
            theirOffer = info
            if myOffer != nil {
                state = .trading
            }
            
        case .confirm:
            theyConfirmed = true
            checkTradeCompletion()
            
        case .complete:
            // Other side confirms completion
            if let received = theirOffer {
                onTradeComplete?(received)
            }
            resetTradeState()
            state = .idle
            
        case .cancel:
            resetTradeState()
            state = .idle
        }
    }
    
    private func checkTradeCompletion() {
        guard iConfirmed, theyConfirmed else { return }
        
        // Trade is complete
        sendMessage(.complete)
        
        if let received = theirOffer {
            onTradeComplete?(received)
        }
        
        resetTradeState()
        state = .idle
    }
}

// MARK: - MCSessionDelegate

extension TradingManager: MCSessionDelegate {
    
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let peerName = peerID.displayName
        Task { @MainActor in
            switch state {
            case .connected:
                self.connectedPeer = peerID
                self.state = .connected(peerName: peerName)
                self.advertiser.stopAdvertisingPeer()
                self.browser.stopBrowsingForPeers()
                
            case .notConnected:
                if self.connectedPeer?.displayName == peerName {
                    self.resetTradeState()
                    self.state = .idle
                }
                
            case .connecting:
                break
                
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(TradeMessage.self, from: data) else { return }
        Task { @MainActor in
            self.handleMessage(message)
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension TradingManager: MCNearbyServiceAdvertiserDelegate {
    
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept invitations
        let session = self.session
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension TradingManager: MCNearbyServiceBrowserDelegate {
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        Task { @MainActor in
            if !self.discoveredPeers.contains(where: { $0.displayName == peerID.displayName }) {
                self.discoveredPeers.append(peerID)
            }
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        let lostName = peerID.displayName
        Task { @MainActor in
            self.discoveredPeers.removeAll { $0.displayName == lostName }
        }
    }
}
