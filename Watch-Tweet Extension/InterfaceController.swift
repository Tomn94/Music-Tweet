//
//  InterfaceController.swift
//  Watch-Tweet Extension
//
//  Created by Tomn on 24/05/2017.
//  Copyright © 2017 U969H3GXLU. All rights reserved.
//

import WatchKit
import WatchConnectivity

class InterfaceController: WKInterfaceController {
    
    @IBOutlet var nowPlayingLabel: WKInterfaceLabel!
    @IBOutlet var tweetBtn: WKInterfaceButton!
    @IBOutlet var artworkSwitch: WKInterfaceSwitch!
    @IBOutlet var artwork: WKInterfaceImage!
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activate()
            }
        }
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        session = WCSession.default()
        reset()
    }
    
    @IBAction func tweet() {
        
        session?.sendMessage(["action" : "tweet"],
                             replyHandler: nil) { error in
                                
                                self.presentAlert(withTitle: "Unable to tweet current track",
                                                  message: error.localizedDescription,
                                                  preferredStyle: .alert,
                                                  actions: [WKAlertAction(title: "Cancel", style: .cancel) {}])
        }
    }
    
    @IBAction func reset() {
        
        session?.sendMessage(["get" : "info"],
                             replyHandler: { info in
                                
                                let text = info["text"] as? String
                                self.nowPlayingLabel.setText(text)
                                self.artwork.setImage(info["artwork"] as? UIImage)
                                self.tweetBtn.setEnabled(!(text?.isEmpty ?? true))
                                
        }) { error in
            self.presentAlert(withTitle: "Unable to get current track from iPhone",
                              message: error.localizedDescription,
                              preferredStyle: .alert,
                              actions: [WKAlertAction(title: "Cancel", style: .cancel) {}])
        }
    }
    
    @IBAction func artworkActivationChanged(_ value: Bool) {
        
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
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error = error {
            presentAlert(withTitle: "Unable to connect to iPhone",
                         message: error.localizedDescription,
                         preferredStyle: .alert,
                         actions: [WKAlertAction(title: "Cancel", style: .cancel) {}])
        }
    }
    
}
