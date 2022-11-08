//
//  ValidationError.swift
//  
//

import Foundation

/// `ValidationError` is a catch-all for different types of errors that occur during
/// validation of a decoded or encoded object.
///
public enum ValidationError : CustomNSError, LocalizedError {
    
    /// Attempting to load a section, task, or input form with non-unique identifiers.
    case notUniqueIdentifiers(String)
    
    /// Expected identifier was not found.
    case identifierNotFound(identifier: String, String)
    
    /// Unsupported data type.
    case invalidType(String)
    
    /// The value provided does not unwrap into an expected type.
    case invalidValue(value: Any?, String)

    /// A forced optional unwrapped with a nil value.
    case unexpectedNullObject(String)
    
    /// The domain of the error.
    public static var errorDomain: String {
        return "MPDValidationErrorDomain"
    }
    
    /// The error code within the given domain.
    public var errorCode: Int {
        switch(self) {
        case .notUniqueIdentifiers(_):
            return -1
        case .invalidType(_):
            return -5
        case .identifierNotFound(_, _):
            return -6
        case .unexpectedNullObject(_):
            return -7
        case .invalidValue(_, _):
            return -8
        }
    }
    
    /// The user-info dictionary.
    public var errorUserInfo: [String : Any] {
        let description: String
        switch(self) {
        case .notUniqueIdentifiers(let str): description = str
        case .invalidType(let str): description = str
        case .identifierNotFound(_, let str): description = str
        case .unexpectedNullObject(let str): description = str
        case .invalidValue(_, let str): description = str
        }
        return ["NSDebugDescription": description]
    }
}
