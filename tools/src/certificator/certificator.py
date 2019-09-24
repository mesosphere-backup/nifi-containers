# Copyright (c) 2019 Martijn Dekkers, D2iQ.
# Licensed under the Apache 2.0 License
# Martijn Dekkers <mdekkers@d2iq.com>

import os
import OpenSSL.crypto
import click
import requests
import json
import jks
import warnings
import jwt
import datetime
warnings.filterwarnings("ignore")


@click.group()
def cli():
    pass


@cli.command()
@click.option(
    '--debug/--no-debug',
    envvar='CRT_DEBUG',
    default=False
)
@click.option(
    '--cluster',
    '-c',
    help='URL for the cluster',
    default='https://master.mesos'
)
@click.option(
    '--username',
    '-u',
    help='The username to fetch the JWT token for'
)
@click.option(
    '--userkey',
    '-k',
    help='The path to the private key to use.',
)
@click.option(
    '--cn',
    help='Canonical Name.',
    required=True
)
@click.option(
    '--key-algo',
    help='Key algorithm.',
    default='rsa',
    type=click.Choice(['rsa', 'ecdsa'])
)
@click.option(
    '--key-size',
    help='Key size.',
    default="2048",
    type=click.Choice(["256", "384", "521", "2048", "4096", "8192"])
)
@click.option(
    '--host',
    help='SAN host',
    required=True
)
@click.option(
    '--ks',
    is_flag=True,
    help='Create java key and trust stores'
)
@click.option(
    '--ks-path',
    help='Path to the key and truststores. The names of the '
         'key and trustores will always be keystore.jks and trustore.jsk'
)
def getcert(debug, cluster, username, userkey, cn, host, key_algo, key_size, ks, ks_path):
    if debug:
        click.echo("certificator debug is on", err=True)

    click.echo("Getcert requested:")
    # Get access to the cluster
    token = fetchtoken(debug, cluster, username, userkey)

    # Set the API endpoint to get a new CSR
    api_endpoint = '/ca/api/v2/newkey'
    newkeyapi = cluster + api_endpoint

    # Prepare the request payload
    newkeyheaders = {'Content-Type': 'application/json', 'Authorization': 'token=' + token}
    newkeypayload = '{"hosts": ["' + host + '"], "CN":"' + cn + '","key": {"algo": "' + key_algo + '","size": ' + key_size + '}}'

    # Submit a CSR
    click.echo("...Submitting CSR...")
    if debug:
        click.echo("[newkeyapi]         " + newkeyapi)
        click.echo("[newkeypayload]     " + newkeypayload)

    r = requests.post(url=newkeyapi, headers=newkeyheaders, data=newkeypayload, verify=False)
    if debug:
        click.echo("[CSR Request Post]  " + r.content.decode('utf-8'))

    # Handle the response
    csrresponse = r.json()
    if debug:
        click.echo("[CSR Response]      " + json.dumps(r.json()))

    certificaterequest = csrresponse['result']['certificate_request']

    # Write the private key for the cert
    privatekey = csrresponse['result']['private_key']
    privatekeyfile = open(host + "_private_key.pem", "w")
    privatekeyfile.write(privatekey)
    click.echo("...Wrote Keys...")

    # Get the CSR signed and retreive the certificate
    click.echo("...Signing CSR...")
    signapiendpoint = '/ca/api/v2/sign'
    signapi = cluster + signapiendpoint

    # Prepare the request payload
    spl = {
        "certificate_request": certificaterequest
    }

    signpayload = json.dumps(spl)

    # Submit the request
    r = requests.post(url=signapi, headers=newkeyheaders, data=signpayload, verify=False)
    if debug:
        click.echo("[Sign Request]      " + json.dumps(r.json()))

    # Handle the response
    signresponsevalue = r.json()
    certificatevalue = signresponsevalue['result']['certificate']
    certificatefile = open(host + "_certificate.pem", "w")
    certificatefile.write(certificatevalue)
    click.echo("...Wrote certificate: " + host + "_certificate.pem...")

    # Make java trust and key stores
    if ks:
        click.echo("Java Trust and Keystore requested. Generating:")
        thetruststore = ks_path + '/truststore.jks'
        thekeystore = ks_path + '/keystore.jks'

        # Get the ca cert, make a trustore entry
        theca = getca(cluster)
        thederca = convertrsa(theca)
        cacert = jks.TrustedCertEntry.new('dcosca', thederca)
        thecalist = [cacert]

        certname = host + '_cert'
        thedercert = convertrsa(certificatevalue)
        kscert = jks.TrustedCertEntry.new(certname, thedercert)

        # Make the truststore
        if os.path.isfile(ks_path + '/truststore.jks'):
            click.echo("...Truststore exists, not overwriting!! ")
        else:
            # Create a truststore, add the ca entry, write the file.
            tsinstance = jks.KeyStore.new('jks', thecalist)
            tsinstance.save(thetruststore, "changeit")
            click.echo("...Wrote Truststore: " + ks_path + "/truststore.jks...")

        # Make the keystore
        if os.path.isfile(ks_path + '/keystore.jks'):
            click.echo("...Keystore exists, not overwriting!! ")
        else:
            ksinstance = jks.KeyStore.new('jks', [kscert])
            ksinstance.save(thekeystore, "changeit")
            click.echo("...Wrote Keystore: " + ks_path + "/keystore.jks...")

    click.echo("...Certificator End...")
    return


