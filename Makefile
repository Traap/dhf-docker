# {{{ 🐳 Makefile — DHF Builder Docker Targets (Arch & Ubuntu)
#
# -------------------------------------------------------------------------- }}}
# {{{ 🔧 Base names and configuration

# DHF defaults DHF defaults
AMBER       := /soup/amber
AUTODOC     := /soup/autodoc
DOCBLD      := /soup/docbld
DOCKER_RAKE := docker compose run --rm -w /soup/docbld dhf-builder rake
EXPORTDIR   := /exports
NEWDOC      := /soup/newdoc
TLCDIR      := /soup/tlc-article

# Enable Docker BuildKit globally
export DOCKER_BUILDKIT=1

# Docker defaults.
IMAGE_NAME := dhf-builder
REGISTRY   ?=
TAG        := latest
# --------------------------------------------------------------------------
# 🧱 Save and Load built images for sharing (auto-detect from Compose)
# --------------------------------------------------------------------------

# Normalize registry format (avoid leading slash if undefined)
ifeq ($(strip $(REGISTRY)),)
  REGISTRY_PREFIX :=
else
  REGISTRY_PREFIX := $(REGISTRY)/
endif

# Explicit Arch defaults
DOCKERFILE_ARCH := Dockerfile.arch
DOCKER_COMPOSE_ARCH := docker-compose.arch.yml
IMAGE_ARCH      := $(shell docker compose -f $(DOCKER_COMPOSE_ARCH) config | grep 'image:' | awk '{print $$2}')
IMAGE_NAME_ARCH := $(notdir $(basename $(IMAGE_ARCH)))
SAVE_TAR_ARCH   := $(IMAGE_NAME_ARCH)-arch.tar

# Ubuntu equivalents
DOCKERFILE_UBUNTU := Dockerfile.ubuntu
DOCKER_COMPOSE_UBUNTU := docker-compose.ubuntu.yml
IMAGE_UBUNTU    := $(shell docker compose -f $(DOCKER_COMPOSE_UBUNTU) config | grep 'image:' | awk '{print $$2}')
IMAGE_NAME_UBUNTU := $(notdir $(basename $(IMAGE_UBUNTU)))
SAVE_TAR_UBUNTU := $(IMAGE_NAME_UBUNTU)-ubuntu.tar

# Detect Git Bash path translation quirk.
ifeq ($(shell uname -o 2>/dev/null),Msys)
  WORKDIR = //workspace
else
  WORKDIR = /workspace
endif

# -------------------------------------------------------------------------- }}}
# {{{ 🧩 Meta Targets

arch.all: arch.build arch.run ## 🧠 Build and run Arch container end-to-end
dhf.all: deploy ## Build the full DHF (delegates to deploy)
ubuntu.all: ubuntu.build ubuntu.run ## 🧠 Build and run Ubuntu container end-to-end

# -------------------------------------------------------------------------- }}}
# {{{ 🧱 Arch Build Targets  (patched for Git Bash & Linux)

arch.build: ## 🧱 Build full Arch docker image using docker-compose
	docker compose -f $(DOCKER_COMPOSE_ARCH) build --progress=plain > arch.log 2>&1

arch.list_files: ## 📝 Run 'rake list_files' using /soup/docbld/Rakefile (cross-platform safe)
	docker compose -f $(DOCKER_COMPOSE_ARCH) run --rm -w $(WORKDIR) \
	  dhf-builder bash -c "rake --rakefile /soup/docbld/Rakefile list_files"

arch.load:  ## 📦 Load the Arch Linux image from a portable tarball
	@echo "📦 Loading Docker image from $(SAVE_TAR_ARCH)"
	docker load -i $(SAVE_TAR_ARCH)
	@echo "✅ Image loaded: $(IMAGE_ARCH)"

arch.rebuild: ## 🔄 Full rebuild of Arch image without cache
	docker compose -f $(DOCKER_COMPOSE_ARCH) build --no-cache > arch.log 2>&1

arch.texlive: ## 📚 Build only TeX Live layer (Arch version)
	docker build --target texlive-base -t $(IMAGE_NAME)-texlive -f $(DOCKERFILE_ARCH) .

arch.push:  ## 🚀 Push the Arch Linux image to its registry
	@echo "📤 Pushing Docker image $(IMAGE_ARCH)"
	docker push $(IMAGE_ARCH)
	@echo "✅ Push complete: $(IMAGE_ARCH)"

arch.ruby: ## 💎 Build only the Ruby chain (repos + gems) (Arch version)
	docker build --target rubydeps -t $(IMAGE_NAME)-ruby -f $(DOCKERFILE_ARCH) .

arch.run: ## 🚀 Run full document build inside Arch container
	docker compose -f $(DOCKER_COMPOSE_ARCH) up --abort-on-container-exit

arch.save:  ## 🐳 Save the built Arch Linux image as a portable tarball
	@echo "📦 Saving Docker image $(IMAGE_ARCH) → $(SAVE_TAR_ARCH)"
	docker save -o $(SAVE_TAR_ARCH) $(IMAGE_ARCH)
	@echo "✅ Export complete: $(SAVE_TAR_ARCH)"

