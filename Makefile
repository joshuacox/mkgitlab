.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs
######################################REDMINIT

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container

build: builddocker

link: linkedmysqlrun

init: TAG IP SMTP_HOST SMTP_PORT SMTP_PASS SMTP_USER DB_USER DB_NAME DB_PASS NAME PORT rmall runpostgresinit runredisinit runredminit

run: TAG IP SMTP_DOMAIN SMTP_OPENSSL_VERIFY_MODE SMTP_HOST SMTP_PORT SMTP_PASS SMTP_USER DB_NAME DB_PASS NAME PORT rmall runpostgres runredis runredmine

runbuild: TAG IP builddocker runpostgres runredis runredminit

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
	--cidfile="postgresinitCID" \
	--env='DB_USER=$(DB_USER)' --env="DB_PASS=$(DB_PASS)" \
	sameersbn/postgresql:9.4

runmysqlinit:
	$(eval NAME := $(shell cat NAME))
	$(eval DB_USER := $(shell cat DB_USER))
	$(eval DB_PASS := $(shell cat DB_PASS))
	$(eval DB_NAME := $(shell cat DB_NAME))
	docker run \
	--name=$(NAME)-mysql-init \
	-d \
	--env='DB_NAME=$(DB_NAME)' \
	--cidfile="mysqlinitCID" \
	--env='MYSQL_USER=$(DB_USER)' --env="MYSQL_ROOT_PASSWORD=$(DB_PASS)" \
	--env="MYSQL_PASSWORD=$(DB_PASS)" \
	--env="MYSQL_DATABASE=$(DB_NAME)" \
	mysql:5.6

externrunredminit:
	$(eval TAG := $(shell cat TAG))
	$(eval IP := $(shell cat IP))
	$(eval NAME := $(shell cat NAME))
	$(eval PORT := $(shell cat PORT))
	$(eval DB_NAME := $(shell cat DB_NAME))
	$(eval DB_HOST := $(shell cat DB_HOST))
	$(eval DB_USER := $(shell cat DB_USER))
	$(eval SMTP_PORT := $(shell cat SMTP_PORT))
	$(eval SMTP_HOST := $(shell cat SMTP_HOST))
	$(eval SMTP_PASS := $(shell cat SMTP_PASS))
	$(eval SMTP_USER := $(shell cat SMTP_USER))
	$(eval DB_ADAPTER := $(shell cat DB_ADAPTER))
	$(eval DB_PASS := $(shell cat DB_PASS))
	docker run --name=$(NAME) \
	-d \
	--publish=$(IP):$(PORT):80 \
	--link=$(NAME)-redis-init:redis \
	--env="REDMINE_PORT=$(PORT)" \
	--env='REDIS_URL=redis://redis:6379/12' \
	--env="DB_NAME=$(DB_NAME)" \
	--env="DB_HOST=$(DB_HOST)" \
	--env="DB_USER=$(DB_USER)" \
	--env="SMTP_PORT=$(SMTP_PORT)" \
	--env="SMTP_HOST=$(SMTP_HOST)" \
	--env="SMTP_PASS=$(SMTP_PASS)" \
	--env="SMTP_USER=$(SMTP_USER)" \
	--env="DB_ADAPTER=$(DB_ADAPTER)" \
	--env="DB_PASS=$(DB_PASS)" \
	--cidfile="redmineinitCID" \
	$(TAG)

runredminit:
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval IP := $(shell cat IP))
	$(eval PORT := $(shell cat PORT))
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
	--link=$(NAME)-redis-init:redis \
	--publish=$(IP):$(PORT):80 \
	--env="DB_NAME=$(DB_NAME)" \
	--env="DB_USER=$(DB_USER)" \
	--env="DB_PASS=$(DB_PASS)" \
	--env="REDMINE_PORT=$(PORT)" \
	--env="SMTP_PORT=$(SMTP_PORT)" \
	--env="SMTP_HOST=$(SMTP_HOST)" \
	--env="SMTP_PASS=$(SMTP_PASS)" \
	--env="SMTP_USER=$(SMTP_USER)" \
	--env='REDIS_URL=redis://redis:6379/12' \
	--cidfile="redmineinitCID" \
	$(TAG)

