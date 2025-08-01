.PHONY: build clean

build:
	swift build -c release
	@if [ "$$(uname)" = "Darwin" ]; then \
		for dylib in .build/release/*.dylib; do \
			if [ -f "$$dylib" ]; then \
				so="$${dylib%.dylib}.so"; \
				rm -f "$$so"; \
				ln "$$dylib" "$$so"; \
				echo "Created link: $$so"; \
			fi \
		done \
	fi

clean:
	swift package clean
	rm -f .build/release/*.so