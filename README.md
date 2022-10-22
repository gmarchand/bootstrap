# bootstrap

## bootstrap-mac

## aws-cloud9-bootstrap

Launch a Cloud9 env with a biggest EBS Volume and all updated tools

## Files

- `bootstrap.sh` : script to bootstrap the cloud9 instance with uptodate components
- `Taskfile.yml` : [Equivalent of Makefile](https://taskfile.dev) to launch the [Cloud9 Quickstart Template](https://github.com/aws-quickstart/quickstart-cloud9-ide) inside your VPC

## How to

1. Install TaskFile : https://taskfile.dev/#/installation
1. Edit Taskvars.yml
1. `task -l` to list all actions
1. `task` to launch a new cloud9 env
