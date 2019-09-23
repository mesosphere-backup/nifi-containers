#!/usr/bin/env bash

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

	../nifi-toolkit-current/bin/tls-toolkit.sh standalone \
		--certificateAuthorityHostname ${PKI_HOST}:19443 \
		--clientCertDn ${CLIENTCERTDN} \
		--subjectAlternativeNames ${PKI_SAN} \
		--isOverwrite \
		--hostnames ${HOSTNAME}

	mv ${HOSTNAME}/keystore.jks ${NF_KEYS_PATH}/keystore.jks
	mv ${HOSTNAME}/truststore.jks ${NF_KEYS_PATH}/truststore.jks

	export NF_NIFI_SECURITY_KEYSTOREPASSWD=$(cat ${HOSTNAME}/nifi.properties | grep keystorePasswd | cut -d"=" -f2)
	export NF_NIFI_SECURITY_KEYPASSWD=$(cat ${HOSTNAME}/nifi.properties | grep keyPasswd | cut -d"=" -f2)
	export NF_NIFI_SECURITY_TRUSTSTOREPASSWD=$(cat ${HOSTNAME}/nifi.properties | grep truststorePasswd | cut -d"=" -f2)
	export NF_NIFI_SECURITY_KEYSTORETYPE=$(cat ${HOSTNAME}/nifi.properties | grep keystoreType | cut -d"=" -f2)
	export NF_NIFI_SECURITY_TRUSTSTORETYPE=$(cat ${HOSTNAME}/nifi.properties | grep truststoreType | cut -d"=" -f2)
	export NF_NIFI_SECURITY_TRUSTSTORE=${NF_KEYS_PATH}/truststore.jks
	export NF_NIFI_SECURITY_KEYSTORE=${NF_KEYS_PATH}/keystore.jks

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
	NF_NIFI_WEB_PROXY_HOST="${HOSTNAME}:${NF_NIFI_WEB_HTTPS_PORT},${NF_NIFI_WEB_PROXY_HOST}"

	# Build the nifi.properties file, remove it if present
	if [[ -f ${NIFI_HOME}/conf/nifi.properties ]];then
		rm -f ${NIFI_HOME}/conf/nifi.properties
	fi

	${scripts_dir}/setprops mkiniconf -p NF_ -d ${NIFI_HOME}/conf/ -t nifi.properties.j2 -c ${NIFI_HOME}/conf/nifi.properties

}

showconfig(){
	# print config information if the DEBUG var is set to True
	prdebug "NiFi properties:"
	prdebug "$(cat ${NIFI_HOME}/conf/nifi.properties)"
	prdebug " "
}

#unset bash debug
if [[ ${DEBUG} == "True" ]]; then
	set +x
fi

makecert
makeconfig
showconfig

# Run NiFi
tail -F "${NIFI_HOME}/logs/nifi-app.log" &
"${NIFI_HOME}/bin/nifi.sh" run &
nifi_pid="$!"

trap "echo Received trapped signal, beginning shutdown...;" KILL TERM HUP INT EXIT;

echo NiFi running with PID ${nifi_pid}.
wait ${nifi_pid}

