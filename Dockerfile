FROM manticoresearch/manticore-executor:0.6.9-dev

ARG TARGET_ARCH='amd64'
ARG MANTICORE_REV='c86d78c3dd0a21705afc1130deb6f47f7b2b9e6f'
ARG COLUMNAR_REV='8171c1adecb46fb7144618b403e49b6ec4b683ec'
ENV EXECUTOR_VERSION='0.6.9-230330-35089f4'

# Build manticore and columnar first
ENV BUILD_DEPS="autoconf automake cmake alpine-sdk openssl-dev bison flex git boost-static boost-dev zstd-dev curl-dev"
RUN apk update && apk add curl gcc vim libcurl $BUILD_DEPS && \
  git clone https://github.com/manticoresoftware/columnar.git && \
    cd columnar && \
    git checkout $COLUMNAR_REV && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DWITH_GALERA=0 -DBUILD_TESTING=OFF .. && \
    make -j8 && make install && cd ../.. && rm -fr columnar && \
  rm -f /usr/local/lib/libcurl.* && \
  rm -f /usr/local/bin/curl && \
  git clone https://github.com/manticoresoftware/manticoresearch.git && \
    cd manticoresearch && \
    git checkout $MANTICORE_REV && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DWITH_GALERA=0 -DBUILD_TESTING=OFF .. && \
    make -j8 && make install && cd ../.. && rm -fr manticoresearch && \
  apk del $BUILD_DEPS && \
  rm -fr /var/cache/apk/* && \
  cp /usr/local/etc/manticoresearch/manticore.conf /etc/manticore.conf

# Get production version and keep dev for executor
RUN apk update && \
  apk add bash figlet mysql-client iproute2 \
    apache2-utils coreutils neovim git && \
  mv /usr/bin/manticore-executor /usr/bin/manticore-executor-dev && \
  ln -sf /usr/bin/manticore-executor-dev /usr/bin/php && \
  curl -sSL https://github.com/manticoresoftware/executor/releases/download/v0.6.9/manticore-executor_${EXECUTOR_VERSION}_linux_${TARGET_ARCH}.tar.gz | tar -xzf - && \
  mv manticore-executor_${EXECUTOR_VERSION}_linux_${TARGET_ARCH}/manticore-executor /usr/bin && \
  rm -fr manticore-executor_${EXECUTOR_VERSION}_linux_${TARGET_ARCH}

# alter bash prompt
ENV PS1A="\u@manticore-executor-kit:\w> "
RUN echo 'PS1=$PS1A' >> ~/.bashrc && \
  echo 'figlet -w 120 Manticore Executor Kit' >> ~/.bashrc

RUN mkdir -p /var/run/manticore && \
  bash -c "mkdir -p /var/{run,log,lib}/manticore-test" && \
  mkdir -p /usr/share/manticore/morph/ && \
  echo -e 'a\nb\nc\nd\n' > /usr/share/manticore/morph/test

RUN echo -e "common { \n\
    plugin_dir = /usr/local/lib/manticore\n\
    lemmatizer_base = /usr/share/manticore/morph/\n\
}\n\
searchd {\n\
    listen = 0.0.0:9312\n\
    listen = 0.0.0:9306:mysql\n\
    listen = 0.0.0:9308:http\n\
    log = /var/log/manticore/searchd.log\n\
    query_log = /var/log/manticore/query.log\n\
    pid_file = /var/run/manticore/searchd.pid\n\
    data_dir = /var/lib/manticore\n\
    query_log_format = sphinxql\n\
    # buddy_path = manticore-executor-dev /workdir/src/main.php\n\
}\n" > "/usr/local/etc/manticoresearch/manticore.conf" && \
  rm -f /etc/manticore.conf && \
  ln -sf /usr/local/etc/manticoresearch/manticore.conf /etc/manticore.conf && \
  ln -sf /usr/local/var/lib/manticore/ /var/lib/manticore && \
  ln -sf /usr/local/var/log/manticore/ /var/log/manticore

# Prevent the container from exiting
ENTRYPOINT ["tail"]
CMD ["-f", "/dev/null"]


# Building dev version
# docker build -t manticoresearch/manticore-executor-kit:0.6.9 -f Dockerfile .

# Building release version
# docker build --build-arg MANTICORE_REV=manticore-6.0.4 --build-arg COLUMNAR_REV=columnar-2.0.4 -t manticoresearch/manticore-executor-kit:0.6.9-6.0.4 -f Dockerfile .
