FROM judge0/compilers:1.4.0 AS production

ARG ISOLATE_VERSION=2.2.1

ENV JUDGE0_HOMEPAGE "https://judge0.com"
LABEL homepage=$JUDGE0_HOMEPAGE

ENV JUDGE0_SOURCE_CODE "https://github.com/judge0/judge0"
LABEL source_code=$JUDGE0_SOURCE_CODE

ENV JUDGE0_MAINTAINER "Herman Zvonimir Došilović <hermanz.dosilovic@gmail.com>"
LABEL maintainer=$JUDGE0_MAINTAINER

ENV PATH "/usr/local/ruby-2.7.0/bin:/opt/.gem/bin:$PATH"
ENV GEM_HOME "/opt/.gem/"

RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99no-check-valid-until && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      cron \
      curl \
      git \
      libcap-dev \
      libpq-dev \
      libsystemd-dev \
      pkg-config \
      sudo \
      unzip && \
    rm -rf /var/lib/apt/lists/* && \
    echo "gem: --no-document" > /root/.gemrc && \
    gem install bundler:2.1.4 && \
    npm install -g --unsafe-perm aglio@2.3.0

COPY patches/isolate-cgroup-v2.patch /tmp/isolate-cgroup-v2.patch

#build essentials

RUN git clone --branch v${ISOLATE_VERSION} --depth=1 https://github.com/ioi/isolate.git /tmp/isolate && \
    cd /tmp/isolate && \
    patch -p1 < /tmp/isolate-cgroup-v2.patch && \
    make install PREFIX=/usr/local && \
    rm -rf /tmp/isolate && \
    rm -f /tmp/isolate-cgroup-v2.patch

# ============================================================
# Install all custom requirements (Python, Node, React, Angular)
# ============================================================

# Copy the entire requirements folder
COPY requirements /tmp/requirements
WORKDIR /tmp/requirements

# 1. Python dependencies (FastAPI, Django, Data Science)
RUN bash python/install-python-deps.sh

# 2. Node.js 18 + npm
RUN bash node/install-node.sh

# 3. Global React testing packages (Jest, Testing Library, Babel)
RUN bash node/install-react-global.sh

# 4. Global Angular CLI and testing packages (Jasmine, Karma, TypeScript)
RUN bash angular/install-angular-global.sh

# 5. Copy Babel config to a permanent location
RUN cp babel/babel.config.js /usr/local/lib/babel.config.js

# 6. Set environment variables for Node, Babel, and Angular
ENV NODE_PATH="/usr/local/lib/node_modules"
ENV BABEL_CONFIG_PATH="/usr/local/lib/babel.config.js"

# Clean up
RUN rm -rf /tmp/requirements
WORKDIR /api


EXPOSE 2359

WORKDIR /api

COPY Gemfile* ./
RUN RAILS_ENV=production bundle

COPY cron /etc/cron.d
RUN cat /etc/cron.d/* | crontab -

COPY . .

ENTRYPOINT ["/api/docker-entrypoint.sh"]
CMD ["/api/scripts/server"]

RUN useradd -u 1000 -m -r judge0 && \
    echo "judge0 ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers && \
    chown judge0: /api/tmp/

USER judge0

ENV JUDGE0_VERSION "1.13.1"
LABEL version=$JUDGE0_VERSION


FROM production AS development

CMD ["sleep", "infinity"]
