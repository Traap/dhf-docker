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

# DHF paths baked into runtime image
AMBER       := /soup/amber
AUTODOC     := /soup/autodoc
DOCBLD      := /soup/docbld
EXPORTDIR   := /exports
NEWDOC      := /soup/newdoc
TLCDIR      := /soup/tlc-article

AMBER_DOC   ?= DHF/Samples/90000
AMBER_ARGS  ?=

# Docker BuildKit is always on
export DOCKER_BUILDKIT=1

# Compose file
DOCKER_COMPOSE := docker-compose.arch.yml
SERVICE := dhf-builder

# Detect Git Bash path translation
ifeq ($(shell uname -o 2>/dev/null),Msys)
  WORKSPACE = //workspace
else
  WORKSPACE = /workspace
endif

# -------------------------------------------------------------------------- }}}
# {{{ 🛡 Guard: require running container

define REQUIRE_CONTAINER_RUNNING
@docker compose -f $(DOCKER_COMPOSE) ps --status running | grep -q $(SERVICE) || \
  (echo "ERROR: $(SERVICE) container is not running."; \
   echo "Run: make arch.up"; \
   exit 1)
endef

# -------------------------------------------------------------------------- }}}
# {{{ 🧩 Meta Targets

arch.all: arch.build arch.up ## Build and start arch container.

# -------------------------------------------------------------------------- }}}
# {{{ 🧱 Build targets

arch.build-base: ## 🧱 Build slow base image (dhf-base)
	docker build -f Dockerfile.base -t dhf-base:latest .. > base.log 2>&1

arch.build: ## 🚀 Build runtime layer (Amber + repos)
	docker compose --progress=plain -f $(DOCKER_COMPOSE) build > arch.log 2>&1

arch.rebuild: ## ♻ Rebuild runtime layer without using cache
	docker compose --progress=plain -f $(DOCKER_COMPOSE) build --no-cache > arch.log 2>&1

# -------------------------------------------------------------------------- }}}
# {{{ ⚡ Container lifecycle

arch.up: ## ▶ Start long-lived DHF builder container
	docker compose -f $(DOCKER_COMPOSE) up -d $(SERVICE)

arch.down: ## ⏹ Stop DHF builder container
	docker compose -f $(DOCKER_COMPOSE) down

arch.restart: ## 🔄 Restart DHF builder container
	docker compose -f $(DOCKER_COMPOSE) down
	docker compose -f $(DOCKER_COMPOSE) up -d $(SERVICE)

arch.ps: ## 📋 Show container status
	docker compose -f $(DOCKER_COMPOSE) ps

arch.shell: ## 🐚 Shell into running container
	$(call REQUIRE_CONTAINER_RUNNING)
	docker compose -f $(DOCKER_COMPOSE) exec $(SERVICE) /bin/bash

# -------------------------------------------------------------------------- }}}
# {{{ 🧪 Container tests.

arch.test: ## 🧪 Verify Amber, Ruby, Bundler, and Python in running container
	$(call REQUIRE_CONTAINER_RUNNING)
	docker compose -f $(DOCKER_COMPOSE) exec \
	  $(SERVICE) \
	  bash -lc "\
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

define DOCKER_DOCBLD_RAKE
$(call REQUIRE_CONTAINER_RUNNING)
docker compose -f $(DOCKER_COMPOSE) exec \
  $(SERVICE) \
  bash -lc "cd $(WORKSPACE) && rake --rakefile $(DOCBLD)/Rakefile $(1)"
endef

dhf.clobber: ## 🧹 Remove build artifacts
	$(call DOCKER_DOCBLD_RAKE,clobber)

dhf.copy_files: ## 📦 Copy distribution files
	$(call DOCKER_DOCBLD_RAKE,copy_files)

dhf.docx: ## 🧾 Build DOCX
	$(call DOCKER_DOCBLD_RAKE,docx)

dhf.deploy: ## 🚀 Full DHF pipeline: clean → build → copy → clobber
	$(call DOCKER_DOCBLD_RAKE,deploy)

dhf.list_files: ## 📝 List all .texx files
	$(call DOCKER_DOCBLD_RAKE,list_files)

dhf.remove_distdir: ## 🗑 Remove dist directory
	$(call DOCKER_DOCBLD_RAKE,remove_distdir)

dhf.texx: ## 🧾 Build PDFs from .texx
	$(call DOCKER_DOCBLD_RAKE,texx)

# -------------------------------------------------------------------------- }}}
# {{{ 🧼 Amber Commands

amber.run: ## 🧪 Run Amber against a single document factory
	$(call REQUIRE_CONTAINER_RUNNING)
	docker compose -f $(DOCKER_COMPOSE) exec \
	  -w $(WORKSPACE)/$(AMBER_DOC) \
	  $(SERVICE) \
	  bash -lc "amber $(AMBER_ARGS)"

amber.debug: ## 🔍 Echo Amber exec command
	$(call REQUIRE_CONTAINER_RUNNING)
	@echo docker compose -f $(DOCKER_COMPOSE) exec \
	  -w $(WORKSPACE)/$(AMBER_DOC) \
	  $(SERVICE) \
	  bash -lc \"amber $(AMBER_ARGS)\"

# -------------------------------------------------------------------------- }}}
# {{{ 🧼 Cleanup

clean: ## 🧼 Stop container and remove volumes/images
	docker compose -f $(DOCKER_COMPOSE) down --volumes --remove-orphans

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
	amber.debug \
	amber.run \
	arch.all \
	arch.build \
	arch.build-base \
	arch.down \
	arch.ps \
	arch.rebuild \
	arch.restart \
	arch.run \
	arch.shell \
	arch.test \
	arch.up \
	dhf.clobber \
	dhf.copy_files \
	dhf.deploy \
	dhf.docx \
	dhf.list_files \
	dhf.remove_distdir \
	dhf.texx \
	clean \
	prune \
	arch.help

# -------------------------------------------------------------------------- }}}
