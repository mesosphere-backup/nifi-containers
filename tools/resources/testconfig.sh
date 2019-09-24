#!/usr/bin/env bash

# Copyright (c) 2019 Martijn Dekkers, D2iQ.
# Licensed under the Apache 2.0 License
# Martijn Dekkers <mdekkers@d2iq.com>

# This file is sourced from toolmaker.sh to set test variables
# Edit as required for your project

setconfig() {

	case $theapp in
		certificator)

			# Certificator requires a DCOS service user with "dcos:adminrouter:ops:ca:rw full"
			# permissions, with a corresponding private key.

			cluster="http://md190819pmsv-1313860270.us-west-2.elb.amazonaws.com"
			svcusr="certgetter"
			svckey="resources/certgetter-priv.pem"
			certcn="tester.build.local"
			certhost="tester.build.local"
			;;

	esac
}
