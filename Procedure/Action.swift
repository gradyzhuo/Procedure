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

open class Action : Identitiable, Hashable, Shareable, CustomStringConvertible {
    
    public typealias Task = (Intents, @escaping (Result)->Void)->Void
    public internal(set) var identifier: String
    public internal(set) var task: Task

    public var isCancelled:Bool{
        return self.runningItem?.isCancelled ?? false
    }
    
    internal var runningItem: DispatchWorkItem?
    
    public var hashValue: Int {
        return self.identifier.hashValue
    }
    
    public init(identifier:String = Utils.Generate.identifier, do task: @escaping Task){
        self.identifier = identifier
        self.task = task
    }
    
    public func run(with inputs: Intents, inQueue queue: DispatchQueue = .main, completion:((Action, Result)->Void)? = nil){
        
        let taskClosure = self.task
        let action = self

        let workItem = DispatchWorkItem {
            taskClosure(inputs){ result in
                //Waitting for the completion handler be called.
                completion?(action, result)
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
    
    public var description: String{
        return "Action(\(identifier)): \(task)"
    }
    
    deinit {
        print("deinit action : \(identifier)")
    }
}

public func ==(lhs: Action, rhs: Action)->Bool{
    return lhs.identifier == rhs.identifier
}

extension Action : Copyable {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let taskCopy = self.task
        return Action(identifier: identifier, do: taskCopy)
    }
    
    
}
