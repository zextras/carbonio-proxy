DOMAIN=.demo.zextras.io

clean:
	mvn clean

compile:
	mvn package -DskipTests

test:
	mvn package

oa-schema:
	mvn io.smallrye:smallrye-open-api-maven-plugin:generate-schema \
		-Dskip.open-api.schema.generation=false

sys-status:
	ssh root@${HOST}${DOMAIN} "systemctl status carbonio-storages"

sys-stop:
	ssh root@${HOST}${DOMAIN} "systemctl stop carbonio-storages"

sys-start:
	ssh root@${HOST}${DOMAIN} "systemctl start carbonio-storages"

upload:
	ssh root@${HOST}${DOMAIN} "rm -rf /usr/share/carbonio/carbonio-storages/*"
	rsync -acz target/quarkus-app/* root@${HOST}${DOMAIN}:/usr/share/carbonio/carbonio-storages/

sys-install: clean compile
	./build_packages.sh
	./install_packages.sh ${HOST}${DOMAIN}

sys-deploy: clean compile sys-stop upload sys-start

.PHONY: clean compile test sys-status sys-stop sys-start upload sys-install sys-deploy