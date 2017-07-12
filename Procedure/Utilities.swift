//
//  Utilities.swift
//  Procedure
//
//  Created by Grady Zhuo on 27/11/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation

public struct Utils {
    
    public static func Log(debug messages: Any...){
        print(messages)
    }
    
}

internal extension Utils{
    
    struct Generate{
        static var identifier:String {
            return UUID().uuidString
        }
    }
    
}

