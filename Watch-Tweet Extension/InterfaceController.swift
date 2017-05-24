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
    @IBOutlet var tweetBtn: WKInterfaceButton!
    @IBOutlet var artwork: WKInterfaceImage!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        reset()
    }

    @IBAction func tweet() {
    }
    
    @IBAction func reset() {
    }
    
    @IBAction func artworkActivationChanged(_ value: Bool) {
    }
    
}
