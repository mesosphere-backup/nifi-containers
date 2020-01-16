#!/usr/bin/env bash
# Copyright (c) 2019 Martijn Dekkers, D2iQ.
# Licensed under the Apache 2.0 License
# Martijn Dekkers <mdekkers@d2iq.com>


# Load script variables
scripts_dir='/opt/nifi/scripts'

# set bash debug
if [[ ${DEBUG} == "True" ]]; then
	set -x
fi

prdebug(){
	if [[ ${DEBUG} == "True" ]];then
		echo "[DEBUG] [$(date +%F\ %T)] $1 $2"
	fi
}

makecert(){

	# Make the PKI_SAN list
	for name in "${!SAN_HOST@}";do
		sanlist="${!name},${sanlist}"
	done

	PKI_SAN=${sanlist%?}

	prdebug "PKI SAN List: ${PKI_SAN}"

	cp /mnt/mesos/sandbox/nifi-key.key .
	cp /mnt/mesos/sandbox/nifi-cert.pem .
	cp /mnt/mesos/sandbox/caroot.pem .
	../nifi-toolkit-current/bin/tls-toolkit.sh standalone \
		--certificateAuthorityHostname "${PKI_HOST}":19443 \
		--clientCertDn "${CLIENTCERTDN}" \
		--subjectAlternativeNames "${PKI_SAN}" \
		--isOverwrite \
		-o . \
		--additionalCACertificate caroot.pem \
		--hostnames "${HOSTNAME}"

	mv "${HOSTNAME}"/keystore.jks "${NF_KEYS_PATH}"/keystore.jks
	mv "${HOSTNAME}"/truststore.jks "${NF_KEYS_PATH}"/truststore.jks

	NIFI_SECURITY_KEYSTOREPASSWD="$(grep keystorePasswd "${HOSTNAME}"/nifi.properties | cut -d"=" -f2)"
	NIFI_SECURITY_KEYPASSWD="$(grep keyPasswd "${HOSTNAME}"/nifi.properties | cut -d"=" -f2)"
	NIFI_SECURITY_TRUSTSTOREPASSWD="$(grep truststorePasswd "${HOSTNAME}"/nifi.properties | cut -d"=" -f2)"
	NIFI_SECURITY_KEYSTORETYPE="$(grep keystoreType "${HOSTNAME}"/nifi.properties | cut -d"=" -f2)"
	NIFI_SECURITY_TRUSTSTORETYPE="$(grep truststoreType "${HOSTNAME}"/nifi.properties | cut -d"=" -f2)"
	NIFI_SECURITY_TRUSTSTORE="${NF_KEYS_PATH}/truststore.jks"
	NIFI_SECURITY_KEYSTORE="${NF_KEYS_PATH}/keystore.jks"

	export NIFI_SECURITY_KEYSTOREPASSWD
	export NIFI_SECURITY_KEYPASSWD
	export NIFI_SECURITY_TRUSTSTOREPASSWD
	export NIFI_SECURITY_KEYSTORETYPE
	export NIFI_SECURITY_TRUSTSTORETYPE
	export NIFI_SECURITY_TRUSTSTORE
	export NIFI_SECURITY_KEYSTORE

	# Make consumable client certificates
	openssl pkcs12 -in "${CLIENTCERTDN/,/_}.p12" -out newfile.crt.pem -clcerts -nokeys -password file:"${CLIENTCERTDN/,/_}.password"
	openssl pkcs12 -in "${CLIENTCERTDN/,/_}.p12" -out newfile.key.pem -nocerts -nodes -password file:"${CLIENTCERTDN/,/_}.password"

	prdebug "Client cert:"
	prdebug "$(cat newfile.crt.pem)"
	prdebug "Client key:"
	prdebug "$(cat newfile.key.pem)"
}

makeconfig(){

	# We need some variables wrangled
	# TODO: FixMe - make HTTP and HTTPS versions
	NIFI_WEB_PROXY_HOST="${HOSTNAME}:${NIFI_WEB_HTTPS_PORT},${NIFI_WEB_PROXY_HOST}"

	# Build the nifi.properties file, remove it if present
	if [[ -f ${NIFI_HOME}/conf/nifi.properties ]];then
		rm -f "${NIFI_HOME}"/conf/nifi.properties
	fi

	${scripts_dir}/j2 --undefined "${NIFI_HOME}"/conf/bootstrap.conf.j2 -o "${NIFI_HOME}"/conf/bootstrap.conf
	${scripts_dir}/j2 --undefined "${NIFI_HOME}"/conf/nifi.properties.j2 -o "${NIFI_HOME}"/conf/nifi.properties
	${scripts_dir}/j2 --undefined "${NIFI_HOME}"/conf/login-identity-providers.xml.j2 -o "${NIFI_HOME}"/conf/login-identity-providers.xml
	${scripts_dir}/j2 --undefined "${NIFI_HOME}"/conf/authorizers.xml.j2 -o "${NIFI_HOME}"/conf/authorizers.xml
	${scripts_dir}/j2 --undefined "${NIFI_HOME}"/conf/zookeeper.properties.j2 -o "${NIFI_HOME}"/conf/zookeeper.properties
}

showconfig(){
	# print config information if the DEBUG var is set to True
	prdebug "NiFi properties:"
	prdebug "$(cat "${NIFI_HOME}"/conf/nifi.properties)"
	prdebug " "
		prdebug "Bootstrap Config"
	prdebug "$(cat "${NIFI_HOME}"/conf/bootstrap.conf)"
	prdebug " "
		prdebug "Login ID Providers:"
	prdebug "$(cat "${NIFI_HOME}"/conf/login-identity-providers.xml)"
	prdebug " "
		prdebug "Authorizers:"
	prdebug "$(cat "${NIFI_HOME}"/conf/authorizers.xml)"
	prdebug " "
		prdebug "Zookeeper properties:"
	prdebug "$(cat "${NIFI_HOME}"/conf/zookeeper.properties)"
	prdebug " "
}

makecert
makeconfig
showconfig

#unset bash debug
if [[ ${DEBUG} == "True" ]]; then
	set +x
fi

# Run NiFi
tail -F "${NIFI_HOME}/logs/nifi-app.log" &
"${NIFI_HOME}/bin/nifi.sh" run &
nifi_pid="$!"

trap "echo Received trapped signal, beginning shutdown...;" KILL TERM HUP INT EXIT;

echo NiFi running with PID ${nifi_pid}.
wait ${nifi_pid}
