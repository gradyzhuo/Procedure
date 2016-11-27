//
//  Action.swift
//  Procedure
//
//  Created by Grady Zhuo on 22/11/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation

public enum ActionResult {
    case successWith(outcome: BanShoutGift?)
    case failureWith(outcome: BanShoutGift?)
    
    public var outcome: BanShoutGift? {
        switch self {
        case let .successWith(outcome):
            return outcome
        case let .failureWith(outcome):
            return outcome
        }
    }
    
    public static var success: ActionResult {
        return .successWith(outcome: nil)
    }
    
    public static var failure: ActionResult {
        return .failureWith(outcome: nil)
    }
    
}

public protocol ActionDelegate {
    //optional
    func action(_ action: Action, didCompletionWithOutput output: BanShoutGift?)
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
}

open class Action : Identitiable, Hashable {
    
    public typealias TaskBlock = (BanShoutGifts, @escaping (ActionResult)->Void)->Void
    
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
    
    public func run(withGifts inputs: BanShoutGifts, inQueue queue: DispatchQueue){
        
        let workItem = DispatchWorkItem {
            self.task(inputs){ output in
                self.delegates.forEach { $0.action(self, didCompletionWithOutput: output.outcome) }
            }
            
        }
        queue.async(execute: workItem)
        self.runningItem = workItem
    }
}

public func ==(lhs: Action, rhs: Action)->Bool{
    return lhs.identifier == rhs.identifier
}
