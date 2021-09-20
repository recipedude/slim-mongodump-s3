FROM debian:bullseye-slim
LABEL maintainer "Sean Wenzel <sean@infinitenetworks.com>"

RUN apt-get update;apt-get -y install awscli wget gnupg

RUN wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
RUN echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list
RUN apt-get update;apt-get install -y mongodb-org

ADD files/run.sh /scripts/run.sh
RUN chmod -R 755 /scripts && \
    mkdir /data

ENV AWS_ACCESS_KEY_ID ""
ENV AWS_SECRET_ACCESS_KEY ""

VOLUME /data
VOLUME /root/.aws

CMD ["/scripts/run.sh"]
