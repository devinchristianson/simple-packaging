# simple-packaging
The goal of this project is to perform simple automated packaging of existing projects using FPM and CICD to build internal repos 

# General CICD plans
- use matrix build for to build each program for each package type
- CI phases:
  - init shared volume and S3 sync(s)
  - two pipeline steps for each combo in matrix - 1. build package 2. copy package to appropriate file location
  - final step for each package type - sign packages, regenerate index files and similar

- also build fpm images with CI?
- write script to determine new releases with github api https://api.github.com/repos/jgm/pandoc/releases/latest


# How to rebuild pipeline (will be done it a pipeline eventually)
- jsonnet concourse/pipeline.jsonnet | yq --prettyPrint > .concourse/pipeline.yml
- fly -t main set-pipeline -p simple-pkg-main -c .concourse/pipeline.yml
# Things to package
- jq
- benthos


to do
- set up deb pipeline
- move rpm index generation to use mkrepo or if that fails 
  - https://github.com/deb-s3/deb-s3
  - https://github.com/stackstate-lab/rpm-s3


