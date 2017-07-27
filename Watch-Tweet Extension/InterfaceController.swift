//
//  InterfaceController.swift
//  Watch-Tweet Extension
//
//  Created by Tomn on 24/05/2017.
//  Copyright © 2017 U969H3GXLU. All rights reserved.
//

import WatchKit
import WatchConnectivity

/// Main view controller, displaying music data
class InterfaceController: WKInterfaceController {
    
    /// Label with the current text to tweet
    @IBOutlet var nowPlayingLabel: WKInterfaceLabel!
    /// Image view displaying the artwork of the track to tweet
    @IBOutlet var artwork: WKInterfaceImage!
    
    /// Tweet button
    @IBOutlet var tweetBtn: WKInterfaceButton!
    /// Artwork (de)activation button
    @IBOutlet var artworkSwitch: WKInterfaceSwitch!
    
    /// Connectivity session with iPhone
    var session: WCSession?
    
    
    /// Called just before appearing, begin updating content
    override func willActivate() {
        super.willActivate()
        
        /* Start connectivity with iPhone */
        session = WCSession.default()
        session?.delegate = self
        session?.activate()
        
        /* Broadcast Handoff */
        updateUserActivity("com.tomn.Music-Tweet.tweet", userInfo: nil, webpageURL: nil)
    }
    
    /// Tweet text and eventually artwork when the corresponding button is pressed
    @IBAction func tweet() {
        
        /* Ask iPhone to tweet */
        session?.sendMessage(["action" : "tweet"],
                             replyHandler: nil) { error in
            
            self.presentAlert(withTitle: "Unable to tweet current track",
                              message: error.localizedDescription,
                              preferredStyle: .alert,
                              actions: [WKAlertAction(title: "Cancel", style: .cancel) {}])
        }
        
        /* Disallow double-posting */
        tweetBtn.setEnabled(false)
        Timer.scheduledTimer(withTimeInterval: 4,
                             repeats: false,
                             block: { _ in
            self.tweetBtn.setEnabled(true)
        })
    }
    
    /// Called when Reset menu item is (firmly) pressed.
    /// Set text to template using track & artist, update artwork preview, and artwork setting
    @IBAction func reset() {
        
        /* Ask iPhone to reset text & artwork to current song */
        session?.sendMessage(["action" : "reset"],
                             replyHandler: nil) { error in
                                
            self.presentAlert(withTitle: "Unable to update text & artwork to currently playing track",
                              message: error.localizedDescription,
                              preferredStyle: .alert,
                              actions: [WKAlertAction(title: "Cancel", style: .cancel) {}])
        }
        
    }
    
    /// Ask data from iPhone to refresh UI
    @IBAction func load() {
        
        session?.sendMessage(["get" : "info"],
                             replyHandler: nil) { error in
            
            self.tweetBtn.setEnabled(false)
            
            self.presentAlert(withTitle: "Unable to get current track from iPhone",
                              message: error.localizedDescription,
                              preferredStyle: .alert,
                              actions: [WKAlertAction(title: "Cancel", style: .cancel) {}])
        }
    }
    
    /// Called when Artwork switch changed
    ///
    /// - Parameter value: New value for the switch,
    ///                    true if tweet should contain artwork
    @IBAction func artworkActivationChanged(_ value: Bool) {
        
        /* Ask iPhone to change settings too, and to store it */
        session?.sendMessage(["setArworkOn" : value],
                             replyHandler: nil) { error in
            
            self.presentAlert(withTitle: "Unable to update artwork setting",
                              message: error.localizedDescription,
                              preferredStyle: .alert,
                              actions: [WKAlertAction(title: "Cancel", style: .cancel) {
                                self.artworkSwitch.setOn(!value)
                                }])
        }
    }
    
}


extension InterfaceController: WCSessionDelegate {
    
    /// Called when conenctivity session completed
    ///
    /// - Parameters:
    ///   - session: Connectivity session with iPhone
    ///   - activationState: Current state of the session
    ///   - error: Eventual error when activating
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        
        if let error = error {
            presentAlert(withTitle: "Unable to connect to iPhone",
                         message: error.localizedDescription,
                         preferredStyle: .alert,
                         actions: [WKAlertAction(title: "Cancel", style: .cancel) {}])
            return
        }
        
        /* Init UI with data */
        load()
    }
    
    /// Called when Apple Watch receives a message from connectivity with iPhone
    ///
    /// - Parameters:
    ///   - session: Connectivity session with iPhone
    ///   - message: Dictionary containing data of the message
    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any]) {
        
        /* If we received Info update */
        if let info = message["info"] as? [String: Any] {
            
            /* Tweet text */
            if let text = info["text"] as? String {
                nowPlayingLabel.setText(text.isEmpty ? "No song is currently playing or paused"
                                                     : text.trimmingCharacters(in: .whitespacesAndNewlines))
                tweetBtn.setEnabled(!text.isEmpty)
            }
            
            /* Artwork settings */
            if let artworkMode = info["artworkMode"] as? Bool {
                artworkSwitch.setOn(artworkMode)
            }
            
            /* Artwork image */
            if let artworkData = info["artworkData"] as? Data {
                artwork.setImage(UIImage(data: artworkData))
                artworkSwitch.setEnabled(true)
            } else {
                artwork.setImage(nil)
                artworkSwitch.setEnabled(false)
                artworkSwitch.setOn(false)
            }
            
        }
        
        /* If we received Tweet success */
        if let success = message["tweeted"] as? Bool,
           success == true {
            WKInterfaceDevice.current().play(.success)
        }
        
        /* If we received Artwork settings */
        if let artworkMode = message["setArworkOn"] as? Bool {
            artworkSwitch.setOn(artworkMode)
        }
        
        /* If we received Error */
        if let alert   = message["alert"] as? [String: String],
           let title   = alert["title"],
           let content = alert["message"] {
            
            WKInterfaceDevice.current().play(.failure)
            
            presentAlert(withTitle: title,
                         message: content,
                         preferredStyle: .alert,
                         actions: [WKAlertAction(title: "OK", style: .cancel) {}])
        }
    }
    
}
