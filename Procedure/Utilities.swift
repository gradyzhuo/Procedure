//
//  Utilities.swift
//  Procedure
//
//  Created by Grady Zhuo on 27/11/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation


public protocol Identitiable {
    var identifier: String { get }
}

private let kIdentifier = UnsafeMutableRawPointer.allocate(bytes: 0, alignedTo: 0)//UnsafeRawPointer()
extension Identitiable {
    public var identifier:String {
        
        guard let id = objc_getAssociatedObject(self, kIdentifier) as? String else {
            let newIdentifier = Utils.Generate.identifier
            objc_setAssociatedObject(self, kIdentifier, newIdentifier, .OBJC_ASSOCIATION_COPY)
            return newIdentifier
        }
        
        return id
    }
}

public struct Utils {
    
    public static func Log(debug messages: Any...){
        print(messages)
    }
    
}

internal extension Utils{
    
    struct Generate{
        static var identifier:String {
            return String(Date().timeIntervalSince1970.hashValue, radix: 16)
        }
    }
    
}

