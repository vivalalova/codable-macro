import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
import CodableMacroMacros

struct NestedKeyPathTests {
    let testMacros: [String: Macro.Type] = [
        "Codable": CodableMacro.self,
        "CodingKey": CodingKeyMacro.self
    ]

    @Test("基本巢狀路徑 - 兩層")
    func testBasicNestedPath() throws {
        assertMacroExpansion(
            """
            @Codable
            struct UserInfo {
                @CodingKey("user.name")
                let userName: String
            }
            """,
            expandedSource: """
            struct UserInfo {
                let userName: String

                enum CodingKeys: String, CodingKey {
                }

                init(from decoder: Decoder) throws {
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        self.userName = try container1.decode(String.self, forKey: DynamicKey(stringValue: "name"))
                    }
                }

                func encode(to encoder: Encoder) throws {
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        try container1.encode(userName, forKey: DynamicKey(stringValue: "name"))
                    }
                }

                static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw CodableMacro.DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                    try array.map { instance in
                        try instance.toDict()
                    }
                }
            }

            extension UserInfo: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("深層巢狀路徑 - 三層")
    func testDeepNestedPath() throws {
        assertMacroExpansion(
            """
            @Codable
            struct APIResponse {
                @CodingKey("data.user.name")
                let name: String
            }
            """,
            expandedSource: """
            struct APIResponse {
                let name: String

                enum CodingKeys: String, CodingKey {
                }

                init(from decoder: Decoder) throws {
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        let container2 = try container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        self.name = try container2.decode(String.self, forKey: DynamicKey(stringValue: "name"))
                    }
                }

                func encode(to encoder: Encoder) throws {
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "data"))
                        var container2 = container1.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        try container2.encode(name, forKey: DynamicKey(stringValue: "name"))
                    }
                }

                static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw CodableMacro.DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                    try array.map { instance in
                        try instance.toDict()
                    }
                }
            }

            extension APIResponse: Codable {
            }
            """,
            macros: testMacros
        )
    }

    @Test("混合簡單和巢狀屬性")
    func testMixedSimpleAndNested() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Profile {
                let id: String
                @CodingKey("user.name")
                let userName: String
            }
            """,
            expandedSource: """
            struct Profile {
                let id: String
                let userName: String

                enum CodingKeys: String, CodingKey {
                    case id
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(String.self, forKey: .id)
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        let rootContainer = try decoder.container(keyedBy: DynamicKey.self)
                        let container1 = try rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        self.userName = try container1.decode(String.self, forKey: DynamicKey(stringValue: "name"))
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    do {
                        struct DynamicKey: CodingKey {
                            var stringValue: String
                            var intValue: Int? { nil }
                            init(stringValue: String) { self.stringValue = stringValue }
                            init?(intValue: Int) { nil }
                        }
                        var rootContainer = encoder.container(keyedBy: DynamicKey.self)
                        var container1 = rootContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: "user"))
                        try container1.encode(userName, forKey: DynamicKey(stringValue: "name"))
                    }
                }

                static func fromDict(_ dict: [String: Any]) throws -> Self {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    return try decoder.decode(Self.self, from: jsonData)
                }

                static func fromDictArray(_ array: [[String: Any]]) throws -> [Self] {
                    try array.map { dict in
                        try fromDict(dict)
                    }
                }

                func toDict() throws -> [String: Any] {
                    let encoder = JSONEncoder()
                    let jsonData = try encoder.encode(self)
                    guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        throw CodableMacro.DictConversionError.invalidDictionaryStructure
                    }
                    return dict
                }

                static func toDictArray(_ array: [Self]) throws -> [[String: Any]] {
                    try array.map { instance in
                        try instance.toDict()
                    }
                }
            }

            extension Profile: Codable {
            }
            """,
            macros: testMacros
        )
    }
}
