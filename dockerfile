FROM debian:stable-slim

RUN apt update

RUN apt install perl-base -y
RUN apt install perl -y
RUN apt install cpanminus -y
RUN apt install unzip -y
RUN apt install gcc -y
RUN apt install libaio1 -y
RUN apt install postgresql-client -y
RUN apt install libpq-dev -y

COPY ora2pg /opt

COPY libs/instantclient-basic-linux.x64-12.2.0.1.0.zip /opt
COPY libs/instantclient-jdbc-linux.x64-12.2.0.1.0.zip /opt
COPY libs/instantclient-sdk-linux.x64-12.2.0.1.0.zip /opt
COPY libs/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip /opt

WORKDIR /opt

RUN unzip instantclient-basic-linux.x64-12.2.0.1.0.zip
RUN unzip instantclient-jdbc-linux.x64-12.2.0.1.0.zip
RUN unzip instantclient-sdk-linux.x64-12.2.0.1.0.zip
RUN unzip instantclient-sqlplus-linux.x64-12.2.0.1.0.zip

RUN rm instantclient-basic-linux.x64-12.2.0.1.0.zip
RUN rm instantclient-jdbc-linux.x64-12.2.0.1.0.zip
RUN rm instantclient-sdk-linux.x64-12.2.0.1.0.zip
RUN rm instantclient-sqlplus-linux.x64-12.2.0.1.0.zip

ENV LD_LIBRARY_PATH /opt/instantclient_12_2
ENV PATH="${PATH}:/opt/instantclient_12_2"
RUN ln -s /opt/instantclient_12_2/libclntshcore.so.12.1 /usr/lib/libclntshcore.so  

RUN cpanm DBI && cpanm Test::NoWarnings && cpanm DBD::Oracle && cpanm DBD::Pg

WORKDIR /opt/ora2pg-24.0
RUN perl Makefile.PL
RUN make && make install

CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"