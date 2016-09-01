.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container

temp: init

init: GITLAB_SECRETS_OTP_KEY_BASE GITLAB_SECRETS_SECRET_KEY_BASE GITLAB_SECRETS_DB_KEY_BASE TAG IP SMTP_HOST SMTP_PORT SMTP_PASS SMTP_USER DB_USER DB_NAME DB_PASS NAME PORT SSH_PORT rmall runpostgresinit runredisinit rungitlabinit

run: TAG IP GITLAB_SECRETS_OTP_KEY_BASE GITLAB_SECRETS_SECRET_KEY_BASE GITLAB_SECRETS_DB_KEY_BASE SMTP_DOMAIN SMTP_OPENSSL_VERIFY_MODE SMTP_HOST SMTP_PORT SMTP_PASS SMTP_USER DB_NAME DB_PASS NAME PORT SSH_PORT rmall runpostgres runredis rungitlab

next: grab rminit run

runredisinit:
	$(eval NAME := $(shell cat NAME))
	docker run --name $(NAME)-redis-init \
	-d \
	--cidfile="redisinitCID" \
	redis \
	redis-server --appendonly yes

runpostgresinit: postgresinitCID

postgresinitCID:
	$(eval NAME := $(shell cat NAME))
	$(eval DB_USER := $(shell cat DB_USER))
	$(eval DB_PASS := $(shell cat DB_PASS))
	$(eval DB_NAME := $(shell cat DB_NAME))
	docker run \
	--name=$(NAME)-postgresql-init \
	-d \
	--env='DB_NAME=$(DB_NAME)' \
	--env='DB_EXTENSION=pg_trgm' \
	--cidfile="postgresinitCID" \
	--env='DB_USER=$(DB_USER)' --env="DB_PASS=$(DB_PASS)" \
	sameersbn/postgresql:9.5-2

rungitlabinit:
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval GITLAB_SECRETS_DB_KEY_BASE := $(shell cat GITLAB_SECRETS_DB_KEY_BASE))
	$(eval GITLAB_SECRETS_SECRET_KEY_BASE := $(shell cat GITLAB_SECRETS_SECRET_KEY_BASE))
	$(eval GITLAB_SECRETS_OTP_KEY_BASE := $(shell cat GITLAB_SECRETS_OTP_KEY_BASE))
	$(eval IP := $(shell cat IP))
	$(eval PORT := $(shell cat PORT))
	$(eval SSH_PORT := $(shell cat SSH_PORT))
	$(eval DB_NAME := $(shell cat DB_NAME))
	$(eval DB_USER := $(shell cat DB_USER))
	$(eval DB_PASS := $(shell cat DB_PASS))
	$(eval SMTP_PORT := $(shell cat SMTP_PORT))
	$(eval SMTP_HOST := $(shell cat SMTP_HOST))
	$(eval SMTP_PASS := $(shell cat SMTP_PASS))
	$(eval SMTP_USER := $(shell cat SMTP_USER))
	docker run --name=$(NAME) \
	-d \
	--link=$(NAME)-postgresql-init:postgresql \
	--link=$(NAME)-redis-init:redisio \
	--publish=$(IP):$(PORT):80 \
	--publish=$(IP):$(SSH_PORT):22 \
	--env="DB_NAME=$(DB_NAME)" \
	--env="GITLAB_SECRETS_DB_KEY_BASE=$(GITLAB_SECRETS_DB_KEY_BASE)" \
	--env="GITLAB_SECRETS_SECRET_KEY_BASE=$(GITLAB_SECRETS_SECRET_KEY_BASE)" \
	--env="GITLAB_SECRETS_OTP_KEY_BASE=$(GITLAB_SECRETS_OTP_KEY_BASE)" \
	--env="DB_USER=$(DB_USER)" \
	--env="DB_PASS=$(DB_PASS)" \
	--env="GITLAB_PORT=$(PORT)" \
	--env="SMTP_PORT=$(SMTP_PORT)" \
	--env="SMTP_HOST=$(SMTP_HOST)" \
	--env="SMTP_PASS=$(SMTP_PASS)" \
	--env="SMTP_USER=$(SMTP_USER)" \
	--env='GITLAB_SSH_PORT=$(SSH_PORT)' \
	--env='REDIS_URL=redis://redis:6379/12' \
	--cidfile="gitlabinitCID" \
	$(TAG)

#	sameersbn/gitlab:2.6-latest
# used to be last line above --> 	-t joshuacox/gitlabinit
#--publish=$(PORT):80 \

