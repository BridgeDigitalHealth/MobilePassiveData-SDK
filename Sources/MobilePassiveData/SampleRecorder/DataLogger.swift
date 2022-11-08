//
//  DataLogger.swift
//

import Foundation
import ExceptionHandler

public protocol LogFileHandle : AnyObject {
    
    /// A unique identifier for the logger.
    var identifier: String { get }
    
    /// The url to the file.
    var url: URL { get }
    
    /// The content type of the data file (if known).
    var contentType: String? { get }
}

/// `DataLogger` is used to write data samples using a custom encoding to a logging file.
/// - note: This class does **not** use a serial queue to process the samples. It is assumed that the
/// recorder that is using this file will handle that implementation.
open class DataLogger : LogFileHandle {
    
    /// A unique identifier for the logger.
    public let identifier: String
    
    /// The url to the file.
    public let url: URL
    
    /// Open file handle for writing to the logger.
    private let fileHandle: FileHandle
    
    /// Number of samples written to the file.
    public private(set) var sampleCount: Int = 0
    
    /// The content type of the data file (if known).
    open var contentType: String? {
        return nil
    }
    
    /// Default initializer. The initializer will automatically open the file and write the
    /// initial data (if any).
    ///
    /// - parameters:
    ///     - identifier: A unique identifier for the logger.
    ///     - url: The url to the file.
    ///     - initialData: The initial data to write to the file on opening.
    public init(identifier: String, url: URL, initialData: Data?) throws {
        self.identifier = identifier
        self.url = url
        
        let data = initialData ?? Data()
        try data.write(to: url)
        
        self.fileHandle = try FileHandle(forWritingTo: url)
    }
    
    /// Write data to the logger.
    /// - parameter data: The data to add to the logging file.
    /// - throws: Error if writing the data fails because the wasn't enough memory on the device.
    open func write(_ data: Data) throws {
        try ExceptionHandler.try {
            self.fileHandle.seekToEndOfFile()
            self.fileHandle.write(data)
        }
        sampleCount += 1
    }
    
    /// Close the file. This will write the end tag for the root element and then close the file handle.
    /// If there is an error thrown by writing the closing tag, then the file handle will be closed and
    /// the error will be rethrown.
    ///
    /// - throws: Error thrown when attempting to write the closing tag.
    open func close() throws {
        self.fileHandle.closeFile()
    }
}
