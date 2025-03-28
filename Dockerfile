#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM oraclelinux:8-slim
ADD --chmod=755 https://raw.githubusercontent.com/docker-library/mysql/refs/heads/master/8.4/docker-entrypoint.sh /usr/local/bin/
RUN set -eux; \
    groupadd --system --gid 999 mysql; \
    useradd --system --uid 999 --gid 999 --home-dir /var/lib/mysql --no-create-home mysql; \
    chmod +x /usr/local/bin/docker-entrypoint.sh; \
    \
    # add gosu for easy step-down from root
    # https://github.com/tianon/gosu/releases
    GOSU_VERSION=1.17; \
    arch="$(uname -m)"; \
    case "$arch" in \
        aarch64) gosuArch='arm64' ;; \
        x86_64) gosuArch='amd64' ;; \
        *) echo >&2 "error: unsupported architecture: '$arch'"; exit 1 ;; \
    esac; \
    curl -fL -o /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$gosuArch.asc"; \
    curl -fL -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$gosuArch"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
    rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
    chmod +x /usr/local/bin/gosu; \
    gosu --version; \
    gosu nobody true; \
    \
    # Install necessary packages
    microdnf install -y \
        bzip2 \
        gzip \
        openssl \
        xz \
        zstd \
        findutils \
    ; \
    microdnf clean all; \
    \
    # Import MySQL GPG key
    key='BCA4 3417 C3B4 85DD 128E C6D4 B7B3 B788 A8D3 785C'; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
    gpg --batch --export --armor "$key" > /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql; \
    rm -rf "$GNUPGHOME"; \
    \
    # Set MySQL version and add repository
    MYSQL_MAJOR=8.4; \
    MYSQL_VERSION=8.4.4-1.el8; \
    { \
        echo '[mysql-8.4-community]'; \
        echo 'name=MySQL 8.4 Community'; \
        echo 'enabled=1'; \
        echo 'baseurl=https://repo.mysql.com/yum/mysql-8.4-community/el/8/$basearch/'; \
        echo 'gpgcheck=1'; \
        echo 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql'; \
        echo 'module_hotfixes=true'; \
    } | tee /etc/yum.repos.d/mysql-8.4-community.repo; \
    \
    # Install MySQL server
    microdnf install -y "mysql-community-server-$MYSQL_VERSION"; \
    microdnf clean all; \
    # the "socket" value in the Oracle packages is set to "/var/lib/mysql" which isn't a great place for the socket (we want it in "/var/run/mysqld" instead)
    # https://github.com/docker-library/mysql/pull/680#issuecomment-636121520
    grep -F 'socket=/var/lib/mysql/mysql.sock' /etc/my.cnf; \
    sed -i 's!^socket=.*!socket=/var/run/mysqld/mysqld.sock!' /etc/my.cnf; \
    grep -F 'socket=/var/run/mysqld/mysqld.sock' /etc/my.cnf; \
    { echo '[client]'; echo 'socket=/var/run/mysqld/mysqld.sock'; } >> /etc/my.cnf; \
    \
    # make sure users dumping files in "/etc/mysql/conf.d" still works
    ! grep -F '!includedir' /etc/my.cnf; \
    { echo; echo '!includedir /etc/mysql/conf.d/'; } >> /etc/my.cnf; \
    mkdir -p /etc/mysql/conf.d; \
    # ensure these directories exist and have useful permissions
    # the rpm package has different opinions on the mode of `/var/run/mysqld`, so this needs to be after install
    mkdir -p /var/lib/mysql /var/run/mysqld; \
    chown mysql:mysql /var/lib/mysql /var/run/mysqld; \
    # ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
    chmod 1777 /var/lib/mysql /var/run/mysqld; \
    \
    mkdir /docker-entrypoint-initdb.d; \
    \
    mysqld --version; \
    mysql --version; \
    \
    # Add MySQL tools repository
    { \
        echo '[mysql-tools-community]'; \
        echo 'name=MySQL Tools Community'; \
        echo 'baseurl=https://repo.mysql.com/yum/mysql-tools-8.4-community/el/8/$basearch/'; \
        echo 'enabled=1'; \
        echo 'gpgcheck=1'; \
        echo 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql'; \
        echo 'module_hotfixes=true'; \
    } | tee /etc/yum.repos.d/mysql-community-tools.repo; \
    \
    # Install MySQL Shell
    MYSQL_SHELL_VERSION=8.4.4-1.el8; \
    microdnf install -y "mysql-shell-$MYSQL_SHELL_VERSION"; \
    microdnf clean all; \
    \
    mysqlsh --version

VOLUME /var/lib/mysql

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3306 33060
CMD ["mysqld"]
