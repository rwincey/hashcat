# Building and running container with Docker


### Prequesists ###

If you want to run hashcat with your gpus inside docker you first need to install the appropriate container runtime.

For nvidia go here https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

(The runtime stage in the dockerfile will use an offical nvidia image, make sure your host has at least the same cuda version or a newer version installed. If you wanna change the runtime version of cuda just have a search here https://hub.docker.com/r/nvidia/cuda/tags?name=12.9.1 and exchange it in the dockfile)

For AMD go here https://rocm.docs.amd.com/projects/install-on-linux/en/latest/how-to/docker.html


### Building and Runtime ###

There will be different dockerfiles for different platforms in the syntax "docker/runtime.PLATFORM.OS", each of which only works on that specific platform and requires the host to have the prequesists installed.

Currently there are only dockerfiles for cuda available (docker/runtime.cuda.OS), more will follow.

Also there are two options available to build the image:

## 1. With the official binaires (docker/runtime.PLATFORM.OS)

This will download the version specified in the dockerfile from the official website and use it.

Here is an example for nvidia on ubuntu:

```bash
docker build -f docker/runtime.cuda.ubuntu24 -t hashcat .
docker run --rm --gpus=all -it hashcat bash
root@docker:~/hashcat# ./hashcat.bin --help
```

   
## 2. Build the binaires yourself (docker/runtime.PLATFORM.OS.withbuild)

This will require the official build container to already be built (with the tag hashcat-binaries) successfully and will pull hashcat from it.

Here is an example for nvidia on ubuntu:

```bash
docker build -f docker/BinaryPackage.ubuntu20 -t hashcat-binaries .
docker build -f docker/runtime.cuda.ubuntu24.withbuild -t hashcat .
docker run --rm --gpus=all -it hashcat bash
root@docker:~/hashcat# ./hashcat.bin --help
```

