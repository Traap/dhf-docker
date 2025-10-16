# {{{ 🐳 Makefile — DHF Builder Docker Targets (Arch & Ubuntu)
#
# -------------------------------------------------------------------------- }}}
# {{{ 🔧 Base names and configuration

# DHF defaults DHF defaults
AMBER       := /opt/dhf/repos/amber
AUTODOC     := /opt/dhf/repos/autodoc
DOCBLD      := /opt/dhf/repos/docbld
DOCKER_RAKE := docker compose run --rm -w /opt/dhf/repos/docbld dhf-builder rake
EXPORTDIR   := /exports
NEWDOC      := /opt/dhf/repos/newdoc
TLCDIR      := /opt/dhf/repos/tlc-article

# Docker defaults.
IMAGE_NAME := dhf-builder

# Explicit Arch defaults
DOCKERFILE_ARCH := Dockerfile.arch
DOCKER_COMPOSE_ARCH := docker-compose.arch.yml

# Ubuntu equivalents
DOCKERFILE_UBUNTU := Dockerfile.ubuntu
DOCKER_COMPOSE_UBUNTU := docker-compose.ubuntu.yml

# -------------------------------------------------------------------------- }}}
# {{{ 🧩 Meta Targets

arch.all: arch.build arch.run ## 🧠 Build and run Arch container end-to-end
dhf.all: deploy ## Build the full DHF (delegates to deploy)
ubuntu.all: ubuntu.build ubuntu.run ## 🧠 Build and run Ubuntu container end-to-end

# -------------------------------------------------------------------------- }}}
# {{{ 🧱 Arch Build Targets


arch.build: ## 🧱 Build full Arch docker image using docker-compose
	docker compose -f $(DOCKER_COMPOSE_ARCH) build

arch.list_files: ## 📝 Run 'rake list_files' inside Arch container (docbld)
	docker compose -f $(DOCKER_COMPOSE_ARCH) run --rm -w /opt/dhf/repos/docbld dhf-builder rake list_files

arch.rebuild: ## 🔄 Full rebuild of Arch image without cache
	docker compose -f $(DOCKER_COMPOSE_ARCH) build --no-cache

arch.texlive: ## 📚 Build only TeX Live layer (Arch version)
	docker build --target texlive-base -t $(IMAGE_NAME)-texlive -f $(DOCKERFILE_ARCH) .

arch.ruby: ## 💎 Build only the Ruby chain (repos + gems) (Arch version)
	docker build --target rubydeps -t $(IMAGE_NAME)-ruby -f $(DOCKERFILE_ARCH) .

arch.run: ## 🚀 Run full document build inside Arch container
	docker compose -f $(DOCKER_COMPOSE_ARCH) up --abort-on-container-exit

arch.shell: ## 🐚 Open an interactive shell inside Arch container
	docker compose -f $(DOCKER_COMPOSE_ARCH) run --rm dhf-builder /bin/bash

# -------------------------------------------------------------------------- }}}
# {{{ 🟠 Ubuntu Build Targets


ubuntu.build: ## 🐧 Build full Ubuntu version of the image
	docker compose -f $(DOCKER_COMPOSE_UBUNTU) build

ubuntu.list_files: ## 📝 Run 'rake list_files' inside Ubuntu container (docbld)
	docker compose -f $(DOCKER_COMPOSE_UBUNTU) run --rm -w /opt/dhf/repos/docbld dhf-builder rake list_files

ubuntu.rebuild: ## 🔄 Full rebuild of Ubuntu image without cache
	docker compose -f $(DOCKER_COMPOSE_UBUNTU) build --no-cache

ubuntu.texlive: ## 📚 Build only TeX Live layer (Ubuntu version)
	docker build --target texlive-base -t $(IMAGE_NAME)-texlive -f $(DOCKERFILE_UBUNTU) .

ubuntu.ruby: ## 💎 Build only the Ruby chain (repos + gems) (Ubuntu version)
	docker build --target rubydeps -t $(IMAGE_NAME)-ruby -f $(DOCKERFILE_UBUNTU) .

ubuntu.run: ## 🚀 Run full document build inside Ubuntu container
	docker compose -f $(DOCKER_COMPOSE_UBUNTU) up --abort-on-container-exit

ubuntu.shell: ## 🐚 Open interactive shell in Ubuntu container
	docker compose -f $(DOCKER_COMPOSE_UBUNTU) run --rm dhf-builder /bin/bash

# -------------------------------------------------------------------------- }}}
# {{{ 🟠 Design History File Targets

dhf.clobber: ## Remove generated files and intermediate artifacts
	$(DOCKER_RAKE) clobber

dhf.copy_files: ## Copy generated files into the distribution folder
	$(DOCKER_RAKE) copy_files

dhf.deploy: remove_distdir texx copy_files clobber ## Full docbld pipeline: clean → build → copy → clobber

dhf.docx: ## Build DOCX files from .texx using docbld
	$(DOCKER_RAKE) docx

dhf.list_files: ## List all .texx files detected by docbld
	$(DOCKER_RAKE) list_files

dhf.remove_distdir: ## Remove the distribution directory
	$(DOCKER_RAKE) remove_distdir

dhf.texx: ## Build PDFs from .texx using docbld
	$(DOCKER_RAKE) texx

# -------------------------------------------------------------------------- }}}
# {{{ 🧼 Cleanup Targets

clean: ## 🧼 Cleanup local containers, images, volumes, orphans (Arch & Ubuntu)
	docker compose -f $(DOCKER_COMPOSE_ARCH) down --rmi local --volumes --remove-orphans
	docker compose -f $(DOCKER_COMPOSE_UBUNTU) down --rmi local --volumes --remove-orphans

prune: ## 🪓 Prune all dangling images and stopped containers
	docker system prune -af

# -------------------------------------------------------------------------- }}}
# {{{ 🆘 Help - TODO: May need tewaking for powershell.

help: ## 📚 Show this help message
	@echo "📌 DHF Builder Makefile — Docker build & testing"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'

# -------------------------------------------------------------------------- }}}
# {{{ 📝 PHONY

.PHONY: \
	arch.build arch.rebuild arch.texlive arch.ruby arch.run arch.shell arch.list_files arch.all \
	dhf.all dhf.clobber dhf.copy_files dhf.deploy dhf.docx dhf.list_files dhf.remove_distdir dhf.texx \
	ubuntu.build ubuntu.rebuild ubuntu.texlive ubuntu.ruby ubuntu.run ubuntu.shell ubuntu.list_files ubuntu.all \
	clean prune help

# -------------------------------------------------------------------------- }}}
