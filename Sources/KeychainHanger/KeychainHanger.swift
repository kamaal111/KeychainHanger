//
//  KeychainHanger.swift
//  
//
//  Created by Kamaal M Farah on 19/10/2021.
//

import Foundation

public struct KeychainHanger {
    public let prefix: String

    public init(prefix: String) {
        self.prefix = prefix
    }

    public func deleteItems(query: KHQuery, type: KHPasswordTypes) {
        var deleteItemsQuery: [CFString: Any] = [
            kSecClass: type.securityClass,
            kSecReturnData: true,
            kSecReturnAttributes: true
        ]
        if let username = query.username {
            deleteItemsQuery[kSecAttrAccount] = username
        }
        if let application = query.application {
            deleteItemsQuery[kSecAttrServer] = applicationWithPrefix(prefix: prefix, application: application)
        }

        SecItemDelete(deleteItemsQuery as CFDictionary)
    }

    public func updateItems(
        query: KHQuery,
        account: String?,
        password: String?,
        application: String?,
        type: KHPasswordTypes) -> OSStatus {
            var getItemsQuery: [CFString: Any] = [
                kSecClass: type.securityClass,
                kSecReturnData: true,
                kSecReturnAttributes: true
            ]
            if let username = query.username {
                getItemsQuery[kSecAttrAccount] = username
            }
            if let application = query.application {
                getItemsQuery[kSecAttrServer] = applicationWithPrefix(prefix: prefix, application: application)
            }

            var updateFields: [CFString: Any] = [:]
            if let account = account {
                updateFields[kSecAttrAccount] = account
            }
            if let password = password {
                updateFields[kSecValueData] = password.data(using: .utf8)!
            }
            if let application = application {
                updateFields[kSecAttrServer] = applicationWithPrefix(prefix: prefix, application: application)
            }

            let status = SecItemUpdate(getItemsQuery as CFDictionary, updateFields as CFDictionary)
            return status
    }

    public func getItems(
        query: KHQuery,
        amount: Int,
        type: KHPasswordTypes) -> KHResult<[KHItem]?> {
            var getItemsQuery: [CFString: Any] = [
                kSecClass: type.securityClass,
                kSecReturnAttributes: true,
                kSecReturnData: true,
                kSecMatchLimit: amount
            ]
            if let username = query.username {
                getItemsQuery[kSecAttrAccount] = username
            }
            if let application = query.application {
                getItemsQuery[kSecAttrServer] = applicationWithPrefix(prefix: prefix, application: application)
            }

            var getItemsReference: AnyObject?
            let getItemsStatus = SecItemCopyMatching(getItemsQuery as CFDictionary, &getItemsReference)

            let getItemsResults: [NSDictionary]
            if let unwrappedReference = getItemsReference as? NSDictionary {
                getItemsResults = [unwrappedReference]
            } else if let unwrappedReference = getItemsReference as? [NSDictionary] {
                getItemsResults = unwrappedReference
            } else {
                return KHResult(status: getItemsStatus, item: nil)
            }

            let hangerItems = getItemsResults.map { item in
                KHItem(original: item)
            }
            return KHResult(status: getItemsStatus, item: hangerItems)
    }

    public func saveItem(
        password: String,
        username: String?,
        application: String?,
        type: KHPasswordTypes) -> KHResult<KHItem?> {
            var keychainItemQuery: [CFString: Any] = [
                kSecValueData: password.data(using: .utf8)!,
                kSecClass: type.securityClass,
                kSecReturnData: true,
                kSecReturnAttributes: true
            ]
            if let username = username {
                keychainItemQuery[kSecAttrAccount] = username
            }
            if let application = application {
                keychainItemQuery[kSecAttrServer] = applicationWithPrefix(prefix: prefix, application: application)
            }

            var setItemReference: AnyObject?
            let itemAddedStatus = SecItemAdd(keychainItemQuery as CFDictionary, &setItemReference)

            guard let setItemResult = setItemReference as? NSDictionary else {
                return KHResult(status: itemAddedStatus, item: nil)
            }

            return KHResult(status: itemAddedStatus, item: KHItem(original: setItemResult))
    }

    private func applicationWithPrefix(prefix: String, application: String) -> String? {
        "\(prefix).\(application)"
    }
}

public struct KHQuery {
    public let username: String?
    public let application: String?

    public init(username: String?, application: String?) {
        self.username = username
        self.application = application
    }
}

public struct KHResult<T> {
    public let status: OSStatus
    public let item: T
}

public enum KHPasswordTypes {
    case internet

    public var securityClass: CFString {
        switch self {
        case .internet: return kSecClassInternetPassword
        }
    }
}

public struct KHItem {
    public let original: NSDictionary

    init(original: NSDictionary) {
        self.original = original
    }

    public var password: String? {
        guard let passwordData = original[kSecValueData] as? Data else { return nil }
        return String(data: passwordData, encoding: .utf8)
    }

    public var username: String? {
        original[kSecAttrAccount] as? String
    }
}
