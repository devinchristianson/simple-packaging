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

# Things to package
- jq



ideas for index generations

deb:
- 


pacman todo
- add check for package in index before running build


