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
    
    /***PUBLIC METHODS***/
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
    
    /*** PRIVATE METHODS ***/
    
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
