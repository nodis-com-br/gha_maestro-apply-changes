FROM docker.io/nodisbr/python

RUN apt-get update
RUN apt-get -y install git

RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]