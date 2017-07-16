//
//  Protocols.swift
//  Procedure
//
//  Created by Grady Zhuo on 18/12/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation

public protocol Identitiable {
    var identifier: String { get }
}


public protocol RunnableStep : Identitiable {
    func run(with intents: Intents)
}

public protocol SequenceStep: RunnableStep {
    var last:SimpleStep { get }
    
    @discardableResult mutating func `continue`<T:SimpleStep>(byStep step:T)->T
}

public protocol SimpleStep : SequenceStep {
    
    /**
     (readonly)
     */
    var previous: SimpleStep? { get }
    var next: SimpleStep? { set get }
}

let kPrevious = UnsafeMutableRawPointer.allocate(bytes: 0, alignedTo: 0)
extension SimpleStep {
    
    public var last:SimpleStep{
        var next: SimpleStep = self
        
        while let n = next.next {
            next = n
        }
        
        return next
    }
    
    public internal(set) var previous: SimpleStep?{
        set{
            objc_setAssociatedObject(self, kPrevious, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get{
            return objc_getAssociatedObject(self, kPrevious) as? SimpleStep
        }
    }
    
    @discardableResult
    public func `continue`<T>(byStep step:T)->T where T : SimpleStep{
        var last = self.last
        last.next = step
        return step
    }
}

public protocol Copyable : class, NSCopying{ }

extension Copyable {
    
    public var copy: Self {
        return self.copy(with: nil) as! Self
    }
    
}

public protocol ActionTrigger {
    var actions: [Action] { get }
    
    init(actions: [Action])
    
    mutating func add(actions: [Action])
}

//extension Array : ActionTrigger where Element : Action {
//    public var actions: [Action]{
//        return self as! [Action]
//    }
//    
//    public init(actions: [Action]) {
//        self = [Action]() as! Array<_>
//        
//    }
//    
//    public mutating func add(actions: [Action]){
//        
//    }
//}

let k = UnsafeMutableRawPointer.allocate(bytes: 0, alignedTo: 0)
public protocol Shareable : Copyable, Identitiable{
    
}

extension Shareable {
    
    private static var instances:[String:Self] {
        
        set{
            objc_setAssociatedObject(self, k, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get{
            guard let instances = objc_getAssociatedObject(self, k) as? [String:Self] else{
                
                let newInstances = [String:Self]()
                Self.instances = newInstances
                
                return newInstances
            }
            
            
            return instances
        }
    }
    
    public static func shared(forKey key: String)->Self?{
        return instances[key]?.copy
    }
    
    public func share()->String{
        self.share(forKey: identifier)
        return identifier
    }
    
    public func share(forKey key:String){
        Self.instances[key] = copy
    }
}
