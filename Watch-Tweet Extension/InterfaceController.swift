//
//  InterfaceController.swift
//  Watch-Tweet Extension
//
//  Created by Tomn on 24/05/2017.
//  Copyright © 2017 U969H3GXLU. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    
    @IBOutlet var nowPlayingLabel: WKInterfaceLabel!
    @IBOutlet var artwork: WKInterfaceImage!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        reset()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func tweet() {
    }
    
    @IBAction func reset() {
    }
    
    @IBAction func artworkActivationChanged(_ value: Bool) {
    }
    
}
