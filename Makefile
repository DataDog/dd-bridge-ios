all: tools dependencies
.PHONY : tools

tools:
		@echo "⚙️  Installing tools..."
		@brew list swiftlint &>/dev/null || brew install swiftlint
		@echo "OK 👌"

dependencies:
		cd Example && pod install

bump:
		@read -p "Enter version number: " version;  \
		sed "s/__DATADOG_VERSION__/$$version/g" DatadogSDKBridge.podspec.src > DatadogSDKBridge.podspec; \
		git add . ; \
		git commit -m "Bumped version to $$version"; \
		echo Bumped version to $$version

ship:
		pod trunk me
		pod spec lint --allow-warnings DatadogSDKBridge.podspec
		pod trunk push --allow-warnings DatadogSDKBridge.podspec
