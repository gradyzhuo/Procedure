//
//  Action.swift
//  Procedure
//
//  Created by Grady Zhuo on 22/11/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation

extension Action {
    //MARK: typealias defines
    
    public enum Result {
        case succeedWith(outcome: Intents)
        case failureWith(error: Procedure.Error?)
        
        public var outcomes: Intents {
            switch self {
            case let .succeedWith(outcome):
                return outcome
            case let .failureWith(error):
                if let error = error {
                    return [error]
                }
                return []
            }
        }
        
        public static var succeed: Result {
            return .succeedWith(outcome: [])
        }
        
        public static var failure: Result {
            return .failureWith(error: nil)
        }
        
    }
}

open class Action : Identitiable, Hashable {
    
    public typealias TaskBlock = (Intents, @escaping (Result)->Void)->Void
    
    public internal(set) var task: TaskBlock

    public var isCancelled:Bool{
        return self.runningItem?.isCancelled ?? false
    }
    
    internal var runningItem: DispatchWorkItem?
    
    public var hashValue: Int {
        return self.identifier.hashValue
    }
    
    public init(do task: @escaping TaskBlock){
        self.task = task
    }
    
    public func run(withGifts inputs: Intents, inQueue queue: DispatchQueue, completion:@escaping (Action, Result)->Void){
        
        let taskClosure = self.task
        let action = self

        let workItem = DispatchWorkItem {
            taskClosure(inputs){ result in
                //Waitting for the completion handler be called.
                completion(action, result)
            }
        }
        
        queue.async(execute: workItem)
        self.runningItem = workItem
        
    }
    
    
    public func cancel(){
        guard let runningItem = runningItem else {
            return
        }
        
        if !runningItem.isCancelled {
            runningItem.cancel()
        }
        
    }
}

public func ==(lhs: Action, rhs: Action)->Bool{
    return lhs.identifier == rhs.identifier
}

extension Action : Copyable {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let taskCopy = self.task
        return Action(do: taskCopy)
    }
    
    
}