runredis:
	$(eval NAME := $(shell cat NAME))
	$(eval REDIS_DATADIR := $(shell cat REDIS_DATADIR))
	docker run --name $(NAME)-redis \
	-d \
	--cidfile="redisCID" \
	--volume=$(REDIS_DATADIR):/data \
	redis \
	redis-server --appendonly yes

runpostgres:
	$(eval NAME := $(shell cat NAME))
	$(eval DB_USER := $(shell cat DB_USER))
	$(eval DB_PASS := $(shell cat DB_PASS))
	$(eval DB_NAME := $(shell cat DB_NAME))
	$(eval POSTGRES_DATADIR := $(shell cat POSTGRES_DATADIR))
	docker run \
	--name=$(NAME)-postgresql \
	-d \
	--env='DB_NAME=$(DB_NAME)' \
	--cidfile="postgresCID" \
	--env='DB_EXTENSION=pg_trgm' \
	--env='DB_USER=$(DB_USER)' --env="DB_PASS=$(DB_PASS)" \
	--volume=$(POSTGRES_DATADIR):/var/lib/postgresql/ \
	sameersbn/postgresql:9.5-2

rungitlab:
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval GITLAB_SECRETS_DB_KEY_BASE := $(shell cat GITLAB_SECRETS_DB_KEY_BASE))
	$(eval GITLAB_SECRETS_SECRET_KEY_BASE := $(shell cat GITLAB_SECRETS_SECRET_KEY_BASE))
	$(eval GITLAB_SECRETS_OTP_KEY_BASE := $(shell cat GITLAB_SECRETS_OTP_KEY_BASE))
	$(eval IP := $(shell cat IP))
	$(eval PORT := $(shell cat PORT))
	$(eval SSH_PORT := $(shell cat SSH_PORT))
	$(eval GITLAB_DATADIR := $(shell cat GITLAB_DATADIR))
	$(eval DB_NAME := $(shell cat DB_NAME))
	$(eval DB_USER := $(shell cat DB_USER))
	$(eval DB_PASS := $(shell cat DB_PASS))
	$(eval SMTP_PASS := $(shell cat SMTP_PASS))
	$(eval SMTP_USER := $(shell cat SMTP_USER))
	$(eval SMTP_PORT := $(shell cat SMTP_PORT))
	$(eval SMTP_HOST := $(shell cat SMTP_HOST))
	$(eval SMTP_OPENSSL_VERIFY_MODE := $(shell cat SMTP_OPENSSL_VERIFY_MODE))
	$(eval SMTP_TLS := $(shell cat SMTP_TLS))
	$(eval SMTP_STARTTLS := $(shell cat SMTP_STARTTLS))
	$(eval SMTP_DOMAIN := $(shell cat SMTP_DOMAIN))
	docker run --name=$(NAME) \
	-d \
	--link=$(NAME)-postgresql:postgresql \
	--link=$(NAME)-redis:redisio \
	--publish=$(IP):$(PORT):80 \
	--publish=$(IP):$(SSH_PORT):22 \
	--env="GITLAB_SECRETS_DB_KEY_BASE=$(GITLAB_SECRETS_DB_KEY_BASE)" \
	--env="GITLAB_SECRETS_SECRET_KEY_BASE=$(GITLAB_SECRETS_SECRET_KEY_BASE)" \
	--env="GITLAB_SECRETS_OTP_KEY_BASE=$(GITLAB_SECRETS_OTP_KEY_BASE)" \
	--env="DB_NAME=$(DB_NAME)" \
	--env="DB_USER=$(DB_USER)" \
	--env="DB_PASS=$(DB_PASS)" \
	--env="SMTP_PORT=$(SMTP_PORT)" \
	--env="SMTP_HOST=$(SMTP_HOST)" \
	--env="SMTP_OPENSSL_VERIFY_MODE=$(SMTP_OPENSSL_VERIFY_MODE)" \
	--env="SMTP_TLS=$(SMTP_TLS)" \
	--env="SMTP_STARTTLS=$(SMTP_STARTTLS)" \
	--env="SMTP_DOMAIN=$(SMTP_DOMAIN)" \
	--env="SMTP_PASS=$(SMTP_PASS)" \
	--env='GITLAB_HTTPS=false' \
	--env="SMTP_USER=$(SMTP_USER)" \
	--env="GITLAB_PORT=$(PORT)" \
	--env='GITLAB_SSH_PORT=$(SSH_PORT)' \
	--env='REDIS_URL=redis://redis:6379/12' \
	--volume=$(GITLAB_DATADIR):/home/git/data \
	--cidfile="gitlabCID" \
	$(TAG)

kill:
	-@docker kill `cat gitlabCID`
	-@docker kill `cat mysqlCID`
	-@docker kill `cat postgresCID`
	-@docker kill `cat redisCID`

