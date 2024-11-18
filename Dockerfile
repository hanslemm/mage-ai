FROM python:3.12-bookworm

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system packages and clean up
RUN set -eux; \
  apt-get update && \
  ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
  nfs-common \
  unixodbc-dev \
  graphviz \
  postgresql-client \
  r-base \
  linux-libc-dev=6.1.115-1 \
  git=1:2.39.5-0+deb12u1 \
  git-man=1:2.39.5-0+deb12u1 \
  libexpat1=2.5.0-1+deb12u1 \
  libexpat1-dev=2.5.0-1+deb12u1 \
  libheif1=1.15.1-1+deb12u1 \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install R packages
RUN Rscript -e "install.packages(c('pacman', 'renv'), repos='http://cran.us.r-project.org')"

# Install Python packages
RUN pip3 install --upgrade --no-cache-dir \
  pip \
  setuptools \
  wheel \
  packaging \
  "git+https://github.com/wbond/oscrypto.git@d5f3437ed24257895ae1edd9e503cfb352e635a8" \
  "git+https://github.com/dremio-hub/arrow-flight-client-examples.git#egg=dremio-flight&subdirectory=python/dremio-flight" \
  "git+https://github.com/mage-ai/singer-python.git#egg=singer-python" \
  "git+https://github.com/mage-ai/sqlglot#egg=sqlglot" \
  faster-fifo

# Install Mage Integrations
RUN pip3 install --no-cache-dir "git+https://github.com/hanslemm/mage-ai.git@LIGHTWEIGHT-MAGE#egg=mage-integrations&subdirectory=mage_integrations"

# Install Mage
COPY ./mage_ai/server/constants.py /tmp/constants.py
RUN pip3 install --no-cache-dir "git+https://github.com/hanslemm/mage-ai.git@LIGHTWEIGHT-MAGE#egg=mage-ai[dbt,postgres,redshift,s3]"

# Copy startup scripts
COPY --chmod=0755 ./scripts/install_other_dependencies.py ./scripts/run_app.sh /app/

ENV MAGE_DATA_DIR="/home/src/mage_data"
ENV PYTHONPATH="${PYTHONPATH}:/home/src"
WORKDIR /home/src
EXPOSE 6789 7789

CMD ["/bin/sh", "-c", "/app/run_app.sh"]