@cli.command()
@click.option(
    '--cluster',
    '-c',
    help='URL for the cluster',
    default='https://master.mesos'
)
def writeca(cluster):
    click.echo("writeCA requested:")
    theca = getca(cluster)
    cafile = open("ca.pem", "w")
    cafile.write(theca)


def fetchtoken(debug, cluster, username, userkey):
    click.echo("...Fetching DCOS Authentication Token...")
    keyfile = open(userkey, "r")
    private_key = keyfile.read()

    thetoken = jwt.encode(
        {"uid": username, "exp": datetime.datetime.utcnow() + datetime.timedelta(seconds=3600)},
        private_key, algorithm='RS256'
    )
    logintoken = thetoken.decode("utf-8")

    headers = {'Content-Type': 'application/json'}
    theusername = '"' + username + '"'
    thelogintoken = '"' + logintoken + '"'
    thepayload = '{"uid": ' + theusername + ', ' + '"token" :' + thelogintoken + '}'

    payload = thepayload
    api_endpoint = '/acs/api/v1/auth/login'

    api = cluster + api_endpoint

    tokenreturn = requests.post(url=api, headers=headers, data=payload, verify=False)

    token = tokenreturn.json()

    click.echo("...DCOS Authentication Token Received!...")

    # debug
    if debug:
        click.echo("Token data:", err=True)
        click.echo(token, err=True)
        click.echo("", err=True)

        return token['token']

    return token['token']


def getca(cluster):
    api_endpoint = '/ca/api/v2/info'
    infoapi = cluster + api_endpoint

    r = requests.post(url=infoapi, data="{}", verify=False)
    certresp = r.json()
    cacert = certresp['result']['certificate']
    return cacert


def convertrsa(cert):
    certfile = cert
    certpem = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, certfile)
    cert_der = OpenSSL.crypto.dump_certificate(OpenSSL.crypto.FILETYPE_ASN1, certpem)
    return cert_der


def main():
    #TODO Make this dynamic
    click.echo("Buildinfo :")
    click.echo("  Version:     1.4")
    click.echo("  Python:      3.5.3")
    click.echo("  Compiled:    PyInstaller 3.5")
    click.echo("  Linked:      StaticX 0.7.0")
    click.echo("  Platform:    Linux-4.9.184-linuxkit-x86_64-with-debian-9.9")
    click.echo("  BuildHost:   Debian GNU/Linux 9")
    click.echo("  DockerImage: openjdk:8-jre")
    click.echo("  GLIBC:       2.24-11+deb9u4")
    click.echo(" ")
    click.echo("Running Application...")
    cli()


main()
