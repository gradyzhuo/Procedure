//
//  BanShoutGift.swift
//  Procedure
//
//  Created by Grady Zhuo on 22/11/2016.
//  Copyright © 2016 Grady Zhuo. All rights reserved.
//

import Foundation


public struct BanShoutGift  {
    
    public let name: String
    public let gift: Any?
    
    public init(name: String, gift: Any? = nil){
        self.name = name
        self.gift = gift
    }
    
}


public struct BanShoutGifts {
    internal var gifts: [String: BanShoutGift] = [:]
    
    public mutating func add(gift: BanShoutGift){
        gifts[gift.name] = gift
    }
    
    public mutating func add(gifts: [BanShoutGift]){
        gifts.forEach{ self.gifts[$0.name] = $0 }
    }
    
    public mutating func add(gifts: BanShoutGifts){
        gifts.gifts.forEach{ self.gifts[$0] = $1 }
    }
    
    public mutating func remove(for name: String)->BanShoutGift?{
        return gifts.removeValue(forKey: name)
    }
    
    public mutating func remove(gift: BanShoutGift){
        gifts.removeValue(forKey: gift.name)
    }
    
    public func gift(for name: String)-> BanShoutGift? {
        return gifts[name]
    }
    
    public init(gifts: [BanShoutGift]){
        self.add(gifts: gifts)
    }
    
    public subscript(name: String)->BanShoutGift?{
        
        set{
            guard let gift = newValue else {
                return
            }
            
            gifts[gift.name] = gift
        }
        
        get{
            return gift(for: name)
        }
        
    }
}

extension BanShoutGifts : ExpressibleByArrayLiteral{
    public typealias Element = BanShoutGift
    
    
    public init(arrayLiteral elements: Element...) {
        elements.forEach{ gifts[$0.name] = $0 }
    }

}

extension BanShoutGifts : ExpressibleByDictionaryLiteral{
    public typealias Key = String
    public typealias Value = BanShoutGift
    
    public init(dictionaryLiteral elements: (Key, Value)...) {
        elements.forEach{ gifts[$0.0] = $0.1 }
    }
    
}

public func +(lhs: BanShoutGifts, rhs: BanShoutGifts)->BanShoutGifts{
    var gifts = lhs
    gifts.add(gifts: rhs)
    return gifts
}

public func +(lhs: BanShoutGifts, rhs: BanShoutGift)->BanShoutGifts{
    var gifts = lhs
    gifts.add(gift: rhs)
    return gifts
}
