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

extension CMSensorDataList: SequenceType {
    public func generate() -> NSFastGenerator {
        return NSFastGenerator(self)
    }
}

class MotionController: WKInterfaceController {

    let sr = CMSensorRecorder()
    var durationValue = 2.0
    var lastStart = NSDate()
    let dateFormatter = NSDateFormatter()
    
    @IBOutlet var durationRef: WKInterfaceSlider!
    @IBOutlet var duration: WKInterfaceLabel!
    @IBOutlet var start: WKInterfaceButton!
    @IBOutlet var lastStartTime: WKInterfaceLabel!
    @IBOutlet var x: WKInterfaceLabel!
    @IBOutlet var y: WKInterfaceLabel!
    @IBOutlet var z: WKInterfaceLabel!
    @IBOutlet var events: WKInterfaceLabel!
    @IBOutlet var identifier: WKInterfaceLabel!
    @IBOutlet var min: WKInterfaceLabel!
    @IBOutlet var max: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        dateFormatter.dateFormat = "yyyy-MM-dd'T'hh:mm:ss"

        // Configure interface objects here.
        self.start.setEnabled(CMSensorRecorder.isAccelerometerRecordingAvailable())
        self.lastStartTime.setText(dateFormatter.stringFromDate(lastStart))
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
    
    @IBAction func processRecorded() {
        // TODO throw this to a background thread...

        self.events.setTextColor(UIColor.redColor())
        
        let data = sr.accelerometerDataFrom(lastStart, to: NSDate())
        
        self.events.setTextColor(UIColor.yellowColor())
        
        if (data != nil) {
            // count and hunt to the last item
            var count = 0
            var lastElement: CMRecordedAccelerometerData?
            var minDate = NSDate.distantFuture()
            var maxDate = NSDate.distantPast()
            
            for element in data as CMSensorDataList {
                count++;
                lastElement = element as? CMRecordedAccelerometerData
                minDate = minDate.earlierDate(lastElement!.startDate)
                maxDate = maxDate.laterDate(lastElement!.startDate)
            }
            
            // update display
            self.events.setText(count.description)
            
            if (lastElement != nil) {
                self.identifier.setText(lastElement!.identifier.description)
                
                let acc = lastElement!.acceleration
                self.x.setText(NSString(format: "%.2f", acc.x) as String)
                self.y.setText(NSString(format: "%.2f", acc.y) as String)
                self.z.setText(NSString(format: "%.2f", acc.z) as String)
                

                self.min.setText(dateFormatter.stringFromDate(minDate))
                self.max.setText(dateFormatter.stringFromDate(maxDate))
            }
            self.events.setTextColor(UIColor.greenColor())
        } else {
            self.events.setText("nil")
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
