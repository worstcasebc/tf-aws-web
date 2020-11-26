# Terraform-Environment

as shown in https://www.youtube.com/watch?v=qfOSaCFnYCk

First install aws-vault

`brew cask install aws-vault`

... and configure it for an IAM user

`aws-vault add <user>`

`vi ~/.aws/config`

Should look like below after the changes

```
[default]
region=eu-central-1
output=json

[profile <user>]
region=eu-central-1
output=json
```

Open a vault-session for the next 12 hours

`aws-vault exec <user> --duration=12h`

We use a docker container to better handle the different terraform versions
The ssh-key I linked into the terraform-directory to used that during the provisioner-connection.

```
docker-compose run --rm tf init
docker-compose run --rm tf fmt
docker-compose run --rm tf validate
docker-compose run --rm tf plan
docker-compose run --rm tf apply
docker-compose run --rm tf destroy
```