mysqlrunredminit:
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval IP := $(shell cat IP))
	$(eval PORT := $(shell cat PORT))
	$(eval SMTP_PASS := $(shell cat SMTP_PASS))
	$(eval SMTP_USER := $(shell cat SMTP_USER))
	$(eval SMTP_PORT := $(shell cat SMTP_PORT))
	$(eval SMTP_HOST := $(shell cat SMTP_HOST))
	docker run --name=$(NAME) \
	-d \
	--link=$(NAME)-mysql-init:mysql \
	--publish=$(IP):$(PORT):80 \
	--env="REDMINE_PORT=$(PORT)" \
	--env="SMTP_PORT=$(SMTP_PORT)" \
	--env="SMTP_HOST=$(SMTP_HOST)" \
	--env="SMTP_PASS=$(SMTP_PASS)" \
	--env="SMTP_USER=$(SMTP_USER)" \
	--cidfile="redmineinitCID" \
	$(TAG)

#	sameersbn/redmine:2.6-latest
# used to be last line above --> 	-t joshuacox/redminit
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
	--env='DB_USER=$(DB_USER)' --env="DB_PASS=$(DB_PASS)" \
	--volume=$(POSTGRES_DATADIR):/var/lib/postgresql/ \
	sameersbn/postgresql:9.4

runmysql:
	$(eval NAME := $(shell cat NAME))
	$(eval DB_USER := $(shell cat DB_USER))
	$(eval DB_PASS := $(shell cat DB_PASS))
	$(eval DB_NAME := $(shell cat DB_NAME))
	$(eval MYSQL_DATADIR := $(shell cat MYSQL_DATADIR))
	docker run \
	--name=$(NAME)-mysql \
	-d \
	--env='DB_NAME=$(DB_NAME)' \
	--cidfile="mysqlCID" \
	--env='MYSQL_USER=$(DB_USER)' --env="MYSQL_ROOT_PASSWORD=$(DB_PASS)" \
	--env="MYSQL_PASSWORD=$(DB_PASS)" \
	--volume=$(MYSQL_DATADIR):/var/lib/mysql \
	mysql:5.6

externrunredmine:
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval IP := $(shell cat IP))
	$(eval PORT := $(shell cat PORT))
	$(eval REDMINE_DATADIR := $(shell cat REDMINE_DATADIR))
	$(eval DB_NAME := $(shell cat DB_NAME))
	$(eval DB_HOST := $(shell cat DB_HOST))
	$(eval DB_USER := $(shell cat DB_USER))
	$(eval DB_ADAPTER := $(shell cat DB_ADAPTER))
	$(eval DB_PASS := $(shell cat DB_PASS))
	$(eval SMTP_PASS := $(shell cat SMTP_PASS))
	$(eval SMTP_USER := $(shell cat SMTP_USER))
	$(eval SMTP_PORT := $(shell cat SMTP_PORT))
	$(eval SMTP_HOST := $(shell cat SMTP_HOST))
	$(eval SMTP_DOMAIN := $(shell cat SMTP_DOMAIN))
	docker run --name=$(NAME) \
	-d \
	--link=$(NAME)-redis:redis \
	--publish=$(IP):$(PORT):80 \
	--env="DB_NAME=$(DB_NAME)" \
	--env="DB_HOST=$(DB_HOST)" \
	--env="DB_USER=$(DB_USER)" \
	--env="SMTP_PASS=$(SMTP_PASS)" \
	--env="SMTP_USER=$(SMTP_USER)" \
	--env="SMTP_PORT=$(SMTP_PORT)" \
	--env="SMTP_HOST=$(SMTP_HOST)" \
	--env="SMTP_DOMAIN=$(SMTP_DOMAIN)" \
	--env="DB_ADAPTER=$(DB_ADAPTER)" \
	--env="DB_PASS=$(DB_PASS)" \
	--env='REDMINE_HTTPS=true' \
	--env="REDMINE_PORT=$(PORT)" \
	--env='REDIS_URL=redis://redis:6379/12' \
	--volume=$(REDMINE_DATADIR):/home/redmine/data \
	--cidfile="redmineCID" \
	$(TAG)

