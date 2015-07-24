//
//  ViewController.swift
//  ttl
//
//  Created by Greg McNutt on 7/3/15.
//  Copyright (c) 2015 Greg McNutt. All rights reserved.
//

import UIKit
import WatchConnectivity
import CoreMotion

class ViewController: UIViewController, WCSessionDelegate {
    let session = WCSession.defaultSession()
    
    @IBOutlet weak var events: UITextView!
    
    var result = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        session.delegate = self
        session.activateSession()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        let data = userInfo["data"] as? String
        let endData = userInfo["end"] as? String
        
        if (data != nil) {
            result += data!
        } else if (endData != nil) {
            result += endData!
            NSOperationQueue.mainQueue().addOperationWithBlock( {
                self.events.text = self.result
                })
            result = ""
        }
    }
}

