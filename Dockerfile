FROM debian:jessie
MAINTAINER Hellyna NG <hellyna@hellyna.com>

# Copy private key.
COPY ./ci@groventure.com.sg.id_rsa /root/.ssh/id_rsa

# Install node repository.
RUN set -x; \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl && \
    curl -L https://deb.nodesource.com/setup_4.x | bash - && \
    # Create users/groups here so that uid/gid will not be taken by other processes
    # which are installed later.
    groupadd --gid 107 odoo && \
    useradd -d /var/lib/odoo --create-home --uid 104 --gid 107 --system odoo && \
    # Install dependencies
    apt-get update && \
    apt-get install -y --no-install-recommends \
        # Required by pip install pillow
        libjpeg62-turbo \
        # Required by pip install python-ldap
        libldap-2.4-2 \
        # Required by pip install psycopg2
        libpq5 \
        # Required by pip install python-ldap
        libsasl2-2 \
        # Required by pip install lxml
        libxml2 \
        # Required by pip install lxml
        libxslt1.1 \
        # Required by npm install -g less
        nodejs \
        postgresql-client \
        python && \
    # Required by npm install -g less
    update-alternatives --install \
        /usr/bin/node node /usr/bin/nodejs 10 && \
    # Install build dependencies
    apt-get update && \
    apt-get install -y --no-install-recommends \
        # Needed for git and python-pip for proper SSL verification of downloaded packages..
        ca-certificates \
        # Required by pip install pillow
        libjpeg62-turbo-dev \
        # Required by pip install python-ldap
        libldap2-dev \
        # Required by pip install psycopg2
        libpq-dev \
        # Required by pip install python-ldap
        libsasl2-dev \
        # Required by pip install lxml
        libxml2-dev \
        # Required by pip install lxml
        libxslt1-dev \
        # Required by pip install wheels
        gcc \
        git \
        # Required by pip install wheels
        python-dev \
        python-pip \
        python-setuptools \
        # Needed by git
        openssh-client && \
    # Required by pip install wheels
    pip install --upgrade pip && \
    # Installing node dependencies
    npm install -g less && \
    # Get odoo sources
    chmod 0700 /root/.ssh && \
    chmod 0600 /root/.ssh/id_rsa && \
    echo 'Host git.groventure.com\n\tStrictHostKeyChecking no\n' >> /root/.ssh/config && \
    mkdir -p /opt && \
    git clone \
        --branch upstream-ocb \
        --depth 3 \
        git@git.groventure.com:/gronex/odoo.git /opt/odoo && \
    ln -svf /opt/odoo/openerp-server /usr/bin/openerp-server && \
    rm -rf /opt/odoo/.git && \
    # Install pip dependencies
    pip install -r /opt/odoo/requirements.txt && \
    # Remove build dependencies
    apt-get purge \
        -y \
        --auto-remove \
        -o APT::AutoRemove::RecommendsImportant=false \
        -o APT::AutoRemove::SuggestsImportant=false \
            # Needed for git and python-pip for proper SSL verification of downloaded packages..
            ca-certificates \
            # Required by pip install pillow
            libjpeg62-turbo-dev \
            # Required by pip install python-ldap
            libldap2-dev \
            # Required by pip install psycopg2
            libpq-dev \
            # Required by pip install python-ldap
            libsasl2-dev \
            # Required by pip install lxml
            libxml2-dev \
            # Required by pip install lxml
            libxslt1-dev \
            # Required by pip install wheels
            gcc \
            git \
            # Required by pip install wheels
            python-dev \
            python-pip \
            python-setuptools \
            # Needed by git
            openssh-client && \
    # Remove temporary files
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.pip

# Copy Odoo configuration file and entrypoint
COPY ./openerp-server.conf /opt/odoo/
COPY ./entrypoint.py /

# Mkdir and define volumes, as well as fix permissions.
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons \
        && chmod 0755 /entrypoint.py
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Set the default config file
ENV OPENERP_SERVER /opt/odoo/openerp-server.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.py"]