killinit:
	-@docker kill `cat gitlabinitCID`
	-@docker kill `cat mysqlinitCID`
	-@docker kill `cat postgresinitCID`
	-@docker kill `cat redisinitCID`

rm-redimage:
	-@docker rm `cat gitlabCID`

rm-initimage:
	-@docker rm `cat gitlabinitCID`
	-@docker rm `cat mysqlinitCID`
	-@docker rm `cat postgresinitCID`
	-@docker rm `cat redisinitCID`

rm-image:
	-@docker rm `cat gitlabCID`
	-@docker rm `cat mysqlCID`
	-@docker rm `cat postgresCID`
	-@docker rm `cat redisCID`

rm-redcids:
	-@rm gitlabCID

rm-initcids:
	-@rm gitlabinitCID
	-@rm mysqlinitCID
	-@rm postgresinitCID
	-@rm redisinitCID

rm-cids:
	-@rm gitlabCID
	-@rm mysqlCID
	-@rm postgresCID
	-@rm redisCID

rmall: kill rm-image rm-cids

rm: kill rm-redimage rm-redcids

rminit: killinit rm-initimage rm-initcids

clean:  rm rminit rmall

initenter:
	docker exec -i -t `cat gitlabinitCID` /bin/bash

enter:
	docker exec -i -t `cat gitlabCID` /bin/bash

pgenter:
	docker exec -i -t `cat postgresCID` /bin/bash

grab: grabgitlabdir grabpostgresdatadir grabredisdatadir

mysqlgrab: grabgitlabdir grabmysqldatadir

externgrab: grabgitlabdir grabredisdatadir

grabpostgresdatadir:
	-@mkdir -p /exports/gitlab/postgresql
	docker cp `cat postgresinitCID`:/var/lib/postgresql  - |sudo tar -C /exports/gitlab/ -pxf -
	echo /exports/gitlab/postgresql > POSTGRES_DATADIR

grabmysqldatadir:
	-@mkdir -p /exports/gitlab/mysql
	docker cp `cat mysqlinitCID`:/var/lib/mysql  - |sudo tar -C /exports/gitlab/ -pxf -
	echo /exports/gitlab/mysql > MYSQL_DATADIR

grabgitlabdir:
	-@mkdir -p /exports/gitlab/git
	docker cp `cat gitlabinitCID`:/home/git/data  - |sudo tar -C /exports/gitlab/git/ -pxf -
	echo /exports/gitlab/gitlab/data > GITLAB_DATADIR

grabredisdatadir:
	-@mkdir -p /exports/gitlab/redis
	docker cp `cat redisinitCID`:/data  - |sudo tar -C /exports/datadir/redis/ -pxf -
	echo /exports/gitlab/redis > REDIS_DATADIR

logs:
	docker logs -f `cat gitlabCID`

initlogs:
	docker logs -f `cat gitlabinitCID`

templogs: initlogs

NAME:
	@while [ -z "$$NAME" ]; do \
		read -r -p "Enter the name you wish to associate with this container [NAME]: " NAME; echo "$$NAME">>NAME; cat NAME; \
	done ;

TAG:
	@while [ -z "$$TAG" ]; do \
		read -r -p "Enter the tag you wish to associate with this gitlab sameersbn/gitlab for example [TAG]: " TAG; echo "$$TAG">>TAG; cat TAG; \
	done ;

IP:
	@while [ -z "$$IP" ]; do \
		read -r -p "Enter the IP you wish to associate with this gitlab [IP]: " IP; echo "$$IP">>IP; cat IP; \
	done ;

DB_ADAPTER:
	@while [ -z "$$DB_ADAPTER" ]; do \
		read -r -p "Enter the DB_ADAPTER you wish to associate with this container [DB_ADAPTER]: " DB_ADAPTER; echo "$$DB_ADAPTER">>DB_ADAPTER; cat DB_ADAPTER; \
	done ;

DB_PASS:
	@while [ -z "$$DB_PASS" ]; do \
		read -r -p "Enter the DB_PASS you wish to associate with this container [DB_PASS]: " DB_PASS; echo "$$DB_PASS">>DB_PASS; cat DB_PASS; \
	done ;

DB_NAME:
	@while [ -z "$$DB_NAME" ]; do \
		read -r -p "Enter the DB_NAME you wish to associate with this container [DB_NAME]: " DB_NAME; echo "$$DB_NAME">>DB_NAME; cat DB_NAME; \
	done ;

DB_HOST:
	@while [ -z "$$DB_HOST" ]; do \
		read -r -p "Enter the DB_HOST you wish to associate with this container [DB_HOST]: " DB_HOST; echo "$$DB_HOST">>DB_HOST; cat DB_HOST; \
	done ;

