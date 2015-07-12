//
//  InterfaceController.swift
//  ttl WatchKit Extension
//
//  Created by Greg McNutt on 7/3/15.
//  Copyright (c) 2015 Greg McNutt. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion

class InterfaceController: WKInterfaceController {

    var arrivalDate: NSDate!
    let mm = CMMotionManager()
    var timer = NSTimer()
    
    @IBOutlet weak var days: WKInterfaceLabel!
    @IBOutlet weak var hours: WKInterfaceLabel!
    @IBOutlet weak var minutes: WKInterfaceLabel!
    @IBOutlet weak var seconds: WKInterfaceLabel!
    @IBOutlet var x: WKInterfaceLabel!
    @IBOutlet var y: WKInterfaceLabel!
    @IBOutlet var z: WKInterfaceLabel!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        let format = NSDateFormatter()
        format.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        arrivalDate = format.dateFromString("2015-07-29T16:21:00-0700")

        // Configure interface objects here.
    }
   
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let interval:NSTimeInterval = 1.0
        timer.invalidate()
        timer = NSTimer.scheduledTimerWithTimeInterval(interval,
            target: self,
            selector: "showTTL:",
            userInfo: nil,
            repeats: true)
        showTTL(timer)
        
        if (mm.accelerometerAvailable) {
            mm.accelerometerUpdateInterval = 0.5
            self.mm.startAccelerometerUpdatesToQueue(NSOperationQueue()) {
                (data, error) in
                self.x.setText(NSString(format: "%.2f", data!.acceleration.x) as String)
                self.y.setText(NSString(format: "%.2f", data!.acceleration.y) as String)
                self.z.setText(NSString(format: "%.2f", data!.acceleration.z) as String)
            }
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        timer.invalidate()
    }
    
    func showTTL(timer:NSTimer) {
        let now = NSDate()
        let dayHourMinuteSecond: NSCalendarUnit = [ .Day, .Hour, .Minute, .Second ]
        
        let difference = NSCalendar.currentCalendar().components(
            dayHourMinuteSecond,
            fromDate: now,
            toDate: arrivalDate,
            options: [])
        
        self.days.setText(difference.day.description)
        self.hours.setText(difference.hour.description)
        self.minutes.setText(difference.minute.description)
        self.seconds.setText(difference.second.description)
        
    }
}
