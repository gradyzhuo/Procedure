//
//  Action.swift
//  Procedure
//
//  Created by Grady Zhuo on 22/11/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation

public protocol ActionDelegate {
    //optional
    func action(_ action: Action, didCompletionWithOutput output: Intent?)
}

private let kDelegateId = UnsafeMutableRawPointer.allocate(bytes: 0, alignedTo: 0)//UnsafeRawPointer()
extension ActionDelegate{
    
    internal var identifier:String {
        
        guard let id = objc_getAssociatedObject(self, kDelegateId) as? String else {
            let newIdentifier = Utils.Generate.identifier
            objc_setAssociatedObject(self, kDelegateId, newIdentifier, .OBJC_ASSOCIATION_COPY)
            return newIdentifier
        }
        
        return id
    }
    
    public func action(_ action: Action, didCompletionWithOutput output: BanShoutGift?){
        //default nothing.
    }
}


extension Action {
    //MARK: typealias defines
    public typealias Delegate = ActionDelegate
    
    public enum Result {
        case succeedWith(outcome: Intent?)
        case failureWith(outcome: ActionError?)
        
        public var outcome: Intent? {
            switch self {
            case let .succeedWith(outcome):
                return outcome
            case let .failureWith(outcome):
                return outcome
            }
        }
        
        public static var succeed: Result {
            return .succeedWith(outcome: nil)
        }
        
        public static var failure: Result {
            return .failureWith(outcome: nil)
        }
        
    }
}

open class Action : Identitiable, Hashable {
    
    public typealias TaskBlock = (Intents, @escaping (Result)->Void)->Void
    
    public internal(set) var delegates: [Delegate] = []
    public internal(set) var task: TaskBlock

    internal var runningItem: DispatchWorkItem!
    
    public func add(delegate: Delegate){
        self.delegates.append(delegate)
    }
    
    public func remove(delegate other: Delegate){
        self.remove { $0.identifier == other.identifier }
    }
    
    public func remove(delegates closure: (Delegate) throws ->Bool){
        let delegates = self.delegates
        do{
            self.delegates = try delegates.filter(closure)
        }catch{
            Utils.Log(debug: "Failed by removing delegates.")
        }
    }
    
    public var hashValue: Int {
        return self.identifier.hashValue
    }
    
    public init(do task: @escaping TaskBlock){
        self.task = task
    }
    
    public func run(withGifts inputs: Intents, inQueue queue: DispatchQueue){
        
        let taskClosure = self.task
        
        let semaphore = DispatchSemaphore(value: 0)
        var output: Result!
        let workItem = DispatchWorkItem {
            taskClosure(inputs){ item in
                output = item
                semaphore.signal()
            }
        }
        
        queue.async(execute: workItem)
        self.runningItem = workItem
        
        semaphore.wait()
        
        let action = self
        //Waitting for the completion handler be called.
        self.delegates.forEach { $0.action(action, didCompletionWithOutput: output.outcome) }
        
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
