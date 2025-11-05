.PHONY: build test clean release install help

# 預設目標
.DEFAULT_GOAL := help

# 顏色定義
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

help: ## 顯示此幫助訊息
	@echo "$(CYAN)Available targets:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'

build: ## 建置專案 (Debug 模式)
	@echo "$(CYAN)Building project...$(RESET)"
	@swift build

release: ## 建置專案 (Release 模式)
	@echo "$(CYAN)Building project in release mode...$(RESET)"
	@swift build -c release

test: ## 執行所有測試
	@echo "$(CYAN)Running tests...$(RESET)"
	@swift test

test-verbose: ## 執行測試 (詳細輸出)
	@echo "$(CYAN)Running tests with verbose output...$(RESET)"
	@swift test -v

test-filter: ## 執行特定測試 (使用 FILTER 變數)
	@echo "$(CYAN)Running filtered tests: $(FILTER)$(RESET)"
	@swift test --filter $(FILTER)

test-coverage: ## 執行測試並生成覆蓋率報告 (Linux)
	@echo "$(CYAN)Running tests with coverage...$(RESET)"
	@swift test --enable-code-coverage

clean: ## 清理建置產物
	@echo "$(YELLOW)Cleaning build artifacts...$(RESET)"
	@swift package clean

reset: ## 重置套件快取
	@echo "$(YELLOW)Resetting package cache...$(RESET)"
	@swift package reset

update: ## 更新依賴套件
	@echo "$(CYAN)Updating dependencies...$(RESET)"
	@swift package update

resolve: ## 解析依賴套件
	@echo "$(CYAN)Resolving dependencies...$(RESET)"
	@swift package resolve

xcode: ## 生成 Xcode 專案 (macOS)
	@echo "$(CYAN)Generating Xcode project...$(RESET)"
	@swift package generate-xcodeproj

format: ## 格式化程式碼 (需要 swift-format)
	@echo "$(CYAN)Formatting code...$(RESET)"
	@if command -v swift-format >/dev/null 2>&1; then \
		find Sources Tests -name "*.swift" -exec swift-format -i {} \; ; \
		echo "$(GREEN)Code formatted successfully$(RESET)"; \
	else \
		echo "$(RED)swift-format not found. Install with: brew install swift-format$(RESET)"; \
	fi

lint: ## 檢查程式碼風格 (需要 swiftlint)
	@echo "$(CYAN)Linting code...$(RESET)"
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
	else \
		echo "$(RED)swiftlint not found. Install with: brew install swiftlint$(RESET)"; \
	fi

validate: build test ## 建置並測試
	@echo "$(GREEN)Validation complete!$(RESET)"

ci: clean build test ## CI 流程: 清理、建置、測試
	@echo "$(GREEN)CI pipeline complete!$(RESET)"

install-tools: ## 安裝開發工具 (macOS)
	@echo "$(CYAN)Installing development tools...$(RESET)"
	@if command -v brew >/dev/null 2>&1; then \
		brew install swift-format swiftlint; \
		echo "$(GREEN)Tools installed successfully$(RESET)"; \
	else \
		echo "$(RED)Homebrew not found. Please install from https://brew.sh$(RESET)"; \
	fi

# 測試快捷方式
test-complex: ## 執行 ComplexUseCaseTests
	@$(MAKE) test-filter FILTER=ComplexUseCaseTests

test-advanced: ## 執行 AdvancedComplexTests
	@$(MAKE) test-filter FILTER=AdvancedComplexTests

test-basic: ## 執行 BasicCodableTests
	@$(MAKE) test-filter FILTER=BasicCodableTests

test-transform: ## 執行 TransformTests
	@$(MAKE) test-filter FILTER=TransformTests

# 開發便捷命令
dev: ## 開發模式: 建置並監看變更
	@echo "$(CYAN)Starting development mode...$(RESET)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(RESET)"
	@while true; do \
		swift build && echo "$(GREEN)Build successful$(RESET)"; \
		sleep 2; \
	done

version: ## 顯示 Swift 版本
	@swift --version

info: ## 顯示專案資訊
	@echo "$(CYAN)Project Information:$(RESET)"
	@echo "  Name: CodableMacro"
	@echo "  Swift Version: 6.1+"
	@echo "  Build Directory: .build"
	@swift package describe

# Docker 相關
docker-build: ## 建置 Docker 映像
	@echo "$(CYAN)Building Docker image...$(RESET)"
	@docker build -t codable-macro:latest -f .devcontainer/Dockerfile .

docker-test: ## 在 Docker 容器中執行測試
	@echo "$(CYAN)Running tests in Docker...$(RESET)"
	@docker run --rm -v $(PWD):/workspace codable-macro:latest swift test
