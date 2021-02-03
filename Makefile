all: tools dependencies xcodeproj-httpservermock templates
.PHONY : tools

tools:
		@echo "⚙️  Installing tools..."
		@brew list swiftlint &>/dev/null || brew install swiftlint
		@echo "OK 👌"

templates:
		@echo "⚙️  Installing Xcode templates..."
		./tools/xcode-templates/install-xcode-templates.sh
		@echo "OK 👌"

bump:
		@read -p "Enter version number: " version;  \
		sed "s/__DATADOG_VERSION__/$$version/g" DatadogSDKBridge.podspec.src > DatadogSDKBridge.podspec; \
		git add . ; \
		git commit -m "Bumped version to $$version"; \
		echo Bumped version to $$version

ship:
		pod spec lint --allow-warnings DatadogSDKBridge.podspec
		pod trunk push --allow-warnings DatadogSDKBridge.podspec
