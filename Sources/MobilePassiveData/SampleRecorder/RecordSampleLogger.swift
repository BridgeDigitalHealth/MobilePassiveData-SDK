//
//  RecordSampleLogger.swift
//  
//


import Foundation
import JsonModel

/// `RecordSampleLogger` is used to write samples encoded as json dictionary objects to a
/// logging file.
public class RecordSampleLogger : DataLogger {
    
    /// Errors that can be thrown by the logger.
    public enum RecordSampleLoggerError : Error {
        /// The logger failed to encode a string.
        case stringEncodingFailed(String)
    }
    
    /// Is the root element in the json file a dictionary?
    /// - seealso: `SampleRecorder.usesRootDictionary`
    public let usesRootDictionary: Bool
    
    /// Does the recorder use a string-delimited format for saving each sample? If so, this contains the keys
    /// used to support encoding in that format.
    public let stringEncodingFormat: StringSeparatedEncodingFormat?
    
    /// Returns "application/json" or the string encoding if applicable.
    override public var contentType: String? {
        return stringEncodingFormat?.contentType ?? "application/json"
    }
    
    private let startText: String
    
    public let factory: SerializationFactory
    
    /// Default initializer. The initializer will automatically open the file and write the
    /// JSON root element and start the sample array.
    ///
    /// - parameters:
    ///     - identifier: A unique identifier for the logger.
    ///     - url: The url to the file.
    ///     - usesRootDictionary: Is the root element in the json file a dictionary?
    public init(identifier: String,
                url: URL,
                factory: SerializationFactory = SerializationFactory.defaultFactory,
                usesRootDictionary: Bool,
                stringEncodingFormat: StringSeparatedEncodingFormat? = nil) throws {
        self.usesRootDictionary = usesRootDictionary
        self.stringEncodingFormat = stringEncodingFormat
        self.factory = factory
        
        let startText: String
        if let format = stringEncodingFormat {
            startText = "\(format.fileTableHeader())"
        } else if usesRootDictionary {
            // If this json file uses a dictionary as its root, then add a start date timestamp
            // and a key for the items in the dictionary.
            let timestamp = factory.encodeString(from: Date(), codingPath: [])
            startText =
            """
            {
            "startDate" : "\(timestamp)",
            "items"     : [
            """
        } else {
            // Otherwise, just open the array
            startText = "[\n"
        }
        guard let data = startText.data(using: .utf8) else {
            throw RecordSampleLoggerError.stringEncodingFailed(startText)
        }
        self.startText = startText
        
        try super.init(identifier: identifier, url: url, initialData: data)
    }
    
    /// Write multiple samples to the logger.
    /// - parameter samples: The samples to add to the logging file.
    /// - throws: Error if writing the samples fails because the wasn't enough memory on the device.
    public func writeSamples(_ samples: [SampleRecord]) throws {
        for sample in samples {
            try writeSample(sample)
        }
    }
    
    /// Write a sample to the logger.
    /// - parameter sample: The sample to add to the logging file.
    /// - throws: Error if writing the sample fails because the wasn't enough memory on the device.
    public func writeSample(_ sample: SampleRecord) throws {
        if let format = self.stringEncodingFormat {
            let string = try sample.delimiterEncodedString(with: format.codingKeys(), delimiter: format.encodingSeparator, factory: factory)
            if sampleCount > 0 || startText.count > 0 {
                try write("\n\(string)")
            } else {
                try write("\(string)")
            }
        }
        else {
            if sampleCount > 0 {
                // If this is not the first sample then write a comma and line feed
                try write(",\n")
            }
            let data = try sample.jsonEncodedData(using: factory)
            try write(data)
        }
    }
    
    /// Close the file. This will write the end tag for the root element and then close the file handle.
    /// If there is an error thrown by writing the closing tag, then the file handle will be closed and
    /// the error will be rethrown.
    ///
    /// - throws: Error thrown when attempting to write the closing tag.
    public override func close() throws {
        
        /// If there is a string encoding format, then there isn't a need for a JSON closure.
        guard self.stringEncodingFormat == nil else {
            try super.close()
            return
        }
        
        // Write the json closure to the file
        let endText = usesRootDictionary ? "\n]\n}" : "\n]"
        var writeError: Error?
        do {
            try write(endText)
        } catch let err {
            writeError = err
        }
        try super.close()
        // If there was an error writing the closure, then rethrow that error *after* closing the file
        if let error = writeError {
            throw error
        }
    }
    
    private func write(_ string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw RecordSampleLoggerError.stringEncodingFailed(string)
        }
        try write(data)
    }
}
