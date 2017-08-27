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

private let kIdentifier = UnsafeMutableRawPointer.allocate(bytes: 0, alignedTo: 0)
extension Identitiable {
    public var identifier: String {
        get{
            guard let id = objc_getAssociatedObject(self, kIdentifier) as? String else{
                let identifier = Utils.Generate.identifier()
                objc_setAssociatedObject(self, kIdentifier, identifier, .OBJC_ASSOCIATION_COPY)
                return identifier
            }
            return id
        }
    }
}

public protocol Flowable: Identitiable {
    /**
     (readonly)
     */
    var previous: SimpleStep? { get }
    var next: SimpleStep? { set get }
    
    var last:SimpleStep { get }
}


public protocol SimpleStep : Flowable {
    
    var name: String { set get }
    
    func run(with intents: Intents)
}

let kPrevious = UnsafeMutableRawPointer.allocate(bytes: 0, alignedTo: 0)
extension SimpleStep {
    
    public var last:SimpleStep{
        var nextStep: SimpleStep = self
        
        while let next = nextStep.next {
            nextStep = next
        }
        return nextStep
    }
    
    public internal(set) var previous: SimpleStep?{
        set{
            objc_setAssociatedObject(self, kPrevious, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get{
            return objc_getAssociatedObject(self, kPrevious) as? SimpleStep
        }
    }
}

public protocol Copyable : class, NSCopying{ }

extension Copyable {
    
    public var copy: Self {
        return self.copy(with: nil) as! Self
    }
    
}

public protocol Invocable {
    var actions: [Action] { get }
    
    init(actions: [Action])
    
    mutating func invoke(actions: [Action])
}

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
