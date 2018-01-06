//
//  ViewController.swift
//  MacSitter
//
//  Created by Matas Empakeris on 12/22/17.
//  Copyright © 2017 Matas Empakeris. All rights reserved.
//

import Cocoa

class PopoverViewController: NSViewController {
    @IBOutlet weak var batteryHealth: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        let batteryHealth = SysInfo.batteryHealth()
        if batteryHealth == -1 || batteryHealth == -2 {
            self.batteryHealth.stringValue = "N/A"
        } else {
            self.batteryHealth.stringValue = "\(batteryHealth!)"
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
        
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as?
            PopoverViewController else {
                fatalError("ViewController not found")
        }
        
        return viewcontroller
    }
}

