# Makefile

# -- linting --------------------------------------------------------------------------------------

# Runs Clippy with configs
.PHONY: clippy
clippy:
	cargo clippy --workspace --all-targets --all-features -- -D warnings

# Runs Fix with configs
.PHONY: fix
fix:
	cargo +nightly fix --allow-staged --allow-dirty --all-targets --all-features

# Runs Format using nightly toolchain
.PHONY: format
format:
	cargo +nightly fmt --all

# Runs Format using nightly toolchain but only in check mode
.PHONY: format-check
format-check:
	cargo +nightly fmt --all --check

# Runs all linting tasks at once (Clippy, fixing, formatting)
.PHONY: lint
lint:
	$(MAKE) -j3 format fix clippy

# --- docs ----------------------------------------------------------------------------------------

# Generates & checks documentation
.PHONY: doc
doc:
	RUSTDOCFLAGS="-D warnings" cargo doc --all-features --keep-going --release

# Serves documentation site
.PHONY: doc-serve
doc-serve:
	./scripts/serve-doc-site.sh

# --- testing -------------------------------------------------------------------------------------

# Run default tests excluding `prove`
.PHONY: test
test:
	RUSTFLAGS="-C debug-assertions" cargo nextest run --profile default --cargo-profile test-release --features concurrent,testing --filter-expr "not test(prove)"

# Run `prove` tests (tests which use the Miden prover)
.PHONY: test-prove
test-prove:
	RUSTFLAGS="-C debug-assertions" cargo nextest run --profile prove --cargo-profile test-release --features concurrent,testing --filter-expr "test(prove)"

# Run all tests
.PHONY: test-all
test-all:
	RUSTFLAGS="-C debug-assertions" $(MAKE) -j2 test test-prove

# Run default tests excluding `prove` with CI configurations
.PHONY: ci-test
ci-test-default:
	cargo nextest run --profile ci-default --cargo-profile test-release --features concurrent,testing --filter-expr "not test(prove)"

# Run `prove` tests (tests which use the Miden prover) with CI configurations
.PHONY: ci-test-prove
ci-test-prove:
	cargo nextest run --profile ci-prove --cargo-profile test-release --features concurrent,testing --filter-expr "test(prove)"

# Run all tests with CI configurations
.PHONY: ci-test-all
ci-test-all:
	RUSTFLAGS="-C debug-assertions" $(MAKE) -j2 ci-test ci-test-prove

# --- building ------------------------------------------------------------------------------------

# By default we should build in release mode
.PHONY: build
build:
	cargo build --release

# Build without the standard library
.PHONY: build-no-std
build-no-std:
	cargo build --no-default-features --target wasm32-unknown-unknown --workspace --exclude miden-mock --exclude miden-bench-tx

# --- benchmarking --------------------------------------------------------------------------------

# Run transaction benchmarks
.PHONY: bench-tx
bench-tx:
	cargo run --bin bench-tx

# --- utilities -----------------------------------------------------------------------------------

# Watch for changes and rebuild
.PHONY: watch
watch:
	cargo watch -w miden-lib/asm -x build