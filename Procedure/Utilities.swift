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

extension Utils{
    
    public struct Generate{
        public static func identifier()->String {
            return UUID().uuidString
        }
    }
    
}

