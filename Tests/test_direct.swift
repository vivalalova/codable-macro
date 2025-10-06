import CodableMacro

@Codable
struct ToolResultContent: Equatable, Hashable {
    @CodingKey("tool_use_id")
    let toolUseId: String
    let content: String
    @CodingKey("is_error")
    var isError: Bool = false
}

let test = ToolResultContent(toolUseId: "123", content: "test", isError: true)
print(test)