runredmine:
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval IP := $(shell cat IP))
	$(eval PORT := $(shell cat PORT))
	$(eval REDMINE_DATADIR := $(shell cat REDMINE_DATADIR))
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
	--link=$(NAME)-redis:redis \
	--publish=$(IP):$(PORT):80 \
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
	--env='REDMINE_HTTPS=true' \
	--env="SMTP_USER=$(SMTP_USER)" \
	--env="REDMINE_PORT=$(PORT)" \
	--env='REDIS_URL=redis://redis:6379/12' \
	--volume=$(REDMINE_DATADIR):/home/redmine/data \
	--cidfile="redmineCID" \
	$(TAG)

mysqlrunredmine:
	$(eval NAME := $(shell cat NAME))
	$(eval PORT := $(shell cat PORT))
	$(eval REDMINE_DATADIR := $(shell cat REDMINE_DATADIR))
	$(eval SMTP_PASS := $(shell cat SMTP_PASS))
	$(eval SMTP_USER := $(shell cat SMTP_USER))
	docker run --name=$(NAME) \
	-d \
	--link=$(NAME)-mysql:mysql \
	--publish=$(PORT):80 \
	--env="SMTP_PASS=$(SMTP_PASS)" \
	--env="SMTP_USER=$(SMTP_USER)" \
	--env="REDMINE_PORT=$(PORT)" \
	--env='REDMINE_HTTPS=true' \
	--env='REDIS_URL=redis://redis:6379/12' \
	--volume=$(REDMINE_DATADIR):/home/redmine/data \
	--cidfile="redmineCID" \
	$(TAG)

linkedmysqlrunredmine:
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval IP := $(shell cat IP))
	$(eval PORT := $(shell cat PORT))
	$(eval REDMINE_DATADIR := $(shell cat REDMINE_DATADIR))
	$(eval SMTP_PASS := $(shell cat SMTP_PASS))
	$(eval SMTP_USER := $(shell cat SMTP_USER))
	$(eval DB_NAME := $(shell cat DB_NAME))
	$(eval DB_HOST := $(shell cat DB_HOST))
	$(eval DB_USER := $(shell cat DB_USER))
	$(eval DB_ADAPTER := $(shell cat DB_ADAPTER))
	$(eval DB_PASS := $(shell cat DB_PASS))
	docker run --name=$(NAME) \
	-d \
	--link=$(NAME)-mysql:mysql \
	--env="DB_NAME=$(DB_NAME)" \
	--env="DB_HOST=$(DB_HOST)" \
	--env="DB_USER=$(DB_USER)" \
	--env="SMTP_PASS=$(SMTP_PASS)" \
	--env="SMTP_USER=$(SMTP_USER)" \
	--env="DB_ADAPTER=$(DB_ADAPTER)" \
	--env="DB_PASS=$(DB_PASS)" \
	--env='REDMINE_HTTPS=true' \
	--env="REDMINE_PORT=$(PORT)" \
	--publish=$(IP):$(PORT):80 \
	--volume=$(REDMINE_DATADIR):/home/redmine/data \
	--cidfile="redmineCID" \
	$(TAG)

builddocker:
	/usr/bin/time -v docker build -t joshuacox/redminit .

kill:
	-@docker kill `cat redmineCID`
	-@docker kill `cat mysqlCID`
	-@docker kill `cat postgresCID`
	-@docker kill `cat redisCID`

