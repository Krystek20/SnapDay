.PHONY: check test validate

check:
	./scripts/validate.sh quick

test:
	./scripts/validate.sh test

validate:
	./scripts/validate.sh full

