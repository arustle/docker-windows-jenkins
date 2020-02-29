FROM openjdk:8-windowsservercore

# Arg defaults (use --build-arg to override)
ARG JENKINS_VERSION=2.221
ARG GIT_VERSION=2.25.1

ENV JENKINS_VERSION=${JENKINS_VERSION}
ENV JENKINS_HOME=c:/jenkins

# $ProgressPreference will disable download progress info and speed-up download
SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; "]

# Note: Install Jenkins master
RUN \
    New-Item -ItemType Directory -Force -Path 'c:/jenkins'; \
    [Net.ServicePointManager]::SecurityProtocol = 'tls12'; \
    Invoke-WebRequest "https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/$env:JENKINS_VERSION/jenkins-war-$env:JENKINS_VERSION.war" -OutFile "c:/jenkins.war" -UseBasicParsing

# Note: Install Git
RUN \
    New-Item -ItemType Directory -Force -Path 'c:/git'; \
    [Net.ServicePointManager]::SecurityProtocol = 'tls12'; \
    Invoke-WebRequest "https://github.com/git-for-windows/git/releases/download/v$env:GIT_VERSION.windows.1/Git-$env:GIT_VERSION-64-bit.exe" -OutFile "$env:TEMP/git.exe" -UseBasicParsing; \
    Start-Process -FilePath "$env:TEMP/git.exe" -ArgumentList '/VERYSILENT', '/NORESTART', '/NOCANCEL', '/SP-', '/DIR="c:/git"' -PassThru | Wait-Process; \
    dir "$env:TEMP" | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue


# jenkins setup scripts
COPY groovy c:\\jenkins\\init.groovy.d

COPY scripts c:\\scripts
RUN C:\\scripts\\install-plugins.ps1 "c:\\scripts\\plugins.txt"

# for main web interface:
EXPOSE 8080

# will be used by attached slave agents:
EXPOSE 50000

CMD [ "powershell", "&'java.exe' --% -Djenkins.install.runSetupWizard=false -jar c:/jenkins.war" ]
