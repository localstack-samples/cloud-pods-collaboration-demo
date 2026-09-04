To create the infrastructure using OpenTofu please set the environment variable `TF_CMD=tofu` and
proceed to run the `lstk tf` commands as normal. The `TF_CMD` variable configures `lstk tf` to call the `tofu`
binary, instead of `terraform` (default).