DB_USER:
	@while [ -z "$$DB_USER" ]; do \
		read -r -p "Enter the DB_USER you wish to associate with this container [DB_USER]: " DB_USER; echo "$$DB_USER">>DB_USER; cat DB_USER; \
	done ;

SSH_PORT:
	@while [ -z "$$SSH_PORT" ]; do \
		read -r -p "Enter the SSH_PORT you wish to associate with this container [SSH_PORT]: " SSH_PORT; echo "$$SSH_PORT">>SSH_PORT; cat SSH_PORT; \
	done ;

SMTP_PORT:
	@while [ -z "$$SMTP_PORT" ]; do \
		read -r -p "Enter the SMTP_PORT you wish to associate with this container [SMTP_PORT]: " SMTP_PORT; echo "$$SMTP_PORT">>SMTP_PORT; cat SMTP_PORT; \
	done ;

SMTP_DOMAIN:
	@while [ -z "$$SMTP_DOMAIN" ]; do \
		read -r -p "Enter the SMTP_DOMAIN you wish to associate with this container [SMTP_DOMAIN]: " SMTP_DOMAIN; echo "$$SMTP_DOMAIN">>SMTP_DOMAIN; cat SMTP_DOMAIN; \
	done ;

SMTP_TLS:
	@while [ -z "$$SMTP_TLS" ]; do \
		read -r -p "Enter the SMTP_TLS you wish to associate with this container [SMTP_TLS]: " SMTP_TLS; echo "$$SMTP_TLS">>SMTP_TLS; cat SMTP_TLS; \
	done ;

SMTP_STARTTLS:
	@while [ -z "$$SMTP_STARTTLS" ]; do \
		read -r -p "Enter the SMTP_STARTTLS you wish to associate with this container [SMTP_STARTTLS]: " SMTP_STARTTLS; echo "$$SMTP_STARTTLS">>SMTP_STARTTLS; cat SMTP_STARTTLS; \
	done ;

SMTP_OPENSSL_VERIFY_MODE:
	@while [ -z "$$SMTP_OPENSSL_VERIFY_MODE" ]; do \
		read -r -p "Enter the SMTP_OPENSSL_VERIFY_MODE you wish to associate with this container [SMTP_OPENSSL_VERIFY_MODE]: " SMTP_OPENSSL_VERIFY_MODE; echo "$$SMTP_OPENSSL_VERIFY_MODE">>SMTP_OPENSSL_VERIFY_MODE; cat SMTP_OPENSSL_VERIFY_MODE; \
	done ;

SMTP_HOST:
	@while [ -z "$$SMTP_HOST" ]; do \
		read -r -p "Enter the SMTP_HOST you wish to associate with this container [SMTP_HOST]: " SMTP_HOST; echo "$$SMTP_HOST">>SMTP_HOST; cat SMTP_HOST; \
	done ;

SMTP_PASS:
	@while [ -z "$$SMTP_PASS" ]; do \
		read -r -p "Enter the SMTP_PASS you wish to associate with this container [SMTP_PASS]: " SMTP_PASS; echo "$$SMTP_PASS">>SMTP_PASS; cat SMTP_PASS; \
	done ;

SMTP_USER:
	@while [ -z "$$SMTP_USER" ]; do \
		read -r -p "Enter the SMTP_USER you wish to associate with this container [SMTP_USER]: " SMTP_USER; echo "$$SMTP_USER">>SMTP_USER; cat SMTP_USER; \
	done ;

PORT:
	@while [ -z "$$PORT" ]; do \
		read -r -p "Enter the port you wish to associate with this container [PORT]: " PORT; echo "$$PORT">>PORT; cat PORT; \
	done ;

example:
	cp -i TAG.example TAG
	curl icanhazip.com > IP
	echo 'false' > SMTP_TLS
	echo 'true' > SMTP_STARTTLS
	echo 'smtp.gmail.com' > SMTP_HOST
	echo 'www.gmail.com' > SMTP_DOMAIN
	echo '587' > SMTP_PORT
	echo '7022' > SSH_PORT
	echo '7080' > PORT
	touch SMTP_OPENSSL_VERIFY_MODE

GITLAB_SECRETS_SECRET_KEY_BASE:
	pwgen -Bsv1 64 > GITLAB_SECRETS_SECRET_KEY_BASE

GITLAB_SECRETS_DB_KEY_BASE:
	pwgen -Bsv1 64 > GITLAB_SECRETS_DB_KEY_BASE

GITLAB_SECRETS_OTP_KEY_BASE:
	pwgen -Bsv1 64 > GITLAB_SECRETS_OTP_KEY_BASE
