# Hugr docker images

The `hugr` is a Data Mesh platform that provides a simple way to manage and share data across different teams and services. It is designed to be easy to use and deploy, with a focus on simplicity and flexibility.

For more information about the Hugr project, please visit the [Hugr web site](https://hugr-lab.github.io/).

The docker images of the Hugr service.
There are two images:

- ghcr.io/hugr-lab/server - simple hugr server,
- ghcr.io/hugr-lab/automigrate - simple hugr server with automigration for the core-db schema,
- ghcr.io/hugr-lab/management - management node for the cluster mode.

The images are built using files:

- server.dockerfile,
- automigrate.dockerfile,
- management.dockerfile.

The automation builds provided by GitHub actions are triggered by the new release tag. The version of images is the same as [Hugr](https://github.com/hugr-lab/hugr). To build the images manually, you can use the following commands:

```bash
docker build -t ghcr.io/hugr-lab/server:latest -f server.dockerfile .
docker build -t ghcr.io/hugr-lab/automigrate:latest -f automigrate.dockerfile .
docker build -t ghcr.io/hugr-lab/management:latest -f management.dockerfile .
```

Or you can build and run it using docker compose. The compose file is provided in the `compose` directory. The compose file is used to run the server and the database.

```bash
docker compose -f example.build.docker-compose.yml up --build
```

## Usage

To run the server, you can use the following command:

```bash
cd compose
docker compose -f example.docker-compose.yml up
```

This will start the server and the database. The server will be available at ```http://localhost:15000``` with core db, that is placed in .local directory, and it should be exists, before server is started. To set up other settings use environment variables see [Hugr repo](https://github.com/hugr-lab/hugr/README.md).

There is an example of docker-compose file that describes Hugr, cache and s3 (minio) services. To run the example, you can use the following command:

```bash
docker compose -f example.cache.docker-compose.yml up
```

## Cluster deployment

The hugr can naitively run in cluster mode. The cluster mode is used to run the server in a distributed environment. To sync the work nodes across the cluster hugr provide a special management node. The management node can be deployed from the docker image `ghcr.io/hugr-lab/management:latest`. The work nodes are the hugr server nodes, that are deployed with environment variables `CLUSTER_*`(see - [hugr README](https://github.com/hugr-lab/hugr/README.md)).

There is an example of docker-compose file that describes Hugr, cache and s3 (minio) services, hugr run in cluster mode (the two nodes is used). To run the example, you can use the following command:

```bash
docker compose -f example.cluster.docker-compose.yml up
```

Also there are k8s chart for the cluster deployment in the `k8s/cluster` directory. To set up cluster locally see [minikube-cluster.md](examples/minikube-cluster.md).

## Pull images

To pull the images from the GitHub container registry, you can use the following commands:

```bash
docker pull ghcr.io/hugr-lab/server:latest
docker pull ghcr.io/hugr-lab/automigrate:latest
docker pull ghcr.io/hugr-lab/management:latest
```

You can also save and load the images to/from a tar file using the following commands:

```bash
docker pull ghcr.io/hugr-lab/server:latest --platform linux/amd64 
docker save -o hugr-server.tar ghcr.io/hugr-lab/server:latest --platform linux/amd64
docker load -i hugr-server.tar
```

```bash
docker pull ghcr.io/hugr-lab/automigrate:latest --platform linux/amd64 
docker save -o hugr-automigrate.tar ghcr.io/hugr-lab/automigrate:latest --platform linux/amd64
docker load -i hugr-automigrate.tar
```

```bash
docker pull ghcr.io/hugr-lab/management:latest --platform linux/amd64 
docker save -o hugr-management.tar ghcr.io/hugr-lab/management:latest --platform linux/amd64
docker load -i hugr-management.tar
```

## Contributing

If you want to contribute to this project, please fork the repository and create a pull request. We welcome contributions of all kinds, including bug fixes, new features, and documentation improvements.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
