# Cloud Pods Collaboration Demo

A sample product API built with API Gateway, Lambda (Java), and DynamoDB, designed for collaborative debugging workflows using LocalStack Cloud Pods. Follow the end-to-end walkthrough for this project: https://docs.localstack.cloud/aws/tutorials/cloud-pods-collaborative-debugging/

![cloud-pod-collab](images/cloud-pod-collab.png)

## Prerequisites

- A valid [LocalStack for AWS license](https://localstack.cloud/pricing), which provides a [`LOCALSTACK_AUTH_TOKEN`](https://docs.localstack.cloud/aws/getting-started/auth-token/) required to run this sample.
- [Docker](https://docs.docker.com/get-docker/) for running LocalStack.
- [Maven](https://maven.apache.org/install.html) and [Java 21](https://adoptium.net/) for building the Lambda functions.
- [Terraform](https://developer.hashicorp.com/terraform/install) or [OpenTofu](https://opentofu.org/docs/intro/install/) with [`lstk`](https://docs.localstack.cloud/aws/developer-tools/running-localstack/lstk/), installed via `npm install -g @localstack/lstk` or `brew install localstack/tap/lstk`.

```bash
export LOCALSTACK_AUTH_TOKEN=<your-auth-token>
```

## Sample Variants

- [Terraform sample](terraform/main.tf)
- [OpenTofu sample](opentofu/main.tf)

## Quick Start

1. Start LocalStack:

```bash
docker compose up -d
```

2. Build Lambda artifacts:

```bash
cd lambda-functions
mvn clean package
```

3. Deploy infrastructure:

```bash
cd terraform
./run-tflocal.sh
```

4. Invoke the API:

```bash
./invoke.sh
```

For OpenTofu, set `LSTK_TF_CMD=tofu` and run `lstk tf` in `opentofu/` (see `opentofu/instructions.md`).

5. Test the scenario from the tutorial:

```bash
./test.sh
```

The test needs LocalStack to enforce IAM, as `docker-compose.yml` does with `ENFORCE_IAM=1`. With `lstk`, start it with `LOCALSTACK_ENFORCE_IAM=1 lstk start`. It adds two products, checks that reading one fails because the policy is missing `dynamodb:GetItem`, then adds the permission and checks the read works. It restores the original policy version when it exits. Set `TF_DIR=opentofu` to test the OpenTofu deployment.

## License

Licensed under Apache License 2.0. See [LICENSE](LICENSE).
