# ===========================================================================
# CHAIN A: TeX Live (heavy LaTeX dependencies)
# ===========================================================================
FROM archlinux:latest AS texlive

ENV LANG=en_US.UTF-8 \
  LC_ALL=en_US.UTF-8 \
  DEBIAN_FRONTEND=noninteractive

# Refresh mirrors & install TeX Live
RUN \
  pacman -Syu --noconfirm pacman-contrib curl && \
  curl -s "https://archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4" \
  | sed -e 's/^#Server/Server/' -e '/^#/d' > /etc/pacman.d/mirrorlist && \
  rankmirrors -n 5 /etc/pacman.d/mirrorlist > /etc/pacman.d/mirrorlist.new && \
  mv /etc/pacman.d/mirrorlist.new /etc/pacman.d/mirrorlist && \
  pacman -Syyu --noconfirm && \
  pacman -S --noconfirm \
  texlive-core \
  texlive-latexextra \
  texlive-fontsextra \
  texlive-binextra && \
  pacman -Scc --noconfirm && \
  rm -rf /var/cache/pacman/pkg/*

# Thin layer with TeX only
FROM archlinux:latest AS texlive-base
COPY --from=texlive / /


# ===========================================================================
# CHAIN B: Ruby & Git (repos + bundler)
# ===========================================================================
FROM archlinux:latest AS ruby-base

ENV LANG=en_US.UTF-8 \
  LC_ALL=en_US.UTF-8 \
  DEBIAN_FRONTEND=noninteractive

# Install only ruby & git (lightweight)
RUN \
  pacman -Syu --noconfirm git ruby && \
  pacman -Scc --noconfirm && \
  rm -rf /var/cache/pacman/pkg/*

# ---------------------------------------------------------------------------
# Clone GitHub repositories
# ---------------------------------------------------------------------------
FROM ruby-base AS repos

WORKDIR /opt/dhf/repos
RUN \
  git clone --depth=1 https://github.com/Traap/docbld.git && \
  git clone --depth=1 https://github.com/Traap/newdoc.git && \
  git clone --depth=1 https://github.com/Traap/amber.git && \
  git clone --depth=1 https://github.com/Traap/autodoc.git && \
  git clone --depth=1 https://github.com/Traap/tlc-article.git

# ---------------------------------------------------------------------------
# Install Ruby dependencies for docbld + amber
# ---------------------------------------------------------------------------
FROM ruby-base AS rubydeps

# Copy repos in so we can bundle install
COPY --from=repos /opt/dhf/repos /opt/dhf/repos

# Determine Ruby gem bin path dynamically
ENV PATH="/root/.local/share/gem/ruby/$(ruby -e 'puts RUBY_VERSION[/^\d+\.\d+/]')/bin:$PATH"

WORKDIR /opt/dhf/repos
RUN \
  gem install --user-install bundler && \
  for dir in docbld amber; do \
  if [ -f "$dir/Gemfile" ]; then \
  cd "$dir"; \
  bundle install; \
  cd ..; \
  fi; \
  done


# ===========================================================================
# FINAL RUNTIME IMAGE
# ===========================================================================
FROM texlive-base AS runtime

# Install lightweight build tools (non-TeX)
RUN \
  pacman -S --noconfirm --needed --overwrite '*' \
  pandoc \
  make \
  python && \
  pacman -Scc --noconfirm && \
  rm -rf /var/cache/pacman/pkg/*

# Copy all repos and Ruby gems
COPY --from=rubydeps /opt/dhf/repos /opt/dhf/repos

# Locale setup
RUN \
  sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && \
  locale-gen

WORKDIR /workspace
RUN mkdir -p /exports

VOLUME ["/workspace", "/exports"]

CMD ["make", "all"]

