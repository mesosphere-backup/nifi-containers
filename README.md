# Apache NiFi Docker Containers for DC/OS

Each NiFi component will have 2 containers, *-core, which is the base Java + NiFi component container, and a container built on top of that which will include all start and run scripts to make the container work in DC/OS as a simple Marathon service. These containers do not implement the DC/OS SDK and do not run as a DC/OS Framework.

To build a container, edit the settings.sh file in the respective directory to your liking, and run `./DockerBuild.sh` or `./Dockerbuild.sh push` to build r build+push the container to whichever Docker registry you are currently logged in to.
