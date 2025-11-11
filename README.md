# Terraform Cloud — AWS Infrastructure Deployment

This repository provisions AWS infrastructure using Terraform Cloud as the execution environment instead of the local Terraform CLI.

---

## Overview

Terraform Cloud manages:
- Remote state storage (encrypted & versioned)
- Secure secret management (AWS credentials or OIDC)
- Automated plans and applies triggered by Git commits
- Audit logs and access control

When code changes are pushed to the repository, Terraform Cloud automatically runs `terraform plan` and `terraform apply` in its remote environment.

---

## Repository Structure
```
.
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```


---

## Prerequisites

1. Terraform Cloud account — https://app.terraform.io
2. Create a Workspace and connect it to this Git repo
3. Configure credentials in:  
   `Workspace → Variables`

Example variables:

| Type         | Key                     | Value (example)          |
|--------------|-------------------------|--------------------------|
| Environment  | AWS_ACCESS_KEY_ID       | xxxxxxxxxxxxxxxxxx       |
| Environment  | AWS_SECRET_ACCESS_KEY   | xxxxxxxxxxxxxxxxxx       |
| Terraform    | region                  | ap-southeast-2           |

> Recommended: Use Terraform Cloud OIDC to assume AWS IAM roles instead of storing static IAM keys.

---

## Terraform Cloud Backend

Terraform Cloud injects the backend automatically.  
To explicitly declare it:

```hcl
terraform {
  cloud {
    organization = "YOUR_ORG"

    workspaces {
      name = "YOUR_WORKSPACE"
    }
  }
}
