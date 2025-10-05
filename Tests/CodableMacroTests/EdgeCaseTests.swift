import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import CodableMacroMacros
@testable import CodableMacro

/// 邊界案例和錯誤案例測試
struct EdgeCaseTests {

    @Test("邊界案例 - 單一屬性")
    func testSingleProperty() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SimpleId {
                let id: String
            }
            """,
            expandedSource: """
            struct SimpleId {
                let id: String

                enum CodingKeys: String, CodingKey {
                    case id
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                }
            }

            extension SimpleId: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - 空 struct")
    func testEmptyStruct() throws {
        assertMacroExpansion(
            """
            @Codable
            struct EmptyStruct {
            }
            """,
            expandedSource: """
            struct EmptyStruct {

                enum CodingKeys: String, CodingKey {
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                }
            }

            extension EmptyStruct: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("錯誤案例 - actor 類型不支援")
    func testActorNotSupported() throws {
        assertMacroExpansion(
            """
            @Codable
            actor Counter {
                var count: Int = 0
            }
            """,
            expandedSource: """
            actor Counter {
                var count: Int = 0
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Codable 只能應用於 struct 或 class", line: 1, column: 1)
            ],
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("錯誤案例 - protocol 不支援")
    func testProtocolNotSupported() throws {
        assertMacroExpansion(
            """
            @Codable
            protocol Identifiable {
                var id: String { get }
            }
            """,
            expandedSource: """
            protocol Identifiable {
                var id: String { get }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Codable 只能應用於 struct 或 class", line: 1, column: 1)
            ],
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - 全部屬性都是 Optional")
    func testAllOptionalProperties() throws {
        assertMacroExpansion(
            """
            @Codable
            struct OptionalData {
                let id: String?
                let name: String?
                let value: Int?
            }
            """,
            expandedSource: """
            struct OptionalData {
                let id: String?
                let name: String?
                let value: Int?

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                    case value
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decodeIfPresent(String.self, forKey: .id)
                    self.name = try container.decodeIfPresent(String.self, forKey: .name)
                    self.value = try container.decodeIfPresent(Int.self, forKey: .value)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encodeIfPresent(id, forKey: .id)
                    try container.encodeIfPresent(name, forKey: .name)
                    try container.encodeIfPresent(value, forKey: .value)
                }
            }

            extension OptionalData: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - 超長屬性名稱")
    func testVeryLongPropertyName() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Data {
                let thisIsAVeryLongPropertyNameThatExceedsNormalLengthExpectationsAndShouldStillWorkCorrectly: String
            }
            """,
            expandedSource: """
            struct Data {
                let thisIsAVeryLongPropertyNameThatExceedsNormalLengthExpectationsAndShouldStillWorkCorrectly: String

                enum CodingKeys: String, CodingKey {
                    case thisIsAVeryLongPropertyNameThatExceedsNormalLengthExpectationsAndShouldStillWorkCorrectly
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.thisIsAVeryLongPropertyNameThatExceedsNormalLengthExpectationsAndShouldStillWorkCorrectly = try container.decode(String.self, forKey: .thisIsAVeryLongPropertyNameThatExceedsNormalLengthExpectationsAndShouldStillWorkCorrectly)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(thisIsAVeryLongPropertyNameThatExceedsNormalLengthExpectationsAndShouldStillWorkCorrectly, forKey: .thisIsAVeryLongPropertyNameThatExceedsNormalLengthExpectationsAndShouldStillWorkCorrectly)
                }
            }

            extension Data: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - 特殊字元屬性名稱（底線）")
    func testPropertyNameWithUnderscore() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Config {
                let max_value: Int
                let min_value: Int
            }
            """,
            expandedSource: """
            struct Config {
                let max_value: Int
                let min_value: Int

                enum CodingKeys: String, CodingKey {
                    case max_value
                    case min_value
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.max_value = try container.decode(Int.self, forKey: .max_value)
                    self.min_value = try container.decode(Int.self, forKey: .min_value)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(max_value, forKey: .max_value)
                    try container.encode(min_value, forKey: .min_value)
                }
            }

            extension Config: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - 數字開頭的屬性名稱（使用反引號）")
    func testPropertyNameWithBackticks() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Response {
                let `return`: String
                let `class`: String
            }
            """,
            expandedSource: """
            struct Response {
                let `return`: String
                let `class`: String

                enum CodingKeys: String, CodingKey {
                    case `return`
                    case `class`
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.`return` = try container.decode(String.self, forKey: .`return`)
                    self.`class` = try container.decode(String.self, forKey: .`class`)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(`return`, forKey: .`return`)
                    try container.encode(`class`, forKey: .`class`)
                }
            }

            extension Response: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - 多種數字型別")
    func testVariousNumericTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Numbers {
                let int8Value: Int8
                let int16Value: Int16
                let int32Value: Int32
                let int64Value: Int64
                let uintValue: UInt
                let floatValue: Float
                let doubleValue: Double
            }
            """,
            expandedSource: """
            struct Numbers {
                let int8Value: Int8
                let int16Value: Int16
                let int32Value: Int32
                let int64Value: Int64
                let uintValue: UInt
                let floatValue: Float
                let doubleValue: Double

                enum CodingKeys: String, CodingKey {
                    case int8Value
                    case int16Value
                    case int32Value
                    case int64Value
                    case uintValue
                    case floatValue
                    case doubleValue
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.int8Value = try container.decode(Int8.self, forKey: .int8Value)
                    self.int16Value = try container.decode(Int16.self, forKey: .int16Value)
                    self.int32Value = try container.decode(Int32.self, forKey: .int32Value)
                    self.int64Value = try container.decode(Int64.self, forKey: .int64Value)
                    self.uintValue = try container.decode(UInt.self, forKey: .uintValue)
                    self.floatValue = try container.decode(Float.self, forKey: .floatValue)
                    self.doubleValue = try container.decode(Double.self, forKey: .doubleValue)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(int8Value, forKey: .int8Value)
                    try container.encode(int16Value, forKey: .int16Value)
                    try container.encode(int32Value, forKey: .int32Value)
                    try container.encode(int64Value, forKey: .int64Value)
                    try container.encode(uintValue, forKey: .uintValue)
                    try container.encode(floatValue, forKey: .floatValue)
                    try container.encode(doubleValue, forKey: .doubleValue)
                }
            }

            extension Numbers: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - 巢狀 Optional Collection")
    func testNestedOptionalCollections() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Complex {
                let nestedArrays: [[String]]?
                let nestedDicts: [[String: Int]]?
                let optionalArrayOfOptionals: [String?]?
            }
            """,
            expandedSource: """
            struct Complex {
                let nestedArrays: [[String]]?
                let nestedDicts: [[String: Int]]?
                let optionalArrayOfOptionals: [String?]?

                enum CodingKeys: String, CodingKey {
                    case nestedArrays
                    case nestedDicts
                    case optionalArrayOfOptionals
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.nestedArrays = try container.decodeIfPresent([[String]].self, forKey: .nestedArrays)
                    self.nestedDicts = try container.decodeIfPresent([[String: Int]].self, forKey: .nestedDicts)
                    self.optionalArrayOfOptionals = try container.decodeIfPresent([String?].self, forKey: .optionalArrayOfOptionals)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encodeIfPresent(nestedArrays, forKey: .nestedArrays)
                    try container.encodeIfPresent(nestedDicts, forKey: .nestedDicts)
                    try container.encodeIfPresent(optionalArrayOfOptionals, forKey: .optionalArrayOfOptionals)
                }
            }

            extension Complex: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - Set 和 Tuple 型別")
    func testSetAndTupleTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Collections {
                let uniqueValues: Set<String>
                let pair: (Int, String)
            }
            """,
            expandedSource: """
            struct Collections {
                let uniqueValues: Set<String>
                let pair: (Int, String)

                enum CodingKeys: String, CodingKey {
                    case uniqueValues
                    case pair
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.uniqueValues = try container.decode(Set<String>.self, forKey: .uniqueValues)
                    self.pair = try container.decode((Int, String).self, forKey: .pair)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(uniqueValues, forKey: .uniqueValues)
                    try container.encode(pair, forKey: .pair)
                }
            }

            extension Collections: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - 泛型型別")
    func testGenericTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Wrapper<T> {
                let value: T
                let items: [T]
            }
            """,
            expandedSource: """
            struct Wrapper<T> {
                let value: T
                let items: [T]

                enum CodingKeys: String, CodingKey {
                    case value
                    case items
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.value = try container.decode(T.self, forKey: .value)
                    self.items = try container.decode([T].self, forKey: .items)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(value, forKey: .value)
                    try container.encode(items, forKey: .items)
                }
            }

            extension Wrapper: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - final class")
    func testFinalClass() throws {
        assertMacroExpansion(
            """
            @Codable
            final class FinalUser {
                let id: String
                let name: String
            }
            """,
            expandedSource: """
            final class FinalUser {
                let id: String
                let name: String

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                }

                required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(name, forKey: .name)
                }
            }

            extension FinalUser: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - class 混合 let 和 var")
    func testClassWithMixedLetVar() throws {
        assertMacroExpansion(
            """
            @Codable
            class MutablePerson {
                let id: String
                var name: String
                var age: Int
            }
            """,
            expandedSource: """
            class MutablePerson {
                let id: String
                var name: String
                var age: Int

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                    case age
                }

                required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.name = try container.decode(String.self, forKey: .name)
                    self.age = try container.decode(Int.self, forKey: .age)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(name, forKey: .name)
                    try container.encode(age, forKey: .age)
                }
            }

            extension MutablePerson: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - 深層巢狀 Optional")
    func testDeeplyNestedOptionals() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Nested {
                let value: String???
            }
            """,
            expandedSource: """
            struct Nested {
                let value: String???

                enum CodingKeys: String, CodingKey {
                    case value
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.value = try container.decodeIfPresent(String??.self, forKey: .value)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encodeIfPresent(value, forKey: .value)
                }
            }

            extension Nested: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - Optional 巢狀 Array")
    func testOptionalNestedArray() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Data {
                let items: [[[String]]]?
            }
            """,
            expandedSource: """
            struct Data {
                let items: [[[String]]]?

                enum CodingKeys: String, CodingKey {
                    case items
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.items = try container.decodeIfPresent([[[String]]].self, forKey: .items)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encodeIfPresent(items, forKey: .items)
                }
            }

            extension Data: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - 複雜的泛型型別組合")
    func testComplexGenericTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            struct ComplexGeneric {
                let dict: [String: [Int: String]]
                let optionalDict: [String: String?]?
            }
            """,
            expandedSource: """
            struct ComplexGeneric {
                let dict: [String: [Int: String]]
                let optionalDict: [String: String?]?

                enum CodingKeys: String, CodingKey {
                    case dict
                    case optionalDict
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.dict = try container.decode([String: [Int: String]].self, forKey: .dict)
                    self.optionalDict = try container.decodeIfPresent([String: String?].self, forKey: .optionalDict)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(dict, forKey: .dict)
                    try container.encodeIfPresent(optionalDict, forKey: .optionalDict)
                }
            }

            extension ComplexGeneric: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - 不同 access level 的屬性")
    func testDifferentAccessLevels() throws {
        assertMacroExpansion(
            """
            @Codable
            public struct PublicData {
                public let id: String
                internal let name: String
                let value: Int
            }
            """,
            expandedSource: """
            public struct PublicData {
                public let id: String
                internal let name: String
                let value: Int

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                    case value
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    self.name = try container.decode(String.self, forKey: .name)
                    self.value = try container.decode(Int.self, forKey: .value)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(name, forKey: .name)
                    try container.encode(value, forKey: .value)
                }
            }

            extension PublicData: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - 所有 Swift 基本數值型別")
    func testAllSwiftNumericTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            struct AllNumeric {
                let int: Int
                let int8: Int8
                let int16: Int16
                let int32: Int32
                let int64: Int64
                let uint: UInt
                let uint8: UInt8
                let uint16: UInt16
                let uint32: UInt32
                let uint64: UInt64
                let float: Float
                let double: Double
                let cgFloat: CGFloat
            }
            """,
            expandedSource: """
            struct AllNumeric {
                let int: Int
                let int8: Int8
                let int16: Int16
                let int32: Int32
                let int64: Int64
                let uint: UInt
                let uint8: UInt8
                let uint16: UInt16
                let uint32: UInt32
                let uint64: UInt64
                let float: Float
                let double: Double
                let cgFloat: CGFloat

                enum CodingKeys: String, CodingKey {
                    case int
                    case int8
                    case int16
                    case int32
                    case int64
                    case uint
                    case uint8
                    case uint16
                    case uint32
                    case uint64
                    case float
                    case double
                    case cgFloat
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.int = try container.decode(Int.self, forKey: .int)
                    self.int8 = try container.decode(Int8.self, forKey: .int8)
                    self.int16 = try container.decode(Int16.self, forKey: .int16)
                    self.int32 = try container.decode(Int32.self, forKey: .int32)
                    self.int64 = try container.decode(Int64.self, forKey: .int64)
                    self.uint = try container.decode(UInt.self, forKey: .uint)
                    self.uint8 = try container.decode(UInt8.self, forKey: .uint8)
                    self.uint16 = try container.decode(UInt16.self, forKey: .uint16)
                    self.uint32 = try container.decode(UInt32.self, forKey: .uint32)
                    self.uint64 = try container.decode(UInt64.self, forKey: .uint64)
                    self.float = try container.decode(Float.self, forKey: .float)
                    self.double = try container.decode(Double.self, forKey: .double)
                    self.cgFloat = try container.decode(CGFloat.self, forKey: .cgFloat)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(int, forKey: .int)
                    try container.encode(int8, forKey: .int8)
                    try container.encode(int16, forKey: .int16)
                    try container.encode(int32, forKey: .int32)
                    try container.encode(int64, forKey: .int64)
                    try container.encode(uint, forKey: .uint)
                    try container.encode(uint8, forKey: .uint8)
                    try container.encode(uint16, forKey: .uint16)
                    try container.encode(uint32, forKey: .uint32)
                    try container.encode(uint64, forKey: .uint64)
                    try container.encode(float, forKey: .float)
                    try container.encode(double, forKey: .double)
                    try container.encode(cgFloat, forKey: .cgFloat)
                }
            }

            extension AllNumeric: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - URL 和 UUID 型別")
    func testURLandUUIDTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Resource {
                let id: UUID
                let url: URL
                let optionalURL: URL?
            }
            """,
            expandedSource: """
            struct Resource {
                let id: UUID
                let url: URL
                let optionalURL: URL?

                enum CodingKeys: String, CodingKey {
                    case id
                    case url
                    case optionalURL
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(UUID.self, forKey: .id)
                    self.url = try container.decode(URL.self, forKey: .url)
                    self.optionalURL = try container.decodeIfPresent(URL.self, forKey: .optionalURL)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(url, forKey: .url)
                    try container.encodeIfPresent(optionalURL, forKey: .optionalURL)
                }
            }

            extension Resource: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }

    @Test("邊界案例 - Data 和 Date 型別組合")
    func testDataAndDateTypes() throws {
        assertMacroExpansion(
            """
            @Codable
            struct TimedData {
                let content: Data
                let created: Date
                let modified: Date?
                let blob: Data?
            }
            """,
            expandedSource: """
            struct TimedData {
                let content: Data
                let created: Date
                let modified: Date?
                let blob: Data?

                enum CodingKeys: String, CodingKey {
                    case content
                    case created
                    case modified
                    case blob
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.content = try container.decode(Data.self, forKey: .content)
                    self.created = try container.decode(Date.self, forKey: .created)
                    self.modified = try container.decodeIfPresent(Date.self, forKey: .modified)
                    self.blob = try container.decodeIfPresent(Data.self, forKey: .blob)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(content, forKey: .content)
                    try container.encode(created, forKey: .created)
                    try container.encodeIfPresent(modified, forKey: .modified)
                    try container.encodeIfPresent(blob, forKey: .blob)
                }
            }

            extension TimedData: Codable {
            }
            """,
            macros: ["Codable": CodableMacro.self]
        )
    }
}
