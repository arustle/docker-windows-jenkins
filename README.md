# Jenkins server on Windows Docker Image
This project is based on the official Jenkins Continuous Integration and Delivery server [available on Docker Hub](https://hub.docker.com/r/jenkins/jenkins).  The official image is built from a Linux, this project provides an image built from Windows.


# Usage

To build and run:
```
docker image build -t winjenkins .
docker container run -p 8080:8080 --name=jenkins-win-server -d winjenkins
```

Optional build arguments:
- JENKINS_VERSION: [Default is 2.221]
- GIT_VERSION: [Default is 2.25.1]

Example:
```
docker image build --build-arg JENKINS_VERSION=2.199 --build-arg GIT_VERSION=2.23.0 -t winjenkins .
docker container run -p 8080:8080 --name=jenkins-win-server -d winjenkins
```

## TODO
- Copy backups into image
- Automate install of Jenkins plugins
- Add sample scripts for other automated Jenkins setups
- Add image to Docker Hub


## License
Usage is provided under the [MIT License](http://opensource.org/licenses/mit-license.php). See LICENSE for the full details.