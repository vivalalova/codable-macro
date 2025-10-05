import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import CodableMacroMacros
@testable import CodableMacro

/// Enum 測試
struct EnumCodableTests {

    @Test("Simple enum - 基本功能")
    func testSimpleEnum() throws {
        assertMacroExpansion(
            """
            @Codable
            enum Direction {
                case north
                case south
                case east
                case west
            }
            """,
            expandedSource: """
            enum Direction {
                case north
                case south
                case east
                case west

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let value = try container.decode(String.self)

                    switch value {
                    case "north":
                        self = .north
                    case "south":
                        self = .south
                    case "east":
                        self = .east
                    case "west":
                        self = .west
                    default:
                        throw DecodingError.dataCorrupted(
                            DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Invalid enum case: \\(value)"
                            )
                        )
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()

                    switch self {
                    case .north:
                        try container.encode("north")
                    case .south:
                        try container.encode("south")
                    case .east:
                        try container.encode("east")
                    case .west:
                        try container.encode("west")
                    }
                }
            }

            extension Direction: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Simple enum - 單一 case")
    func testSimpleEnumSingleCase() throws {
        assertMacroExpansion(
            """
            @Codable
            enum Status {
                case active
            }
            """,
            expandedSource: """
            enum Status {
                case active

                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let value = try container.decode(String.self)

                    switch value {
                    case "active":
                        self = .active
                    default:
                        throw DecodingError.dataCorrupted(
                            DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Invalid enum case: \\(value)"
                            )
                        )
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.singleValueContainer()

                    switch self {
                    case .active:
                        try container.encode("active")
                    }
                }
            }

            extension Status: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Associated values enum - 有標籤參數")
    func testAssociatedValuesEnumWithLabels() throws {
        assertMacroExpansion(
            """
            @Codable
            enum NetworkResponse {
                case success(data: String, statusCode: Int)
                case failure(error: String)
                case empty
            }
            """,
            expandedSource: """
            enum NetworkResponse {
                case success(data: String, statusCode: Int)
                case failure(error: String)
                case empty

                enum CodingKeys: String, CodingKey {
                    case success
                    case failure
                    case empty
                }

                enum SuccessCodingKeys: String, CodingKey {
                    case data
                    case statusCode
                }

                enum FailureCodingKeys: String, CodingKey {
                    case error
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    if container.allKeys.count != 1 {
                        throw DecodingError.dataCorrupted(
                            DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Expected exactly one key"
                            )
                        )
                    }

                    let key = container.allKeys.first!

                    switch key {
                    case .success:
                        let nestedContainer = try container.nestedContainer(keyedBy: SuccessCodingKeys.self, forKey: .success)
                        let data = try nestedContainer.decode(String.self, forKey: .data)
                        let statusCode = try nestedContainer.decode(Int.self, forKey: .statusCode)
                        self = .success(data: data, statusCode: statusCode)
                    case .failure:
                        let nestedContainer = try container.nestedContainer(keyedBy: FailureCodingKeys.self, forKey: .failure)
                        let error = try nestedContainer.decode(String.self, forKey: .error)
                        self = .failure(error: error)
                    case .empty:
                        self = .empty
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)

                    switch self {
                    case .success(let data, let statusCode):
                        var nestedContainer = container.nestedContainer(keyedBy: SuccessCodingKeys.self, forKey: .success)
                        try nestedContainer.encode(data, forKey: .data)
                        try nestedContainer.encode(statusCode, forKey: .statusCode)
                    case .failure(let error):
                        var nestedContainer = container.nestedContainer(keyedBy: FailureCodingKeys.self, forKey: .failure)
                        try nestedContainer.encode(error, forKey: .error)
                    case .empty:
                        _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .empty)
                    }
                }
            }

            extension NetworkResponse: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Associated values enum - 無標籤參數")
    func testAssociatedValuesEnumWithoutLabels() throws {
        assertMacroExpansion(
            """
            @Codable
            enum Result {
                case success(String)
                case failure(Int, String)
            }
            """,
            expandedSource: """
            enum Result {
                case success(String)
                case failure(Int, String)

                enum CodingKeys: String, CodingKey {
                    case success
                    case failure
                }

                enum SuccessCodingKeys: String, CodingKey {
                    case _0
                }

                enum FailureCodingKeys: String, CodingKey {
                    case _0
                    case _1
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    if container.allKeys.count != 1 {
                        throw DecodingError.dataCorrupted(
                            DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Expected exactly one key"
                            )
                        )
                    }

                    let key = container.allKeys.first!

                    switch key {
                    case .success:
                        let nestedContainer = try container.nestedContainer(keyedBy: SuccessCodingKeys.self, forKey: .success)
                        let _0 = try nestedContainer.decode(String.self, forKey: ._0)
                        self = .success(_0)
                    case .failure:
                        let nestedContainer = try container.nestedContainer(keyedBy: FailureCodingKeys.self, forKey: .failure)
                        let _0 = try nestedContainer.decode(Int.self, forKey: ._0)
                        let _1 = try nestedContainer.decode(String.self, forKey: ._1)
                        self = .failure(_0, _1)
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)

                    switch self {
                    case .success(let _0):
                        var nestedContainer = container.nestedContainer(keyedBy: SuccessCodingKeys.self, forKey: .success)
                        try nestedContainer.encode(_0, forKey: ._0)
                    case .failure(let _0, let _1):
                        var nestedContainer = container.nestedContainer(keyedBy: FailureCodingKeys.self, forKey: .failure)
                        try nestedContainer.encode(_0, forKey: ._0)
                        try nestedContainer.encode(_1, forKey: ._1)
                    }
                }
            }

            extension Result: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Raw value enum - 應提供診斷訊息")
    func testRawValueEnum() throws {
        assertMacroExpansion(
            """
            @Codable
            enum Color: String {
                case red
                case green
                case blue
            }
            """,
            expandedSource: """
            enum Color: String {
                case red
                case green
                case blue
            }

            extension Color: Codable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Enum with raw value already conforms to Codable", line: 1, column: 1, severity: .warning)
            ],
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Mixed associated values enum - 有些 case 有參數，有些沒有")
    func testMixedAssociatedValuesEnum() throws {
        assertMacroExpansion(
            """
            @Codable
            enum LoadingState {
                case idle
                case loading(progress: Double)
                case success(data: String)
                case failure(error: String, retryCount: Int)
            }
            """,
            expandedSource: """
            enum LoadingState {
                case idle
                case loading(progress: Double)
                case success(data: String)
                case failure(error: String, retryCount: Int)

                enum CodingKeys: String, CodingKey {
                    case idle
                    case loading
                    case success
                    case failure
                }

                enum LoadingCodingKeys: String, CodingKey {
                    case progress
                }

                enum SuccessCodingKeys: String, CodingKey {
                    case data
                }

                enum FailureCodingKeys: String, CodingKey {
                    case error
                    case retryCount
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    if container.allKeys.count != 1 {
                        throw DecodingError.dataCorrupted(
                            DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Expected exactly one key"
                            )
                        )
                    }

                    let key = container.allKeys.first!

                    switch key {
                    case .idle:
                        self = .idle
                    case .loading:
                        let nestedContainer = try container.nestedContainer(keyedBy: LoadingCodingKeys.self, forKey: .loading)
                        let progress = try nestedContainer.decode(Double.self, forKey: .progress)
                        self = .loading(progress: progress)
                    case .success:
                        let nestedContainer = try container.nestedContainer(keyedBy: SuccessCodingKeys.self, forKey: .success)
                        let data = try nestedContainer.decode(String.self, forKey: .data)
                        self = .success(data: data)
                    case .failure:
                        let nestedContainer = try container.nestedContainer(keyedBy: FailureCodingKeys.self, forKey: .failure)
                        let error = try nestedContainer.decode(String.self, forKey: .error)
                        let retryCount = try nestedContainer.decode(Int.self, forKey: .retryCount)
                        self = .failure(error: error, retryCount: retryCount)
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)

                    switch self {
                    case .idle:
                        _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .idle)
                    case .loading(let progress):
                        var nestedContainer = container.nestedContainer(keyedBy: LoadingCodingKeys.self, forKey: .loading)
                        try nestedContainer.encode(progress, forKey: .progress)
                    case .success(let data):
                        var nestedContainer = container.nestedContainer(keyedBy: SuccessCodingKeys.self, forKey: .success)
                        try nestedContainer.encode(data, forKey: .data)
                    case .failure(let error, let retryCount):
                        var nestedContainer = container.nestedContainer(keyedBy: FailureCodingKeys.self, forKey: .failure)
                        try nestedContainer.encode(error, forKey: .error)
                        try nestedContainer.encode(retryCount, forKey: .retryCount)
                    }
                }
            }

            extension LoadingState: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Associated values enum - 包含 Optional 參數")
    func testAssociatedValuesWithOptional() throws {
        assertMacroExpansion(
            """
            @Codable
            enum Response {
                case success(data: String, metadata: String?)
                case error(code: Int, message: String?)
            }
            """,
            expandedSource: """
            enum Response {
                case success(data: String, metadata: String?)
                case error(code: Int, message: String?)

                enum CodingKeys: String, CodingKey {
                    case success
                    case error
                }

                enum SuccessCodingKeys: String, CodingKey {
                    case data
                    case metadata
                }

                enum ErrorCodingKeys: String, CodingKey {
                    case code
                    case message
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    if container.allKeys.count != 1 {
                        throw DecodingError.dataCorrupted(
                            DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Expected exactly one key"
                            )
                        )
                    }

                    let key = container.allKeys.first!

                    switch key {
                    case .success:
                        let nestedContainer = try container.nestedContainer(keyedBy: SuccessCodingKeys.self, forKey: .success)
                        let data = try nestedContainer.decode(String.self, forKey: .data)
                        let metadata = try nestedContainer.decodeIfPresent(String.self, forKey: .metadata)
                        self = .success(data: data, metadata: metadata)
                    case .error:
                        let nestedContainer = try container.nestedContainer(keyedBy: ErrorCodingKeys.self, forKey: .error)
                        let code = try nestedContainer.decode(Int.self, forKey: .code)
                        let message = try nestedContainer.decodeIfPresent(String.self, forKey: .message)
                        self = .error(code: code, message: message)
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)

                    switch self {
                    case .success(let data, let metadata):
                        var nestedContainer = container.nestedContainer(keyedBy: SuccessCodingKeys.self, forKey: .success)
                        try nestedContainer.encode(data, forKey: .data)
                        try nestedContainer.encodeIfPresent(metadata, forKey: .metadata)
                    case .error(let code, let message):
                        var nestedContainer = container.nestedContainer(keyedBy: ErrorCodingKeys.self, forKey: .error)
                        try nestedContainer.encode(code, forKey: .code)
                        try nestedContainer.encodeIfPresent(message, forKey: .message)
                    }
                }
            }

            extension Response: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("Associated values enum - 混合有標籤和無標籤參數")
    func testMixedLabeledUnlabeledParameters() throws {
        assertMacroExpansion(
            """
            @Codable
            enum Data {
                case value(String)
                case pair(first: Int, String)
            }
            """,
            expandedSource: """
            enum Data {
                case value(String)
                case pair(first: Int, String)

                enum CodingKeys: String, CodingKey {
                    case value
                    case pair
                }

                enum ValueCodingKeys: String, CodingKey {
                    case _0
                }

                enum PairCodingKeys: String, CodingKey {
                    case first
                    case _1
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    if container.allKeys.count != 1 {
                        throw DecodingError.dataCorrupted(
                            DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Expected exactly one key"
                            )
                        )
                    }

                    let key = container.allKeys.first!

                    switch key {
                    case .value:
                        let nestedContainer = try container.nestedContainer(keyedBy: ValueCodingKeys.self, forKey: .value)
                        let _0 = try nestedContainer.decode(String.self, forKey: ._0)
                        self = .value(_0)
                    case .pair:
                        let nestedContainer = try container.nestedContainer(keyedBy: PairCodingKeys.self, forKey: .pair)
                        let first = try nestedContainer.decode(Int.self, forKey: .first)
                        let _1 = try nestedContainer.decode(String.self, forKey: ._1)
                        self = .pair(first: first, _1)
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)

                    switch self {
                    case .value(let _0):
                        var nestedContainer = container.nestedContainer(keyedBy: ValueCodingKeys.self, forKey: .value)
                        try nestedContainer.encode(_0, forKey: ._0)
                    case .pair(let first, let _1):
                        var nestedContainer = container.nestedContainer(keyedBy: PairCodingKeys.self, forKey: .pair)
                        try nestedContainer.encode(first, forKey: .first)
                        try nestedContainer.encode(_1, forKey: ._1)
                    }
                }
            }

            extension Data: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }
}
