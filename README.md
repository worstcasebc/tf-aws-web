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

We use a docker container to better handle the different terraform versions.

```
docker-compose run --rm tf init
docker-compose run --rm tf fmt
docker-compose run --rm tf validate
docker-compose run --rm tf plan
docker-compose run --rm tf apply
docker-compose run --rm tf destroy
```

After applying the infrastructure-code to aour AWS account, check with the `elb-public-dns`in your browser.

A bastion-host is automatically created to allow ssh-access to the webserver-instances within private subnets. The inbound-traffic is restricted to the actual used public-ip.

If not already done, add your private key to the ssh-agent to forward it to the bastion-host.

`ssh-add -K ~/.ssh/id_rsa`

`ssh -A ec2-user@<bastion-host-ip>`

From the bastion host follow the route to the webserver by

`ssh ec2-user@<webserver-private-ip>`
