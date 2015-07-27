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
    let wcsession = WCSession.defaultSession()
    var timer = NSTimer()
    var lastBatch : String!
    var lastStart : String!
    var tryCount = 0
    
    @IBOutlet weak var tryVal: UILabel!
    @IBOutlet weak var batchVal: UILabel!
    @IBOutlet weak var minVal: UILabel!
    @IBOutlet weak var maxVal: UILabel!
    @IBOutlet weak var countVal: UILabel!
    @IBOutlet weak var errorVal: UILabel!
    @IBOutlet weak var reachableVal: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        wcsession.delegate = self
        wcsession.activateSession()
        
        // init value of reachability
        sessionReachabilityDidChange(wcsession)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sessionReachabilityDidChange(session: WCSession) {
        if (session.reachable) {
            self.reachableVal.textColor = UIColor.greenColor()
            self.reachableVal.text = "reachable"
        } else {
            self.reachableVal.textColor = UIColor.redColor()
            self.reachableVal.text = "not reachable"
        }
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        
        let command = message["action"] as! String
        switch (command) {
        case "dequeuer":
            
            // the command
            let enabled = message["enabled"] as! Bool
            lastStart = message["lastStart"] as! String
            lastBatch = "0"
            
            // stop timer, should we re-enable?
            timer.invalidate()
            if (enabled) {
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(5.0,
                        target: self,
                        selector: "fetchData:",
                        userInfo: nil,
                        repeats: true)
                })
            }
            
            replyHandler(["enabled" : enabled, "asOf" : lastStart])
            
        default:
            NSLog("invalid command \(command)")
        }
    }
    
    func fetchData(timer : NSTimer) {
        tryCount++
        self.tryVal.text = tryCount.description
        
        if (self.wcsession.reachable) {
            
            // send current position to watch
            self.wcsession.sendMessage(
                [
                    "action" : "getData",
                    "lastBatch" : lastBatch,
                    "lastStart" : lastStart
                ],
                replyHandler: { (result: [String : AnyObject]) -> Void in
                    self.lastBatch = result["lastBatch"] as? String
                    NSOperationQueue.mainQueue().addOperationWithBlock( {
                        self.countVal.text = result["count"] as? String
                        self.batchVal.text = result["lastBatch"] as? String
                        self.minVal.text = result["min"] as? String
                        self.maxVal.text = result["max"] as? String
                        self.errorVal.text = "ok"
                    })
                },
                errorHandler: { (error: NSError) -> Void in
                    NSOperationQueue.mainQueue().addOperationWithBlock( {
                        self.errorVal.text = error.description
                    })
                }
            )
        } else {
            NSOperationQueue.mainQueue().addOperationWithBlock( {
                self.errorVal.text = "skipped"
            })
        }
    }
}

