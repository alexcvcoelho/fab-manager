FROM ruby:3.2.2

# First we need to be able to fetch from https repositories
RUN apt-get update && \
    apt-get install -y apt-transport-https \
      ca-certificates apt-utils supervisor locales

RUN locale-gen C.UTF-8

RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -\
  && apt-get update -qq && apt-get install -qq --no-install-recommends \
    nodejs \
  && apt-get upgrade -qq \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*\
  && npm install -g yarn@1

# Fix bug: LoadError: Could not open library '/usr/local/bundle/gems/sassc-2.1.0-x86_64-linux/lib/sassc/libsass.so': Error loading shared library ld-linux-x86-64.so.2: No such file or directory (needed by /usr/local/bundle/gems/sassc-2.1.0-x86_64-linux/lib/sassc/libsass.so)
# add libsass-dev libsass libc6-compat and env below
ENV LD_LIBRARY_PATH=/lib64

RUN gem install bundler

# Throw error if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

# Install Javascript packages
WORKDIR /usr/src/app
COPY package.json /usr/src/app/package.json
COPY yarn.lock /usr/src/app/yarn.lock
RUN yarn install

# Web app
RUN mkdir -p /usr/src/app && \
    mkdir -p /usr/src/app/config && \
    mkdir -p /usr/src/volume/invoices && \
    mkdir -p /usr/src/volume/payment_schedules && \
    mkdir -p /usr/src/volume/exports && \
    mkdir -p /usr/src/volume/imports && \
    mkdir -p /usr/src/volume/log && \
    mkdir -p /usr/src/volume/public && \
    mkdir -p /usr/src/volume/public/uploads && \
    mkdir -p /usr/src/volume/public/packs && \
    mkdir -p /usr/src/volume/accounting && \
    mkdir -p /usr/src/volume/supporting_document_files && \
    mkdir -p /usr/src/app/tmp/sockets && \
    mkdir -p /usr/src/app/tmp/pids

COPY docker/database.yml /usr/src/app/config/database.yml
COPY . /usr/src/app

RUN ln -s /usr/src/volume/invoices /usr/src/app/invoices && \
    ln -s /usr/src/volume/payment_schedules /usr/src/app/payment_schedules && \
    ln -s /usr/src/volume/exports /usr/src/app/exports && \
    ln -s /usr/src/volume/imports /usr/src/app/imports && \
    ln -s /usr/src/volume/public /usr/src/app/public && \
    ln -s /usr/src/volume/public/uploads /usr/src/app/public/uploads && \
    ln -s /usr/src/volume/public/packs /usr/src/app/public/packs && \
    ln -s /usr/src/volume/accounting /usr/src/app/accounting && \
    ln -s /usr/src/volume/supporting_document_files /usr/src/app/supporting_document_files && \
    ln -s /usr/src/volume/log /usr/src/app/log

COPY Gemfile /tmp/
COPY Gemfile.lock /tmp/
#RUN bundle lock --add-platform x86_64-linux
RUN bundle install --binstubs --without test doc
RUN rails app:update:bin

# Volumes (the folders are created by setup.sh)
VOLUME /usr/src/volume/invoices \
       /usr/src/volume/payment_schedules \
       /usr/src/volume/exports \
       /usr/src/volume/imports \
       /usr/src/volume/public \
       /usr/src/volume/public/uploads \
       /usr/src/volume/public/packs \
       /usr/src/volume/accounting \
       /usr/src/volume/supporting_document_files \
       /usr/src/volume/log \
       /var/log/supervisor

# Expose port 3000 to the Docker host, so we can access it from the outside
EXPOSE 3000

# Permission to evit access denied for supervisor
RUN chmod -R a+w /usr/src/app
RUN chmod -R a+w /var/run
RUN chmod -R a+w /var/log

# The main command to run when the container starts. Also tell the Rails server
# to bind to all interfaces by default.
COPY docker/supervisor.conf /etc/supervisor/conf.d/fabmanager.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/fabmanager.conf"]
