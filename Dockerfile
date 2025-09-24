FROM ghcr.io/oneargo/argoformatchecker/app:develop AS base

USER root

# Install Poetry for dependency management.
ENV POETRY_HOME=/opt/poetry
ENV PATH="${POETRY_HOME}/bin:${PATH}"

RUN \
    apk add --no-cache \
        python3 \
        py3-pip \
        curl \
        build-base \
        python3-dev \
        git && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    mkdir -p /opt/poetry/project /opt/poetry/bin && \
    curl -sSL https://install.python-poetry.org | python -

# Install dependencies.
COPY file_checker_python/argofilechecker-python-wrapper/pyproject.toml file_checker_python/argofilechecker-python-wrapper/poetry*.lock file_checker_python/argofilechecker-python-wrapper/README.md /opt/poetry/dep/
RUN \
    cd /opt/poetry/dep && \
    poetry config virtualenvs.create false && \
    if [ ! -f poetry.lock ]; then poetry lock; fi && \
    poetry install --no-root && \
    poetry env info

FROM base AS build-deps
# Ephemeral environment for building packages.
RUN --mount=type=bind,source=./file_checker_python/argofilechecker-python-wrapper,target=/opt/dep,rw=true \
    cd /opt/dep && \
    rm -rf ./dist && \
    POETRY_DYNAMIC_VERSIONING_BYPASS=1.0.0 poetry build && \
    mkdir /opt/build && \
    mv ./dist/*.whl /opt/build

FROM base AS app

#env variables for file checker
ENV FILE_CHECKER_JAR="/app/app.jar"
#ENV FILE_CHECKER_SPECS="/app/specs"

RUN --mount=type=bind,from=build-deps,source=/opt/build,target=/opt/build \
    python -m venv /opt/venv && \
    /opt/venv/bin/pip install /opt/build/*.whl && \
    /opt/venv/bin/python -c "from argofilechecker_python_wrapper import FileChecker; print('OK')"

WORKDIR /home/app
COPY file_checker_python/pyproject.toml file_checker_python/poetry*.lock file_checker_python/README.md ./
COPY file_checker_python/file_checker_api /home/app/file_checker_api
COPY file_checker_spec /home/app/file_checker_spec

RUN --mount=type=bind,from=build-deps,source=/opt/build,target=/opt/build \
    poetry config virtualenvs.create false && \
    poetry add /opt/build/*.whl && \
    if [ ! -f poetry.lock ]; then poetry lock; fi && \
    poetry install --no-root && \
    poetry env info

ENV PATH="/opt/venv/bin:${PATH}"
RUN mkdir /home/app/input
RUN chown fileCheckerRunner:gcontainer /home/app/input

USER fileCheckerRunner

#overide entrypoint from base image
ENTRYPOINT ["poetry"]
CMD ["run", "gunicorn", "file_checker_api:app", "-b", "0.0.0.0:8000", "-k", "uvicorn.workers.UvicornWorker", "--timeout", "300"]
