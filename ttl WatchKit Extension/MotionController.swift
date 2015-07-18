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

class MotionController: WKInterfaceController {
    
    let mm = CMMotionManager()
    var timer = NSTimer()
    
    @IBOutlet var accelOn: WKInterfaceSwitch!
    @IBOutlet var x: WKInterfaceLabel!
    @IBOutlet var y: WKInterfaceLabel!
    @IBOutlet var z: WKInterfaceLabel!
    @IBOutlet var rate: WKInterfaceLabel!
    @IBOutlet var totalSamples: WKInterfaceLabel!

    var xVal = 0.0, yVal = 0.0, zVal = 0.0
    var count : UInt64 = 0
    var lastCount: UInt64 = 0
    var lastUpdate: UInt64 = 0
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        self.accelOn.setEnabled(mm.accelerometerAvailable)
    }
    
    // the accelOn switch is pressed
    @IBAction func accelOnUpdate(value: Bool) {
        if (value) {
            self.x.setTextColor(UIColor.yellowColor())
            self.y.setTextColor(UIColor.yellowColor())
            self.z.setTextColor(UIColor.yellowColor())
            self.rate.setTextColor(UIColor.greenColor())
            mm.accelerometerUpdateInterval = 0.0
            self.mm.startAccelerometerUpdatesToQueue(NSOperationQueue()) {
                (data, error) in
                self.xVal = data!.acceleration.x
                self.yVal = data!.acceleration.y
                self.zVal = data!.acceleration.z
                self.count++
            }
        } else {
            self.x.setTextColor(UIColor.blueColor())
            self.y.setTextColor(UIColor.blueColor())
            self.z.setTextColor(UIColor.blueColor())
            self.rate.setTextColor(UIColor.blueColor())
            self.mm.stopAccelerometerUpdates()
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        timer.invalidate()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5,
            target: self,
            selector: "updateAccel:",
            userInfo: nil,
            repeats: true)
        lastUpdate = mach_absolute_time()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        timer.invalidate()
    }

    func updateAccel(timer: NSTimer) {
        self.x.setText(NSString(format: "%.2f", xVal) as String)
        self.y.setText(NSString(format: "%.2f", yVal) as String)
        self.z.setText(NSString(format: "%.2f", zVal) as String)
        
        // compute rate
        var info : mach_timebase_info = mach_timebase_info(numer: 0, denom: 0)
        mach_timebase_info(&info)
        
        let now = mach_absolute_time()
        let rate = (Double(count - lastCount) * 1e9) / (Double(now - lastUpdate) * Double(info.numer) / Double(info.denom))
        self.rate.setText(NSString(format: "%.2f", rate) as String)
        lastCount = count
        lastUpdate = now
        
        self.totalSamples.setText(count.description)
    }
}
