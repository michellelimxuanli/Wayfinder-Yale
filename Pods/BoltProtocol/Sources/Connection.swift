import Foundation
import PackStream

#if os(Linux)
import Dispatch
#endif

public class Connection: NSObject {

    private let settings: ConnectionSettings

    private var socket: SocketProtocol
    public var currentTransactionBookmark: String?

    public init(socket: SocketProtocol,
                settings: ConnectionSettings = ConnectionSettings() ) {
        
        self.socket = socket
        self.settings = settings

        super.init()
    }

    public func connect(completion: (_ success: Bool) throws -> Void) throws {
        try socket.connect(timeout: 10)
        try initBolt()
        try initialize()
        try completion(true)
    }

    private func initBolt() throws {
        try socket.send(bytes: [0x60, 0x60, 0xB0, 0x17, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        let response = try socket.receive(expectedNumberOfBytes: 4)
        let version = try UInt32.unpack(response[0..<response.count])
        if version == 1 {
            // success
        } else {
            throw ConnectionError.unknownVersion
        }
    }

    private func initialize() throws {
        let message = Request.initialize(settings: settings)
        let chunks = try message.chunk()
        for chunk in chunks {
            try socket.send(bytes: chunk)
        }

        let responseData = try socket.receive(expectedNumberOfBytes: 1024) //TODO: Ensure I get all chunks back
        let unchunkedResponseDatas = try Response.unchunk(responseData)
        for unchunkedResponseData in unchunkedResponseDatas {
            let _ = try Response.unpack(unchunkedResponseData)
            // TODO: throw ConnectionError.authenticationError on error
        }
    }

    public enum ConnectionError: Error {
        case unknownVersion
        case authenticationError
        case requestError
    }

    enum CommandResponse: Byte {
        case success = 0x70
        case record = 0x71
        case ignored = 0x7e
        case failure = 0x7f
    }

    private func chunkAndSend(request: Request) throws {

        let chunks = try request.chunk()

        for chunk in chunks {
            let _ = try socket.send(bytes: chunk)
            // let response = try socket.send(bytes: chunk)
            // TODO: Use response
        }

    }

    private func parseMeta(_ meta: [PackProtocol]) {
        for item in meta {
            if let map = item as? Map {
                for (key, value) in map.dictionary {
                    switch key {
                    case "bookmark":
                        self.currentTransactionBookmark = value as? String
                    case "stats":
                        break
                    case "result_available_after":
                        break
                    case "result_consumed_after":
                        break
                    case "type":
                        break
                    case "fields":
                        break
                    default:
                        print("Couldn't parse metadata \(key)")
                    }
                }
            }
        }
    }

    public func request(_ request: Request, completionHandler: (Bool, [Response]) throws -> Void) throws {

        try chunkAndSend(request: request)

        let responseData = try socket.receive(expectedNumberOfBytes: 1024) //TODO: Ensure I get all chunks back
        let unchunkedResponsesAsBytes = try Response.unchunk(responseData)

        var responses = [Response]()
        var success = true
        for responseBytes in unchunkedResponsesAsBytes {
            let response = try Response.unpack(responseBytes)
            responses.append(response)

            if let error = response.asError() {
                throw error
            }

            if response.category != .record {
                parseMeta(response.items)
            }

            success = success && response.category != .failure
        }

        try completionHandler(success, responses)
    }

}
