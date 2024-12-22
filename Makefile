
setup:
	@cd .git/hooks; ln -s -f ../../scripts/git-hooks/* ./

.git/hooks/pre-commit: setup


# used as pre-commit
lint-git:
	@files=$$(git diff --name-only --cached | grep  -E '\.go$$' | xargs -r gofmt -l); if [ -n "$$files" ]; then echo $$files;  exit 101; fi
	@git diff --name-only --cached | grep  -E '\.md$$' | xargs -r markdownlint-cli2

# lint changed files
lint:
	@files=$$(git diff --name-only | grep  -E '\.go$$' | xargs -r gofmt -l); if [ -n "$$files" ]; then echo $$files;  exit 101; fi
	@git diff --name-only | grep  -E '\.md$$' | xargs -r markdownlint-cli2

lint-all:
	@markdownlint-cli2 **/*.md


.PHONY: setup
.PHONY: lint lint-all
