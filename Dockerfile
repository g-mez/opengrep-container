FROM registry.access.redhat.com/ubi9/ubi-minimal:9.4

# Set up working directory for build steps
WORKDIR /app
ARG OPENGREP_VERSION

# Copy offline artifacts (binary + rules)
COPY artifacts/opengrep/${OPENGREP_VERSION}/opengrep /usr/local/bin/opengrep
COPY artifacts/rules /rules
RUN chmod +x /usr/local/bin/opengrep && chmod -R 755 /rules

# Install locale support for UTF-8 (required for Python & Opengrep)
RUN microdnf install -y glibc-langpack-en && microdnf clean all

# Set UTF-8 locale and Python output encoding
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV PYTHONUTF8=1
ENV PYTHONIOENCODING=utf-8

# Create non-root user with home directory (needed for Opengrep cache)
RUN useradd -u 1000 -m -d /home/opengrep opengrep

# Validate the rulesets 
RUN /usr/local/bin/opengrep validate /rules

# Metadata
LABEL org.opengrep.version=$OPENGREP_VERSION

# Switch to non-root user
USER opengrep
WORKDIR /home/opengrep

# Default command
ENTRYPOINT ["/usr/local/bin/opengrep"]
CMD ["--help"]
