# Terraform VirtualBox Lab

A hands-on Terraform learning project using VirtualBox as a local infrastructure target.

The purpose of this project was to learn Terraform by actually provisioning infrastructure and working through the complete Terraform workflow rather than only learning the syntax.

## What I Practiced

- Terraform providers
- Provider configuration
- Terraform resources
- Resource dependencies
- Declarative infrastructure
- Terraform state
- `terraform init`
- `terraform validate`
- `terraform plan`
- `terraform apply`
- Resource replacement
- State refresh
- Provider troubleshooting
- Infrastructure vs Terraform state
- VirtualBox automation

## Lab Architecture

The initial goal was to provision an Ubuntu Server VM using Terraform:

```
                         Terraform
                             |
                             v
                    VirtualBox Provider
                             |
                             v
                         VirtualBox
                             |
              +--------------+--------------+
              |                             |
              v                             v
       Ubuntu Virtual Disk            Ubuntu Server ISO
              |
              v
       terraform-ubuntu-01
```

### VM Configuration

The Terraform configuration defined:

- 2 CPUs
- 2048 MB RAM
- SATA storage controller
- 20 GB VDI disk
- Ubuntu Server ISO
- Virtual disk attachment
- ISO attachment

## Terraform Resources

The configuration used the following resources:

```
virtualbox_vm
virtualbox_disk
virtualbox_vm_storage_attachment
```

Terraform used resource references to establish dependencies between the VM, disk, and storage attachments.

## Terraform Workflow

The project followed the standard Terraform workflow:

```
Write Configuration
        |
        v
terraform init
        |
        v
terraform validate
        |
        v
terraform plan
        |
        v
terraform apply
        |
        v
Infrastructure
        |
        v
Terraform State
```

## Provider

The project used:

```
Provider: namnd/virtualbox
Version: 0.2.4
```

The local environment used:

```
VirtualBox: 7.2.14
Platform: Windows
```

## Important Learning: Terraform State

Terraform state records the infrastructure Terraform is currently managing.

During this lab, Terraform successfully created the virtual disk and tracked it in state:

```
virtualbox_disk.ubuntu_disk
```

The VirtualBox VM was subsequently created, but the provider failed while processing the VM information. This resulted in a difference between the infrastructure that existed in VirtualBox and the resources recorded in Terraform state.

This demonstrated why Terraform state is an important part of infrastructure management.

## Provider Compatibility Issue

The VM creation attempt exposed a compatibility/problematic behavior in the `namnd/virtualbox` provider when used with VirtualBox 7.2.14.

VirtualBox successfully created the VM and `VBoxManage` was able to display its information, but the Terraform provider returned an error while processing that information.

The provider also did not support importing the existing VM.

The VM was therefore manually removed from VirtualBox after the failed Terraform operation.

This became an important part of the learning process rather than simply a failed deployment.

## Key Takeaways

The main lessons from this project were:

1. Terraform uses providers to communicate with infrastructure platforms.
2. Resources represent infrastructure managed by Terraform.
3. Terraform builds dependencies from resource references.
4. `terraform plan` should be reviewed before applying changes.
5. Terraform state represents Terraform's knowledge of infrastructure.
6. Infrastructure and Terraform state can become inconsistent after failed operations.
7. A failed `terraform apply` does not necessarily mean that no infrastructure was created.
8. Provider compatibility is an important consideration when choosing an infrastructure target.
9. Troubleshooting Terraform requires checking both Terraform and the underlying infrastructure.

## Next Step

The next phase of my Terraform learning will move from local VirtualBox infrastructure to AWS.

The goal is to apply the same Terraform concepts to a more commonly used cloud infrastructure environment:

```
Terraform
    |
    v
AWS Provider
    |
    +-- VPC
    +-- EC2
    +-- Security Groups
    +-- IAM
    +-- S3
```

## Project Status

| Component | Status |
|-----------|--------|
| Terraform setup | Completed |
| Provider configuration | Completed |
| Virtual disk | Successfully created |
| Terraform state | Practiced |
| Terraform plan | Practiced |
| VM configuration | Completed |
| VM creation attempt | Completed |
| VM provisioning | Blocked by provider issue |
| Troubleshooting | Completed |
| AWS Terraform lab | Next |

## Purpose

This repository documents my hands-on Terraform learning journey, including both successful infrastructure operations and real troubleshooting encountered while working with a local VirtualBox environment.
