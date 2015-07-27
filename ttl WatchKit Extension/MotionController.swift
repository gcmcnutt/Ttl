//
//  MotionController.swift
//  ttl
//
//  Created by Greg McNutt on 7/15/15.
//  Copyright © 2015 Greg McNutt. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion
import Darwin
import WatchConnectivity

extension CMSensorDataList: SequenceType {
    public func generate() -> NSFastGenerator {
        return NSFastGenerator(self)
    }
}

class MotionController: WKInterfaceController, WCSessionDelegate {
    
    let sr = CMSensorRecorder()
    var durationValue = 2.0
    var lastStart = NSDate()
    let dateFormatter = NSDateFormatter()
    let wcsession = WCSession.defaultSession()
    var cmdCount = 0
    
    @IBOutlet var durationRef: WKInterfaceSlider!
    @IBOutlet var duration: WKInterfaceLabel!
    @IBOutlet var start: WKInterfaceButton!
    @IBOutlet var lastStartTime: WKInterfaceLabel!
    @IBOutlet var reachableVal: WKInterfaceLabel!
    @IBOutlet var dequeueResult: WKInterfaceLabel!
    @IBOutlet var cmdCountVal: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        dateFormatter.dateFormat = "yyyy-MM-dd'T'hh:mm:ss"
        
        // can we record?
        self.start.setEnabled(CMSensorRecorder.isAccelerometerRecordingAvailable())
        self.lastStartTime.setText(dateFormatter.stringFromDate(lastStart))
        
        // wake up session to phone
        wcsession.delegate = self
        wcsession.activateSession()
        
        // init is-phone-reachable?
        sessionReachabilityDidChange(wcsession)
    }
    
    func sessionReachabilityDidChange(session: WCSession) {
        if (session.reachable) {
            self.reachableVal.setTextColor(UIColor.greenColor())
            self.reachableVal.setText("reachable")
        } else {
            self.reachableVal.setTextColor(UIColor.redColor())
            self.reachableVal.setText("not reachable")
        }
    }
    
    @IBAction func durationChanged(value: Float) {
        durationValue = Double(value)
        self.duration.setText(value.description)
    }
    
    @IBAction func startRecorder() {
        lastStart = NSDate()
        self.lastStartTime.setText(dateFormatter.stringFromDate(lastStart))
        self.sr.recordAccelerometerFor(durationValue * 60.0)
    }
    
    // watch controlled activation of the dequeuer process
    @IBAction func dequeuer(value: Bool) {
        if (self.wcsession.reachable) {
            self.dequeueResult.setText("sending...")
            self.wcsession.sendMessage(
                [
                    "action": "dequeuer",
                    "enabled" : value,
                    "lastStart": lastStart.timeIntervalSince1970.description
                ],
                replyHandler: { (result: [String : AnyObject]) -> Void in
                    self.dequeueResult.setTextColor(UIColor.greenColor())
                    self.dequeueResult.setText(result.description)
                },
                errorHandler: { (error: NSError) -> Void in
                    self.dequeueResult.setTextColor(UIColor.redColor())
                    self.dequeueResult.setText(error.description)
                }
            )
        } else {
            self.dequeueResult.setText("not reachable...")
        }
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        
        let command = message["action"] as! String
        self.cmdCountVal.setText((++cmdCount).description)
        switch (command) {
            
            // a message to get new data from watch
        case "getData":
            let lastBatch = UInt64(message["lastBatch"] as! String)
            let lastStart = Double(message["lastStart"] as! String)
            
            // first or subsequent batch?
            let data : CMSensorDataList!
            if (lastBatch == 0) {
                data = sr.accelerometerDataFrom(NSDate(timeIntervalSince1970: lastStart!), to: NSDate())
            } else {
                data = sr.accelerometerDataSince(lastBatch!)
            }
            
            // count and hunt to the last item
            var count = 0
            var minDate = NSDate.distantFuture()
            var maxDate = NSDate.distantPast()
            var currentBatch : UInt64 = 0
            if (data != nil) {
                
                for element in data as CMSensorDataList {
                    
                    let lastElement = element as! CMRecordedAccelerometerData
                    
                    // we only do one batch at a time
                    if (currentBatch == 0) {
                        currentBatch = lastElement.identifier
                    }
                    if (currentBatch != lastElement.identifier) {
                        currentBatch = lastElement.identifier
                        break
                    }
                    
                    // next item, measure it
                    count++;
                    if (lastElement.startDate.compare(NSDate.distantPast()) == NSComparisonResult.OrderedAscending) {
                        NSLog("odd date: " + lastElement.description)
                    }
                    minDate = minDate.earlierDate(lastElement.startDate)
                    maxDate = maxDate.laterDate(lastElement.startDate)
                }
            }
            replyHandler(
                [
                    "count" : count.description,
                    "lastBatch": currentBatch.description,
                    "min" : dateFormatter.stringFromDate(minDate),
                    "max" : dateFormatter.stringFromDate(maxDate)
                ])
            
        default:
            NSLog("invalid command \(command)")
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}
