#!/usr/bin/env bash

showconfig() {

	echo ""
	echo "*************************************************************************"
	echo "Configuration Data (COPY AND KEEP IN A SAFE PLACE)"
	cat ./config.json
	echo "*************************************************************************"
	echo ""

}

toolkit_init(){
	if [[ -z ${PKI_DN} ]] || [[ -z ${PKI_PORT} ]] || [[ -z ${PKI_TOKEN} ]]; then
	 echo "Incorrect configuration!"
	 echo "PKI_DN must be set to the marathon l4b hostname for this container"
	 echo "PKI_PORT must be set to the port for this container"
	 echo "PKI_TOKEN must be set to a complex token that should be shared with all nifi systems"
	 echo ""
	 echo "Sleeping to avoid a container restart loop. Supply the correct configuration and restart the service"
	 sleep infinity
	 exit
	fi

	rm config.json
	rm nifi-ca-keystore.jks
	echo "All data wiped!!"
	timeout 5 ../bin/tls-toolkit.sh server --dn ${PKI_DN} -t ${PKI_TOKEN} --PORT ${PKI_PORT}
	showconfig

}

if [[ ${DEBUG} == "True" ]]; then
	set -x
fi


# Check if first run or wipe is required
if [[ ! -f ./config.json || ${RUNMODE} == "Wipe" ]]; then
	echo "Initialising TLS-Toolkit"
	toolkit_init
fi


if [[ ${DEBUG} == "True" ]]; then
	set +x
fi

"../bin/tls-toolkit.sh" server -F config.json &
pki_pid="$!"

trap "echo Received trapped signal, beginning shutdown...;" KILL TERM HUP INT EXIT;

echo ""
echo NiFi TLS-Toolkit Server running with PID ${pki_pid}.
echo ""

wait ${pki_pid}
