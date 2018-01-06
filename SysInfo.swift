//
//  sysinfo.swift
//  MacSitter
//
//  Created by Matas Empakeris on 12/27/17.
//  Copyright © 2017 Matas Empakeris. All rights reserved.
//  Huge shoutout to Beltex (https://github.com/beltex) whose library (SystemKit) I used as learning material
//

import IOKit.pwr_mgt
import IOKit.ps
import Darwin
import Foundation

public class SysInfo {
    private static var prevCPULoad : host_cpu_load_info = SysInfo.hostCPULoadInfo()!
    
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
    
    public static func maxFanSpeeds() -> [Int] {
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
    
    /**
        returns cpu usage by category (system, user, idle, and other)
    */
    public static func cpuUsageByCategory() -> (system: Double,
                                                user: Double,
                                                idle: Double,
                                                other: Double) {
            // retrieve cpu ticks per category
            let currentCPULoad = SysInfo.hostCPULoadInfo()
            if currentCPULoad == nil  {
                return (system: -1.0, user: -1.0, idle: -1.0, other: -1.0)
            }
            
            // usage is calculated by subtracting cpu_ticks recorded at the previous call from
            // the cpu_ticks recorded in the current call
            let userDiff = Double(currentCPULoad!.cpu_ticks.0 - prevCPULoad.cpu_ticks.0)
            let sysDiff = Double(currentCPULoad!.cpu_ticks.0 - prevCPULoad.cpu_ticks.1)
            let idleDiff = Double(currentCPULoad!.cpu_ticks.2 - prevCPULoad.cpu_ticks.2)
            let otherDiff = Double(currentCPULoad!.cpu_ticks.3 - prevCPULoad.cpu_ticks.3)
            
            let totalCPUTicks = userDiff + sysDiff + idleDiff + otherDiff
                                                    
            prevCPULoad = currentCPULoad!
                                                    
            return (sysDiff/totalCPUTicks*100,
                    userDiff/totalCPUTicks*100,
                    idleDiff/totalCPUTicks*100,
                    otherDiff/totalCPUTicks*100)
    }
    
    /**
        returns memory usage by category (free, active, inactive, wired, compressed (activity monitor value))
    */
    public static func memoryUsageByCategory() -> (free : Double,
                                                   active: Double,
                                                   inactive: Double,
                                                   wired: Double,
                                                   compressed: Double) {
            let stats = SysInfo.hostVirtualMemoryStatistics()
            let Gigabyte = 1000000000.0
            if stats == nil {
                return (free: -1.0, active: -1.0, inactive: -1.0, wired: -1.0, compressed: -1.0)
            }
            
            //stats only returns memory blocks used, so need to convert to gigabytes
            let free = Double(stats!.free_count) * Double(PAGE_SIZE) / Gigabyte
            let active = Double(stats!.active_count) * Double(PAGE_SIZE) / Gigabyte
            let inactive = Double(stats!.inactive_count) * Double(PAGE_SIZE) / Gigabyte
            let wired = Double(stats!.wire_count) * Double(PAGE_SIZE) / Gigabyte
            let compressed = Double(stats!.compressor_page_count) * Double(PAGE_SIZE) / Gigabyte
            
            return (free, active, inactive, wired, compressed)
    }
    
    /**
     //TODO: Double check that this behaves properly
        returns max capacity of the battery if there is one. Returns nil if battery doesn't exist
    */
    public static func batteryHealth() -> Int! {
        enum exitCode: Int {
            case IOPSError = -1
            case NotMacbook = -2
        }
        
        if macModel().range(of:"Book") == nil {
            print(macModel())
            return exitCode.NotMacbook.rawValue
        }
        
        let psBlob = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let psList = IOPSCopyPowerSourcesList(psBlob).takeRetainedValue() as [CFTypeRef]
        guard
            let psDesc = IOPSGetPowerSourceDescription(psBlob, psList[0])?.takeUnretainedValue(),
            let value = (psDesc as NSDictionary)[kIOPSMaxCapacityKey] as? Int
            else {
                print("batteryHealth: max capacity could not be found")
                return exitCode.IOPSError.rawValue
        }
        
        return value
    }
    
    // MARK: Private Methods
    
    private static func macModel() -> String {
        let mib = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
        mib[0] = CTL_HW
        mib[1] = HW_MODEL
        
        // get buffer length from sysctl for model char*
        let nameLen = UnsafeMutablePointer<size_t>.allocate(capacity: MemoryLayout<size_t>.size)
        sysctl(mib, 2, nil, nameLen, nil, 0)
        
        // call sysctl again after allocating pointer with nameLen as required
        let name = UnsafeMutableRawPointer.allocate(bytes: nameLen.pointee, alignedTo: 1)
        sysctl(mib, 2, name, nameLen, nil, 0)
        
        let nameptr = name.bindMemory(to: CChar.self, capacity: MemoryLayout.size(ofValue: name))
        let model = String(cString: nameptr)
        
        mib.deallocate(capacity: 2)
        nameLen.deallocate(capacity: MemoryLayout<size_t>.size)
        name.deallocate(bytes: nameLen.pointee, alignedTo: 1)
        
        return model
    }
    
    private static func homeFileSystemAttributeDict() throws -> [FileAttributeKey : Any] {
        var fileSystemAttributeDict = [FileAttributeKey : Any]()
        
        do {
            fileSystemAttributeDict = try FileManager.default.attributesOfFileSystem(forPath:NSHomeDirectory())
        } catch {
            throw error
        }
        
        return fileSystemAttributeDict
    }
    
    /**
        retrieves processor load data
     */
    private static func hostCPULoadInfo() -> host_cpu_load_info? {
        //retrieve Host load info count
        var size = UInt32(MemoryLayout<host_cpu_load_info_data_t>.size/MemoryLayout<integer_t>.size)
        
        //alloc host info UnsafeMutablePointer with one instance
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        
        //rebind pointer temporarily to an integer_t to use with FreeBSD method host_statistics
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
        }
        
        if result != KERN_SUCCESS {
            print("An error occurred in host_statistics")
            return nil
        }
        
        //returns pointee of hostInfo and sets data to that
        let data = hostInfo.move()
        
        hostInfo.deallocate(capacity: 1)
        
        return data
    }
    
    /**
        retrieves stats related to virtual memory usage by category (free, active, inactive, wired, compressed)
    */
    private static func hostVirtualMemoryStatistics() -> vm_statistics64? {
        var size = UInt32(MemoryLayout<vm_statistics64_data_t>.size/MemoryLayout<integer_t>.size)
        let hostInfo = vm_statistics64_t.allocate(capacity: 1)
        
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
        }
        
        let data = hostInfo.move()
        hostInfo.deallocate(capacity: 1)
        
        if result != KERN_SUCCESS {
            print("An error occurred in host_statistics")
            return nil
        }
        
        return data
    }
}
