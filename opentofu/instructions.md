To create the infrastructure using OpenTofu please set the environment variable `TF_CMD=tofu` and
proceed to run the `tflocal` commands as normal. The `TF_CMD` variable configures `terraform-local` to call the `tofu`
binary, instead of `terraform` (default).