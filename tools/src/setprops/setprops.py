#!/usr/bin/env python3
# Copyright (c) 2019 Martijn Dekkers, D2iQ.
# Licensed under the Apache 2.0 License
# Martijn Dekkers <mdekkers@d2iq.com>

import os
import click
from jinja2 import Environment, FileSystemLoader


@click.group()
def cli():
    pass


@cli.command()
@click.option(
    '--prefix',
    '-p',
    help='What prefix to use. Will also use the value of the CNF_PREFIX environment variable, if defined. Default prefix is DCNF_',
    required=True,
    default = 'DCNF_',
    envvar='CNF_PREFIX'
)
@click.option(
    '--template',
    '-t',
    help='Template config file to use. Template should be a JINJA2 formatted template file. '
         'Will also use the value of the CNF_TEMPL environment variable, if defined.',
    required=True,
    envvar='CNF_TEMPL'
)
@click.option(
    '--configfile',
    '-c',
    required=True,
    type=click.File('w'),
    envvar='CNF_CONF',
    help='Config file to generate. Can be used multiple times. '                                                                                                            
         'Will use the value of the CNF_CONF environment variable, if defined.'
)
@click.option(
    '--keysplit',
    '-k',
    help='Key split character to use. Many config files will use some form of key seperator '
         'such as "this.is.a.key" that don\'t always translate nicely in environment variables'
         'Always use the underscore in your environment variables, and use this switch to'
         'indicate what seperator to replace the underscore with.'
         'Will also use the value of the CNF_KSPL environment variable, if defined.',
    envvar='CNF_KSPL'
)
@click.version_option(
    version=0.1,
    prog_name='setprops',
    message='\nsetprops builds a configuration file from a JINJA2 template. For usage, see --help\n'
)
def mkiniconf(configfile,prefix,template):
    """This program will read prefixed environment variables and a JINJA2 configuration file template,
    and combines them to generate a config file for an application or service."""

    file_loader = FileSystemLoader('templates')
    env = Environment(loader=file_loader)

    thetemplate = env.get_template(template)
    TheConfItems = {}

    for k in sorted(os.environ.keys()):
        v = os.environ[k]
        if not k.startswith(prefix):
            continue

        k = k[len(prefix):]
        k = k.lower()
        click.echo('[%s] Setting config %s to %s' % (configfile, k, v))

        TheConfItems[k] = v

    TheConfigFile = thetemplate.render(TheConfItems)
    configfile.write(TheConfigFile)

    return


@cli.command()
@click.option(
    '--template',
    '-t',
    type=click.File('w'),
    required=True,
    help='Template config file to create.',
)
@click.option(
    '--configfile',
    '-c',
    type=click.File('r'),
    required=True,
    help='Config file to read. Can be used multiple times.'
)
@click.option(
    '--kvseperator',
    '-s',
    default="=",
    help='What character separates keys from values. Defaults to "="'
)
@click.option(
    '--keysplit',
    '-k',
    default=".",
    help='Key split character to use. Many config files will use some form of key seperator '
         'such as "this.is.a.key" that don\'t always translate nicely in environment variables'
         'Always use the underscore in your environment variables, and use this switch to'
         'indicate what seperator to replace the underscore with. Defaults to "."')
@click.option(
    '--comment',
    '-m',
    default="#",
    help='What character denotes a linecomment. Defaults to "#"'
)
def mktemplate(template,configfile,kvseperator,keysplit,comment):
    lines = []

    for line in configfile:
        lines.append(line)
        line = line.strip()
        if not line or line.startswith(comment):
            template.write(line + "\n")
            continue

        k, v = line.split(kvseperator, 1)
        thekey = k.replace(keysplit, "_")
        if v is not "":
            v = "{{ " + thekey.lower() + "|default(\"" + v + "\") }}"
        else:
            v = "{{ " + thekey.lower() + " }}"

        template.write(k + "=" + v +"\n")

    return


def main():
    cli()
    return

main()