arch.shell: ## 🐚 Open an interactive shell inside Arch container
	docker compose -f $(DOCKER_COMPOSE_ARCH) run --rm dhf-builder /bin/bash

# -------------------------------------------------------------------------- }}}
# {{{ 🟠 Ubuntu Build Targets  (patched for Git Bash & Linux)

ubuntu.build: ## 🐧 Build full Ubuntu version of the image
	docker compose -f $(DOCKER_COMPOSE_UBUNTU) build --progress=plain > ubuntu.log 2>&1

ubuntu.list_files: ## 📝 Run 'rake list_files' using /soup/docbld/Rakefile (cross-platform safe)
	docker compose -f $(DOCKER_COMPOSE_UBUNTU) run --rm -w $(WORKDIR) \
	  dhf-builder bash -c "rake --rakefile /soup/docbld/Rakefile list_files"

ubuntu.load:  ## 📦 Load the Ubuntu image from a portable tarball
	@echo "📦 Loading Docker image from $(SAVE_TAR_UBUNTU)"
	docker load -i $(SAVE_TAR_UBUNTU)
	@echo "✅ Image loaded: $(IMAGE_UBUNTU)"

ubuntu.push:  ## 🚀 Push the Ubuntu image to its registry
	@echo "📤 Pushing Docker image $(IMAGE_UBUNTU)"
	docker push $(IMAGE_UBUNTU)
	@echo "✅ Push complete: $(IMAGE_UBUNTU)"

ubuntu.rebuild: ## 🔄 Full rebuild of Ubuntu image without cache
	docker compose -f $(DOCKER_COMPOSE_UBUNTU) build --no-cache > ubuntu.log 2>&1

ubuntu.texlive: ## 📚 Build only TeX Live layer (Ubuntu version)
	docker build --target texlive-base -t $(IMAGE_NAME)-texlive -f $(DOCKERFILE_UBUNTU) .

ubuntu.ruby: ## 💎 Build only the Ruby chain (repos + gems) (Ubuntu version)
	docker build --target rubydeps -t $(IMAGE_NAME)-ruby -f $(DOCKERFILE_UBUNTU) .

ubuntu.run: ## 🚀 Run full document build inside Ubuntu container
	docker compose -f $(DOCKER_COMPOSE_UBUNTU) up --abort-on-container-exit

ubuntu.save:  ## 🐳 Save the built Ubuntu image as a portable tarball
	@echo "📦 Saving Docker image $(IMAGE_UBUNTU) → $(SAVE_TAR_UBUNTU)"
	docker save -o $(SAVE_TAR_UBUNTU) $(IMAGE_UBUNTU)
	@echo "✅ Export complete: $(SAVE_TAR_UBUNTU)"

ubuntu.shell: ## 🐚 Open interactive shell in Ubuntu container
	docker compose -f $(DOCKER_COMPOSE_UBUNTU) run --rm dhf-builder /bin/bash

# -------------------------------------------------------------------------- }}}
# {{{ 🧬 Design History File (DHF) Targets  (patched for container consistency)

# Helper macro — run any rake target via /soup/docbld/Rakefile
define DOCKER_RAKE_CMD
docker compose -f $(DOCKER_COMPOSE_ARCH) run --rm -w $(WORKDIR) \
  dhf-builder bash -c "rake --rakefile /soup/docbld/Rakefile $(1)"
endef

dhf.list_files: ## 📝 List all .texx files detected by docbld
	$(call DOCKER_RAKE_CMD,list_files)

dhf.texx: ## 🧾 Build PDFs from .texx files using docbld
	$(call DOCKER_RAKE_CMD,texx)

dhf.docx: ## 🧾 Build DOCX files from .texx using docbld
	$(call DOCKER_RAKE_CMD,docx)

dhf.copy_files: ## 📦 Copy generated files into the distribution folder
	$(call DOCKER_RAKE_CMD,copy_files)

dhf.clobber: ## 🧹 Remove generated files and intermediate artifacts
	$(call DOCKER_RAKE_CMD,clobber)

dhf.remove_distdir: ## 🗑️ Remove the distribution directory
	$(call DOCKER_RAKE_CMD,remove_distdir)

dhf.deploy: ## 🚀 Full docbld pipeline: clean → build → copy → clobber
	$(call DOCKER_RAKE_CMD,deploy)

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
	arch.build arch.load arch.rebuild arch.texlive arch.ruby arch.run arch.shell arch.list_files arch.push arch.save arch.all \
	dhf.all dhf.clobber dhf.copy_files dhf.deploy dhf.docx dhf.list_files dhf.remove_distdir dhf.texx \
	ubuntu.build ubuntu.load ubuntu.rebuild ubuntu.texlive ubuntu.ruby ubuntu.run ubuntu.shell ubuntu.list_files ubuntu.push ubuntu.save ubuntu.all \
	clean prune help

# -------------------------------------------------------------------------- }}}
