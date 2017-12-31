//
//  sysinfo.swift
//  MacSitter
//
//  Created by Matas Empakeris on 12/27/17.
//  Copyright © 2017 Matas Empakeris. All rights reserved.
//

import Darwin
import Foundation

public class SysInfo {
    
    // MARK: Public Methods
    
    public static func totalHddSpace() -> Float {
        guard
            let fileSystemAttributeDict = try? homeFileSystemAttributeDict()
            else {
                //Some error occurred
                return -1
        }
        
        //calculate space left in gigabytes
        let totalSpace = fileSystemAttributeDict[.systemSize] as! NSNumber
        let gigabyteDivider : Float = 1000000000.0
        return totalSpace.floatValue / gigabyteDivider
    }
    
    public static func freeHddSpace() -> Float {
        guard
            let fileSystemAttributeDict = try? homeFileSystemAttributeDict()
            else {
                //Some error occurred
                return -1
        }
        
        //calculate space free in gigabytes
        let freeSpace = fileSystemAttributeDict[.systemFreeSize] as! NSNumber
        let gigabyteDivider : Float = 1000000000.0
        return freeSpace.floatValue / gigabyteDivider
    }
    
    public static func cpuTemperature(_ temperatureUnit:TemperatureUnit) -> Double {
        var temperature : Double = 0.0
        do {
            try SMCKit.open()
            temperature = try SMCKit.temperature(TemperatureSensors.CPU_0_DIE.code, unit:temperatureUnit)
            SMCKit.close()
        } catch {
            print(error)
            SMCKit.close()
        }
        
        return temperature
    }
    
    public static func currentFanSpeeds() -> [Int] {
        var fanSpeeds:[Int] = []
        do {
            try SMCKit.open()
            
            let numFans = try SMCKit.fanCount()
            for ii in 0...numFans-1 {
                fanSpeeds.append(try SMCKit.fanCurrentSpeed(ii))
            }
            
            SMCKit.close()
        } catch {
            print(error)
            SMCKit.close()
        }
        
        return fanSpeeds
    }
    
    func maxFanSpeeds() -> [Int] {
        var fanSpeeds:[Int] = []
        do {
            try SMCKit.open()
            
            let numFans = try SMCKit.fanCount()
            for ii in 0...numFans-1 {
                fanSpeeds.append(try SMCKit.fanMaxSpeed(ii))
            }
            
            SMCKit.close()
        } catch {
            print(error)
            SMCKit.close()
        }
        
        return fanSpeeds
    }
    
    // MARK: Private Methods
    
    private static func homeFileSystemAttributeDict() throws -> [FileAttributeKey : Any] {
        var fileSystemAttributeDict = [FileAttributeKey : Any]()
        
        do {
            fileSystemAttributeDict = try FileManager.default.attributesOfFileSystem(forPath:NSHomeDirectory())
        } catch {
            throw error
        }
        
        return fileSystemAttributeDict
    }
}