killinit:
	-@docker kill `cat redmineinitCID`
	-@docker kill `cat mysqlinitCID`
	-@docker kill `cat postgresinitCID`
	-@docker kill `cat redisinitCID`

rm-redimage:
	-@docker rm `cat redmineCID`

rm-initimage:
	-@docker rm `cat redmineinitCID`
	-@docker rm `cat mysqlinitCID`
	-@docker rm `cat postgresinitCID`
	-@docker rm `cat redisinitCID`

rm-image:
	-@docker rm `cat redmineCID`
	-@docker rm `cat mysqlCID`
	-@docker rm `cat postgresCID`
	-@docker rm `cat redisCID`

rm-redcids:
	-@rm redmineCID

rm-initcids:
	-@rm redmineinitCID
	-@rm mysqlinitCID
	-@rm postgresinitCID
	-@rm redisinitCID

rm-cids:
	-@rm redmineCID
	-@rm mysqlCID
	-@rm postgresCID
	-@rm redisCID

rmall: kill rm-image rm-cids

rm: kill rm-redimage rm-redcids

rminit: killinit rm-initimage rm-initcids

clean:  rm

initenter:
	docker exec -i -t `cat redmineinitCID` /bin/bash

enter:
	docker exec -i -t `cat redmineCID` /bin/bash

pgenter:
	docker exec -i -t `cat postgresCID` /bin/bash

grab: grabredminedir grabpostgresdatadir grabredisdatadir

mysqlgrab: grabredminedir grabmysqldatadir

externgrab: grabredminedir grabredisdatadir

grabpostgresdatadir:
	-@mkdir -p datadir/postgresql
	docker cp `cat postgresinitCID`:/var/lib/postgresql  - |sudo tar -C datadir -pxf -
	echo `pwd`/datadir/postgresql > POSTGRES_DATADIR

grabmysqldatadir:
	-@mkdir -p datadir/mysql
	docker cp `cat mysqlinitCID`:/var/lib/mysql  - |sudo tar -C datadir/ -pxf -
	echo `pwd`/datadir/mysql > MYSQL_DATADIR

grabredminedir:
	-@mkdir -p datadir/redmine
	docker cp `cat redmineinitCID`:/home/redmine/data  - |sudo tar -C datadir/redmine/ -pxf -
	echo `pwd`/datadir/redmine/data > REDMINE_DATADIR

grabredisdatadir:
	-@mkdir -p datadir/redis
	docker cp `cat redisinitCID`:/data  - |sudo tar -C datadir/redis/ -pxf -
	echo `pwd`/datadir/redis > REDIS_DATADIR

logs:
	docker logs -f `cat redmineCID`

initlogs:
	docker logs -f `cat redmineinitCID`

NAME:
	@while [ -z "$$NAME" ]; do \
		read -r -p "Enter the name you wish to associate with this container [NAME]: " NAME; echo "$$NAME">>NAME; cat NAME; \
	done ;

TAG:
	@while [ -z "$$TAG" ]; do \
		read -r -p "Enter the tag you wish to associate with this redmine sameersbn/redmine for example [TAG]: " TAG; echo "$$TAG">>TAG; cat TAG; \
	done ;

IP:
	@while [ -z "$$IP" ]; do \
		read -r -p "Enter the IP you wish to associate with this redmine [IP]: " IP; echo "$$IP">>IP; cat IP; \
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

externaldbinfo:
	-@echo "go here https://github.com/sameersbn/docker-redmine#postgresql to learn about the variables necessary to setup this instance"
	-@sleep 5

executeEmailRakeTask:
	@cat emailRakeTask
	@bash emailRakeTask

