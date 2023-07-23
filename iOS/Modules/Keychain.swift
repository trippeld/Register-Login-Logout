//
//  SwiftKeychain.swift
//  Wip
//
//  Created by Daniel Douglas Dyrseth on 04/11/2017.
//  Copyright © 2017 Lightpear. All rights reserved.
//


import Security
import Foundation

open class KeychainSwift {
    
    var lastQueryParameters: [String: Any]?
    
    open var lastResultCode: OSStatus = noErr
    
    var keyPrefix = ""
    
    open var accessGroup: String?
    
    
    open var synchronizable: Bool = false
    
    private let readLock = NSLock()
    
    public init() { }
    
    public init(keyPrefix: String) {
        self.keyPrefix = keyPrefix
    }
    
    @discardableResult
    open func set(_ value: String, forKey key: String,
                  withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
        
        if let value = value.data(using: String.Encoding.utf8) {
            return set(value, forKey: key, withAccess: access)
        }
        
        return false
    }
    
    @discardableResult
    open func set(_ value: Data, forKey key: String,
                  withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
        
        delete(key)
        
        let accessible = access?.value ?? KeychainSwiftAccessOptions.defaultOption.value
        
        let prefixedKey = keyWithPrefix(key)
        
        var query: [String : Any] = [
            KeychainSwiftConstants.klass       : kSecClassGenericPassword,
            KeychainSwiftConstants.attrAccount : prefixedKey,
            KeychainSwiftConstants.valueData   : value,
            KeychainSwiftConstants.accessible  : accessible
        ]
        
        query = addAccessGroupWhenPresent(query)
        query = addSynchronizableIfRequired(query, addingItems: true)
        lastQueryParameters = query
        
        lastResultCode = SecItemAdd(query as CFDictionary, nil)
        
        return lastResultCode == noErr
    }
    
    @discardableResult
    open func set(_ value: Bool, forKey key: String,
                  withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
        
        let bytes: [UInt8] = value ? [1] : [0]
        let data = Data(bytes: bytes)
        
        return set(data, forKey: key, withAccess: access)
    }
    
    open func get(_ key: String) -> String? {
        if let data = getData(key) {
            
            if let currentString = String(data: data, encoding: .utf8) {
                return currentString
            }
            
            lastResultCode = -67853
        }
        
        return nil
    }
    
    open func getData(_ key: String) -> Data? {
        readLock.lock()
        defer { readLock.unlock() }
        
        let prefixedKey = keyWithPrefix(key)
        
        var query: [String: Any] = [
            KeychainSwiftConstants.klass       : kSecClassGenericPassword,
            KeychainSwiftConstants.attrAccount : prefixedKey,
            KeychainSwiftConstants.returnData  : kCFBooleanTrue,
            KeychainSwiftConstants.matchLimit  : kSecMatchLimitOne
        ]
        
        query = addAccessGroupWhenPresent(query)
        query = addSynchronizableIfRequired(query, addingItems: false)
        lastQueryParameters = query
        
        var result: AnyObject?
        
        lastResultCode = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        if lastResultCode == noErr { return result as? Data }
        
        return nil
    }
    
    open func getBool(_ key: String) -> Bool? {
        guard let data = getData(key) else { return nil }
        guard let firstBit = data.first else { return nil }
        return firstBit == 1
    }
    
    @discardableResult
    open func delete(_ key: String) -> Bool {
        let prefixedKey = keyWithPrefix(key)
        
        var query: [String: Any] = [
            KeychainSwiftConstants.klass       : kSecClassGenericPassword,
            KeychainSwiftConstants.attrAccount : prefixedKey
        ]
        
        query = addAccessGroupWhenPresent(query)
        query = addSynchronizableIfRequired(query, addingItems: false)
        lastQueryParameters = query
        
        lastResultCode = SecItemDelete(query as CFDictionary)
        
        return lastResultCode == noErr
    }
    
    @discardableResult
    open func clear() -> Bool {
        var query: [String: Any] = [ kSecClass as String : kSecClassGenericPassword ]
        query = addAccessGroupWhenPresent(query)
        query = addSynchronizableIfRequired(query, addingItems: false)
        lastQueryParameters = query
        
        lastResultCode = SecItemDelete(query as CFDictionary)
        
        return lastResultCode == noErr
    }
    
    func keyWithPrefix(_ key: String) -> String {
        return "\(keyPrefix)\(key)"
    }
    
    func addAccessGroupWhenPresent(_ items: [String: Any]) -> [String: Any] {
        guard let accessGroup = accessGroup else { return items }
        
        var result: [String: Any] = items
        result[KeychainSwiftConstants.accessGroup] = accessGroup
        return result
    }
    
    func addSynchronizableIfRequired(_ items: [String: Any], addingItems: Bool) -> [String: Any] {
        if !synchronizable { return items }
        var result: [String: Any] = items
        result[KeychainSwiftConstants.attrSynchronizable] = addingItems == true ? true : kSecAttrSynchronizableAny
        return result
    }
}



import Foundation
import Security

public struct KeychainSwiftConstants {
    public static var accessGroup: String { return toString(kSecAttrAccessGroup) }
    
    public static var accessible: String { return toString(kSecAttrAccessible) }
    
    public static var attrAccount: String { return toString(kSecAttrAccount) }
    
    public static var attrSynchronizable: String { return toString(kSecAttrSynchronizable) }
    
    public static var klass: String { return toString(kSecClass) }
    
    public static var matchLimit: String { return toString(kSecMatchLimit) }
    
    public static var returnData: String { return toString(kSecReturnData) }
    
    public static var valueData: String { return toString(kSecValueData) }
    
    static func toString(_ value: CFString) -> String {
        return value as String
    }
}



import Security

public enum KeychainSwiftAccessOptions {
    
    case accessibleWhenUnlocked
    
    case accessibleWhenUnlockedThisDeviceOnly
    
    case accessibleAfterFirstUnlock
    
    case accessibleAfterFirstUnlockThisDeviceOnly
    
    case accessibleAlways
    
    case accessibleWhenPasscodeSetThisDeviceOnly
    
    case accessibleAlwaysThisDeviceOnly
    
    static var defaultOption: KeychainSwiftAccessOptions {
        return .accessibleAfterFirstUnlock
    }
    
    var value: String {
        switch self {
        case .accessibleWhenUnlocked:
            return toString(kSecAttrAccessibleWhenUnlocked)
            
        case .accessibleWhenUnlockedThisDeviceOnly:
            return toString(kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
            
        case .accessibleAfterFirstUnlock:
            return toString(kSecAttrAccessibleAfterFirstUnlock)
            
        case .accessibleAfterFirstUnlockThisDeviceOnly:
            return toString(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
            
        case .accessibleAlways:
            return toString(kSecAttrAccessibleAlways)
            
        case .accessibleWhenPasscodeSetThisDeviceOnly:
            return toString(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly)
            
        case .accessibleAlwaysThisDeviceOnly:
            return toString(kSecAttrAccessibleAlwaysThisDeviceOnly)
        }
    }
    
    func toString(_ value: CFString) -> String {
        return KeychainSwiftConstants.toString(value)
    }
}
