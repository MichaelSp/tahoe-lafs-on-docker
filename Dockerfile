FROM ubuntu:latest

RUN apt-get -y update && apt-get -y install tahoe-lafs python-cffi openssh-client

ADD entrypoint.sh /entrypoint
RUN chmod +x /entrypoint

EXPOSE 3456

ENTRYPOINT ["/entrypoint"]
CMD version