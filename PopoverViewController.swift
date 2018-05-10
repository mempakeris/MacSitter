//
//  ViewController.swift
//  MacSitter
//
//  Created by Matas Empakeris on 12/22/17.
//  Copyright © 2017 Matas Empakeris. All rights reserved.
//

import Cocoa
import OGCircularBar

class PopoverViewController: NSViewController {
    @IBOutlet weak var status: NSTextField!
    @IBOutlet weak var barView: OGCircularBarView!
    @IBOutlet weak var titleLabel: NSTextField!
    private var batteryHealth: Int? = SysInfo.batteryHealth()
    private var hddTotalSpace: Double? = SysInfo.totalHddSpace()
    private var hddUsedSpace: Double? = SysInfo.usedHddSpace()

    // TODO: sweep through and properly handle unwrapping optionals
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let barViewArea = NSTrackingArea.init(rect:barView.bounds, options: [NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        barView.addTrackingArea(barViewArea)
        
        let blue = NSColor(calibratedRed: 20/255, green: 160/255, blue: 255, alpha: 1)
        let red = NSColor(calibratedRed: 255, green: 0, blue: 0, alpha: 1)
        let green = NSColor(calibratedRed: 0, green: 255, blue: 0, alpha: 1)
        
        barView.addBarBackground(startAngle: 90, endAngle: -270, radius: 150, width: 15, color: blue.withAlphaComponent(0.1))
        barView.addBarBackground(startAngle: 90, endAngle: -270, radius: 130, width: 15, color: red.withAlphaComponent(0.1))
        
        if let batteryHealth = self.batteryHealth {
            status.stringValue = "\(batteryHealth)"
            barView.addBar(startAngle: 90, endAngle: -270, progress: CGFloat(batteryHealth/100), radius: 150, width: 15, color: blue, animationDuration: 1.5, glowOpacity: 0.4, glowRadius: 8)
        } else {
            status.stringValue = "N/A"
        }
        
        if let hddUsedSpace = self.hddUsedSpace,
            let hddTotalSpace = self.hddTotalSpace {
            barView.addBar(startAngle: 90, endAngle: -270, progress: CGFloat(hddUsedSpace/hddTotalSpace), radius: 130, width: 15, color: red, animationDuration: 1.5, glowOpacity: 0.4, glowRadius: 8)
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

//Note: view controller needs to be instantiated after application load, so view controller does not clobber statusitem launch
extension PopoverViewController {
    static func freshController() -> PopoverViewController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "PopoverViewController")
        
        guard
            let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? PopoverViewController
            else {
                fatalError("ViewController not found")
        }
        
        return viewcontroller
    }
    
    override func mouseMoved(with event:NSEvent) {
        let mouseLoc: CGPoint = NSPointToCGPoint(event.locationInWindow)
        
        // Change label according to which ring we're hoving over.
        // Coordinates must be converted from global to CAShapeLayer coordinates
        if barView.bars[0].touchPath!.contains(barView.bars[0].convert(mouseLoc, from: nil)) {
            if let batteryHealth = self.batteryHealth {
                status.stringValue = "\(batteryHealth)%"
            } else {
                status.stringValue = "N/A"
            }
            
            recenter(status, inView: barView)
            titleLabel.stringValue = "Battery Health"
        } else if barView.bars[1].touchPath!.contains(barView.bars[1].convert(mouseLoc, from: nil)) {
            if let hddUsedSpace = self.hddUsedSpace,
                let hddTotalSpace = self.hddTotalSpace {
                status.stringValue = "\(hddUsedSpace)\n Out Of\n \(hddTotalSpace)GB"
            } else {
                status.stringValue = "N/A"
            }
            
            recenter(status, inView: barView)
            titleLabel.stringValue = "Used HD Space"
        }
    }
}

private extension PopoverViewController {
    func recenter(_ textField: NSTextField, inView view: NSView) {
        textField.sizeToFit()
        textField.frame.origin.x = (view.bounds.origin.x + view.frame.width/2) - textField.frame.width/2
        textField.frame.origin.y = view.bounds.origin.y + view.frame.height/2 - textField.frame.height/2
    }
}

