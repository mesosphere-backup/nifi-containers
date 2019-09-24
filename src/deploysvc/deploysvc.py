#!/usr/bin/env python3
# Copyright (c) 2019 Martijn Dekkers, D2iQ.
# Licensed under the Apache 2.0 License
# Martijn Dekkers <mdekkers@d2iq.com>

import os,sys
from pathlib import Path
import click
import json
from jinja2 import Environment, FileSystemLoader, evalcontextfilter
Environment(trim_blocks=True, lstrip_blocks=True)

theservices = []


@click.group()
def cli():
    pass


@cli.command()
@click.option(
    '--usage',
    '-u',
    help='Show usage details on a specific service',
)
def show(usage):
    rootfolder = './services'

    if not usage:
        click.echo("\nThe following services are currently available:\n")
        for theservice in os.listdir(rootfolder):
            if theservice.endswith(".j2"):
                theservice = theservice[:-3]
                click.echo("\t[" + theservice + "]")
    else:
        thefile = Path(rootfolder + '/' + usage + ".j2")

        if thefile.is_file():
            theservice = open(thefile,'r')
            content = theservice.read()
            blockstart = content.index('{#')
            blockend = content.index('#}',blockstart)
            click.echo(content[blockstart + 2:blockend])
        else:
            click.echo("\t\x1b[93;41mDefinition " + usage + " does not exist.\033[0m")
            sys.exit(1)


@cli.command()
@click.option(
    '--definitionfile',
    '-d',
    help='The file that defines the service parameters.',
    default='definition.json'
)
@click.option(
    '--servicetype',
    '-s',
    help='The service you would like to deploy. Execute this program with the showsvc option to list'
         ' instructions for currently defined services.',
    required=True,
    prompt=True,
    type=click.Choice(theservices)
)
def build(definitionfile,servicetype):
    theoutputfile = open(servicetype + "-def.json", "w+")
    file_loader = FileSystemLoader('services')
    env = Environment(loader=file_loader)
    template = servicetype + ".j2"
    thetemplate = env.get_template(template)

    with open(definitionfile) as deffile:
        thedefinition = json.load(deffile)

    theoptionsfile = thetemplate.render(thedefinition=thedefinition)
    theoutputfile.write(theoptionsfile)

    return


def makeoptions():
    rootfolder = './services'
    for theservice in os.listdir(rootfolder):
        if theservice.endswith(".j2"):
            theservice = theservice[:-3]
            theservices.append(theservice)


def main():
    makeoptions()
    cli()


main()