emailRakeTask:
	$(eval NAME := $(shell cat NAME))
	$(eval SMTP_PASS := $(shell cat SMTP_PASS))
	$(eval SMTP_USER := $(shell cat SMTP_USER))
	$(eval SMTP_PORT := $(shell cat SMTP_PORT))
	$(eval SMTP_HOST := $(shell cat SMTP_HOST))
	$(eval SMTP_OPENSSL_VERIFY_MODE := $(shell cat SMTP_OPENSSL_VERIFY_MODE))
	$(eval SMTP_TLS := $(shell cat SMTP_TLS))
	$(eval SMTP_STARTTLS := $(shell cat SMTP_STARTTLS))
	echo -n "docker exec -it $(NAME) ">emailRakeTask
	echo -n " sudo -u redmine -H bundle exec rake redmine:email:receive_imap RAILS_ENV='production' ">>emailRakeTask
	echo -n " host=$(SMTP_HOST) port=$(SMTP_PORT) ssl=$(SMTP_TLS) username=$(SMTP_USER) password=$(SMTP_PASS) ">>emailRakeTask
	echo -n " starttls=$(SMTP_STARTTLS) ">>emailRakeTask
	echo -n " folder=Inbox move_on_success=SUCCESS move_on_failure=failed project=contact tracker=support ">>emailRakeTask
	echo -n " allow_override=priority,tracker,project no_permission_check=1 ">>emailRakeTask
	echo " no_account_notice=1">>emailRakeTask
	chmod +x emailRakeTask

checkEmail: emailRakeTask executeEmailRakeTask

backlogs:
	$(eval REDMINE_DATADIR := $(shell cat REDMINE_DATADIR))
	cd $(REDMINE_DATADIR)/plugins ; \
	git clone https://github.com/backlogs/redmine_backlogs.git 
	cd $(REDMINE_DATADIR)/plugins/redmine_backlogs ; \
	git checkout feature/redmine3 ; \
	sed -i 's/gem "nokogiri"/#gem "nokogiri"/' Gemfile
	sed -i 's/gem "capybara"/#gem "capybara"/' Gemfile
	chown -R 1000:1000 $(REDMINE_DATADIR)/plugins
	rm -Rf $(REDMINE_DATADIR)/tmp

crmagile:
	$(eval REDMINE_DATADIR := $(shell cat REDMINE_DATADIR))
	cd $(REDMINE_DATADIR)/plugins ; \
	git clone https://github.com/RCRM/redmine_agile.git
	chown -R 1000:1000 $(REDMINE_DATADIR)/plugins
	rm -Rf $(REDMINE_DATADIR)/tmp

scrum:
	$(eval REDMINE_DATADIR := $(shell cat REDMINE_DATADIR))
	cd $(REDMINE_DATADIR)/plugins ; \
	wget https://redmine.ociotec.com/attachments/download/384/scrum%20v0.14.0.tar.gz; \
	tar zxvf scrum\ v0.14.0.tar.gz ; \
	rm scrum\ v0.14.0.tar.gz ; \
	mv scrum\ v0.14.0 scrum
	chown -R 1000:1000 $(REDMINE_DATADIR)/plugins
	rm -Rf $(REDMINE_DATADIR)/tmp

example:
	cp -i TAG.example TAG
	curl icanhazip.com > IP
	echo 'false' > SMTP_TLS
	echo 'true' > SMTP_STARTTLS
	echo 'smtp.gmail.com' > SMTP_HOST
	echo 'www.gmail.com' > SMTP_DOMAIN
	echo '587' > SMTP_PORT
	touch 	SMTP_OPENSSL_VERIFY_MODE

next: grab rminit run

theme:
	$(eval REDMINE_DATADIR := $(shell cat REDMINE_DATADIR))
	cd $(REDMINE_DATADIR)/themes ; \
	git clone https://github.com/Thalhalla/NeoArchaicRedmineTheme.git ; \
	chown -R 1000:1000 $(REDMINE_DATADIR)/themes
	rm -Rf $(REDMINE_DATADIR)/tmp
