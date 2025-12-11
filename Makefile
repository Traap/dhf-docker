# {{{ 🐳 Makefile — DHF Builder Docker Targets (Arch & Ubuntu)
#
# Cleaned up and optimized for split-base architecture:
#   - arch.build-base     → build slow TeXLive+Pandoc foundation
#   - arch.build          → build runtime layer
#   - arch.rebuild        → rebuild runtime layer without cache
#   - arch.test           → verify Amber + Ruby + Bundler in runtime container
#
# -------------------------------------------------------------------------- }}}
# {{{ 🔧 Base names and configuration

IMAGE_NAME := dhf-builder
REGISTRY   ?=
TAG        := latest

# DHF paths baked into runtime image
AMBER       := /soup/amber
AUTODOC     := /soup/autodoc
DOCBLD      := /soup/docbld
EXPORTDIR   := /exports
NEWDOC      := /soup/newdoc
TLCDIR      := /soup/tlc-article

# Docker BuildKit is always on
export DOCKER_BUILDKIT=1

# Compose file
DOCKER_COMPOSE_ARCH := docker-compose.arch.yml

# Detect Git Bash path translation
ifeq ($(shell uname -o 2>/dev/null),Msys)
  WORKDIR = //workspace
else
  WORKDIR = /workspace
endif

# -------------------------------------------------------------------------- }}}
# {{{ 🧩 Meta Targets

arch.all: arch.build arch.run ## Build + run Arch container end-to-end

# -------------------------------------------------------------------------- }}}
# {{{ 🧱 Base Build Targets (TeXLive + Pandoc)

arch.build-base: ## 🧱 Build slow base image (dhf-base)
	docker build -f Dockerfile.base -t dhf-base:latest .. > base.log 2>&1

# -------------------------------------------------------------------------- }}}
# {{{ ⚡ Runtime Build Targets (Fast)

arch.build: ## 🚀 Build runtime layer (Amber + repos)
	docker compose --progress=plain -f $(DOCKER_COMPOSE_ARCH) build > arch.log 2>&1

arch.rebuild: ## ♻ Rebuild runtime layer without using cache
	docker compose --progress=plain -f $(DOCKER_COMPOSE_ARCH) build --no-cache > arch.log 2>&1

arch.run: ## ▶ Run full document build inside Arch container
	docker compose -f $(DOCKER_COMPOSE_ARCH) up --abort-on-container-exit

arch.up: ## ▶ Start container in background
	docker compose -f $(DOCKER_COMPOSE_ARCH) up -d dhf-builder

arch.down: ## 🧹 Stop and remove Arch container
	docker compose -f $(DOCKER_COMPOSE_ARCH) down

arch.shell: ## 🐚 Enter interactive shell inside the runtime container
	docker compose -f $(DOCKER_COMPOSE_ARCH) exec dhf-builder /bin/bash

# -------------------------------------------------------------------------- }}}
# {{{ 🧪 Runtime Tests (Amber, Ruby, Bundler)

arch.test: ## 🧪 Verify Amber, Ruby, and Bundler are correctly installed in runtime
	docker compose -f $(DOCKER_COMPOSE_ARCH) run --rm --entrypoint "" dhf-builder bash -lc "\
	  set -e ; \
	  echo 'Checking Ruby:' && ruby --version && \
	  echo 'Checking gem:' && gem --version && \
	  echo 'Checking Bundler:' && bundler --version && \
	  echo 'Checking Python:' && python --version && \
	  echo 'Checking Amber:' && bundle exec amber --version && \
	  echo 'Checking Amber --help:' && bundle exec amber --help \
	"

# -------------------------------------------------------------------------- }}}
# {{{ 🧬 DHF Document Build Targets

define DOCKER_DOCBLD_RAKE_CMD
docker compose -f $(DOCKER_COMPOSE_ARCH) exec \
  dhf-builder \
  bash -lc "cd /workspace && rake --rakefile /soup/docbld/Rakefile $(1)"
endef

dhf.deploy: ## 🚀 Full DHF pipeline: clean → build → copy → clobber
	$(call DOCKER_DOCBLD_RAKE_CMD,deploy)

dhf.list_files: ## 📝 List all .texx files
	$(call DOCKER_DOCBLD_RAKE_CMD,list_files)

dhf.texx: ## 🧾 Build PDFs from .texx
	$(call DOCKER_DOCBLD_RAKE_CMD,texx)

dhf.docx: ## 🧾 Build DOCX
	$(call DOCKER_DOCBLD_RAKE_CMD,docx)

dhf.clobber: ## 🧹 Remove build artifacts
	$(call DOCKER_DOCBLD_RAKE_CMD,clobber)

dhf.copy_files: ## 📦 Copy distribution files
	$(call DOCKER_DOCBLD_RAKE_CMD,copy_files)

dhf.remove_distdir: ## 🗑 Remove dist directory
	$(call DOCKER_DOCBLD_RAKE_CMD,remove_distdir)

# -------------------------------------------------------------------------- }}}
# {{{ 🧼 Cleanup

clean: ## 🧼 Cleanup containers, images, volumes
	docker compose -f $(DOCKER_COMPOSE_ARCH) down --rmi local --volumes --remove-orphans

prune: ## 🪓 Full Docker prune
	docker system prune -af

# -------------------------------------------------------------------------- }}}
# {{{ 🆘 Help

arch.help: ## 📚 Show this help message
	@echo "📌 DHF Builder Makefile — Docker build & testing"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'

win.help: ## 📚 Show this help message
	@echo "DHF Builder Makefile - Docker build & testing"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_./%-]+:.*## ' $(MAKEFILE_LIST) | sort | \
	awk -F ':.*## ' '{printf "  %-25s %s\n", $$1, $$2}'

# -------------------------------------------------------------------------- }}}
# {{{ 📝 PHONY

.PHONY: \
	arch.all \
	arch.build-base \
	arch.build \
	arch.rebuild \
	arch.run \
	arch.up \
	arch.down \
	arch.shell \
	arch.test \
	dhf.deploy \
	dhf.list_files \
	dhf.texx \
	dhf.docx \
	dhf.clobber \
	dhf.copy_files \
	dhf.remove_distdir \
	clean \
	prune \
	arch.help

# -------------------------------------------------------------------------- }}}
