//
//  File.swift
//  
//
//  Created by Robert Garcia on 31/7/23.
//

import Foundation


enum CryptoError: Error, Equatable {
    case badIv
    case badKey
    case badIndex(String)
    case encryptionFailed
    case decryptionFailed
    case bytesNotMatching
    case CannotGetCombinedData
    case invalidBase64String
    case emptyBase64String
}


enum ConfigLoaderError: Error {
    case NoConfigLoaded(String)
    case MissingConfigProperty(String)
}


enum APIError: Error {
    case decoding
    case server(String)
    case noInternet
    case failedRequest(String)
    case invalidResponse
}


enum ExtensionError: Swift.Error, Equatable {
    case InvalidHex
}

public enum UploadError: Error, Equatable {
    case InvalidIndex
    case CannotGenerateFileHash
    case FailedToFinishUpload
    case MissingUploadUrl
    case UploadNotSuccessful
    case UploadedSizeNotMatching
    case MissingEtag
    case PartUploadFailed(partIndex: Int, error: Error)

    public static func == (lhs: UploadError, rhs: UploadError) -> Bool {
        switch (lhs, rhs) {
        case (.InvalidIndex, .InvalidIndex),
             (.CannotGenerateFileHash, .CannotGenerateFileHash),
             (.FailedToFinishUpload, .FailedToFinishUpload),
             (.MissingUploadUrl, .MissingUploadUrl),
             (.UploadNotSuccessful, .UploadNotSuccessful),
             (.UploadedSizeNotMatching, .UploadedSizeNotMatching),
             (.MissingEtag, .MissingEtag):
            return true
        case let (.PartUploadFailed(lhsPartIndex, lhsError), .PartUploadFailed(rhsPartIndex, rhsError)):
            return lhsPartIndex == rhsPartIndex && lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}


public class StartUploadError: Error {
    public var apiError: APIClientError? = nil
    public init(apiError: APIClientError? = nil) {
        self.apiError = apiError
    }
}

public class FinishUploadError: Error {
    public var apiError: APIClientError? = nil
    public init(apiError: APIClientError? = nil) {
        self.apiError = apiError
    }
}

enum NetworkFacadeError: Swift.Error, Equatable {
    case EncryptionFailed
    case FailedToOpenEncryptOutputStream
    case FailedToOpenDecryptOutputStream
    case FailedToOpenDecryptInputStream
    case EncryptedFileNotSameSizeAsOriginal
    case DecryptionFailed
    case HashMissmatch
    case FileIsEmpty
}
