# Tools

This project holds a few tools that help with building custom containers running in DC/OS, including a simple build system for these tools. These tools are written in Python3, are "compiled" with PyInstaller, and subsequently some OS libraries (GLIBC is the key one) are statically linked into this "compiled" executable with StaticX. This approach ensures compatibility with a wider range of containers, and removes the need for a full Python + modules installation within the container. See the `src` directory for the individual tools. 

## Toolmaker
The `toolmaker.sh` script is a Bash script that will help with the building of these tools. To ensure proper operation of a given tool, it should ideally be compiled in the same or similar container type as the container type the target service will be running in. To that end a `makeenv` command is available, that will set up a container to the required specifications. 

The builder environments are made up of a `builder-core` container which is a base container with, with the required OS packages installed. The `appbuilder` container is based on the `builder-core` container, and simply reads the correct `requirements.txt` file that is included in the target app `src` directory, and install those in the container. There is a `push` option available to push the resulting container to your own registry if required. Up-to-date and tested container images are always available in the `mesosnifi` docker-hub account. 

### Requirements:
- Bash (4+ recommended, but 3 may also work)
- Docker 
- To test the `certificator` app:
    - A DC/OS service user with the dcos:adminrouter:ops:ca:rw full` permissions
    - The private key for that user, should be placed in the `resources` directory

### Usage:

Download or git clone / pull this directory and subdirectories to some bash environment (tested on OSX, should work on Linux, Windows is a gamble). 

Run `./toolmaker.sh` for help and usage information.

```
About:
Simple script that will build or test a python script in a container.
Will create a correct build container if required.
Expects that the script lives in the ./<appname> directory with a filename of <appname>.py
Built scripts are first packed with pyinstaller, and then linked with staticx

Usage:
./toolmaker.sh {build|test|makeenv|cleanup}
	build <app> {dev|debug|dist}
		Builds the <app> script with the stated buildmode:
		dev:	 Leaves all staticx and pyinstaller build artefacts in
		         place in the work folder
		debug:	 Enables debug mode for everything
		dist:	 Cleans up everything, disables debug, strips the
		         resulting application,
		         and places the built application in the bin directory
        cleanup: Cleans up the work directory

	test <app>
		Test the stated script. Set application options in
		resources/testconfig.sh

	makeenv <app> [push]
		Builds the container used by this script to actually build the
		app. Ensure a requirements.txt exists in your app src directory
		containing the required pip3 installable modules.
		push:	 push the built container to dockerhub. Make sure to
		         configure src/<app>/buildconfig.sh with the correct
		         tag.
```

