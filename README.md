# Monitor snowflake through cloudwatch dashboard

## Send Snowflake metrics to cloudwatch using external function

### Using terraform for CICD

> Create Snowflake user and export it's information

```
cd ~/.ssh
$ openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out snowflake_tf_snow_key.p8 -nocrypt
$ openssl rsa -in snowflake_tf_snow_key.p8 -pubout -out snowflake_tf_snow_key.pub
```

```
CREATE USER "tf-snow" RSA_PUBLIC_KEY='RSA_PUBLIC_KEY_HERE_WITHOUT_WHITESPACES_AND_COMMENTS' DEFAULT_ROLE=PUBLIC MUST_CHANGE_PASSWORD=FALSE;

GRANT ROLE SYSADMIN TO USER "tf-snow";
GRANT ROLE SECURITYADMIN TO USER "tf-snow";
```

```
export SNOWFLAKE_USER="tf-snow"
export SNOWFLAKE_PRIVATE_KEY_PATH="~/.ssh/snowflake_tf_snow_key.p8"
export SNOWFLAKE_ACCOUNT="OFA26496"
export SNOWFLAKE_REGION="us-west-2"
```

> Export AWS Profile Information

```
export TF_VAR_account_no=817409382164
export TF_VAR_aws_profile="rackspace"
```

> Enable Debuging

```
export TF_LOG="DEBUG"
export TF_LOG_PATH="terraform-debug.log"
```

> Run terraform plan

```
terraform plan -var-file="regions/us-east-1/dev/terraform.tfvars"
```

> Run terraform apply

```
terraform apply -var-file="regions/us-east-1/dev/terraform.tfvars"
```
