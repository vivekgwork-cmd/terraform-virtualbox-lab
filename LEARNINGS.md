# Terraform VirtualBox Lab — Learnings

This document records the concepts and troubleshooting lessons learned while building the Terraform VirtualBox lab.

---

## 1. Terraform Is Declarative

Terraform follows a declarative approach.

Instead of writing step-by-step instructions such as:

```text
Create a VM
Give it 2 CPUs
Give it 2 GB RAM
Create a disk
Attach the disk
Attach the ISO
```

we describe the desired infrastructure:

```hcl
resource "virtualbox_vm" "ubuntu" {
  name   = "terraform-ubuntu-01"
  cpus   = 2
  memory = 2048
}
```

Terraform determines what actions are required to reach the desired state.

---

## 2. Providers

Terraform itself does not know how to communicate with VirtualBox.

The provider acts as the bridge between Terraform and the infrastructure platform.

```
Terraform    |    v
VirtualBox Provider    |    v
VirtualBox
```

The provider was configured using:

```hcl
terraform {
  required_providers {
    virtualbox = {
      source  = "namnd/virtualbox"
      version = "0.2.4"
    }
  }
}
provider "virtualbox" {}
```

The important concept learned here is that Terraform needs a provider to interact with an external infrastructure platform.

---

## 3. Resources

Terraform represents infrastructure using resources.

This project used:

```
virtualbox_vm
virtualbox_disk
virtualbox_vm_storage_attachment
```

For example:

```hcl
resource "virtualbox_disk" "ubuntu_disk" {
  file_path = "C:/vivek/terraform-virtualbox-lab/terraform/ubuntu.vdi"
  size      = 20000
  format    = "VDI"
}
```

The resource describes the desired disk.

Terraform then determines whether that disk needs to be created, changed, or replaced.

---

## 4. Resource Dependencies

Terraform can understand dependencies through resource references.

For example:

```hcl
vm_id = virtualbox_vm.ubuntu.id
```

and:

```hcl
medium = virtualbox_disk.ubuntu_disk.id
```

These references tell Terraform that the storage attachment depends on the VM and disk.

Terraform can therefore build a dependency graph automatically.

Conceptually:

```
virtualbox_disk
       |
       v
virtualbox_vm
       |
       v
storage_attachment
```

---

## 5. `terraform init`

The first command used to initialize the project was:

```
terraform init
```

This initializes the Terraform working directory and installs the required provider.

The project used:

```
namnd/virtualbox v0.2.4
```

Terraform also generated:

```
.terraform.lock.hcl
```

The lock file records provider selection and checksums and should be committed to Git.

---

## 6. `terraform plan`

`terraform plan` shows what Terraform intends to do without actually applying the changes.

One of the first plans showed:

```
Plan: 4 to add, 0 to change, 1 to destroy.
```

The reason for the unexpected replacement was a difference in the representation of the Windows file path.

Terraform compared:

```
C:\vivek\terraform-virtualbox-lab\terraform\ubuntu.vdi
```

with:

```
C:/vivek/terraform-virtualbox-lab/terraform/ubuntu.vdi
```

The provider considered this a change that required replacement.

After correcting the path representation, the plan became:

```
Plan: 3 to add, 0 to change, 0 to destroy.
```

### Lesson

Always inspect `terraform plan` before running `terraform apply`.

Terraform may identify a resource replacement even when the change appears insignificant from a human perspective.

---

## 7. Terraform State

Terraform maintains a state file that records the resources it knows about.

The command:

```
terraform state list
```

initially showed:

```
virtualbox_disk.ubuntu_disk
```

This meant Terraform was tracking the disk.

The state did not contain the VM because the VM creation operation did not complete successfully from Terraform's perspective.

---

## 8. Infrastructure and State Are Different

One of the most important lessons from the experiment was that:

```
Infrastructure = What actually exists
Terraform State = What Terraform knows about
```

These are normally synchronized.

However, after the failed VM creation:

```
VirtualBox
    |
    +-- terraform-ubuntu-01
```

while Terraform state contained only:

```
virtualbox_disk.ubuntu_disk
```

The two had become inconsistent.

---

## 9. A Failed `terraform apply` Can Still Create Infrastructure

Terraform reported:

```
Error: Error creating VM
```

However, checking VirtualBox manually:

```
VBoxManage list vms
```

returned:

```
"terraform-ubuntu-01" {UUID}
```

This demonstrated an important operational lesson:

> A failed Terraform apply does not necessarily mean that the infrastructure was not created.

After a failed apply, the underlying infrastructure should always be checked.

---

## 10. Troubleshooting Using the Underlying Platform

Instead of relying only on Terraform's error message, VirtualBox was inspected directly.

The command:

```
VBoxManage list vms
```

confirmed that the VM existed.

Then:

```
VBoxManage showvminfo "terraform-ubuntu-01" --machinereadable
```

showed information including:

```
name="terraform-ubuntu-01"
UUID="..."
memory=2048
cpus=2
```

This demonstrated that VirtualBox itself had successfully created the VM.

The problem therefore appeared to be in the Terraform provider's handling of the VirtualBox VM information.

---

## 11. Import Limitations

An attempt was made to bring the existing VM into Terraform state:

```
terraform import virtualbox_vm.ubuntu <UUID>
```

Terraform returned:

```
Resource Import Not Implemented
```

This demonstrated another important provider limitation.

Not every Terraform resource necessarily supports importing existing infrastructure.

When import is unavailable, recovery from an orphaned resource can require manual intervention.

---

## 12. Cleaning Up an Orphaned VM

Because the provider could not import the VM, the VM was removed directly through VirtualBox:

```
VBoxManage unregistervm "terraform-ubuntu-01" --delete
```

Afterward:

```
VBoxManage list vms
```

returned no registered VMs.

This restored the VirtualBox environment to a clean state.

---

## 13. Provider Compatibility

The environment used:

```
VirtualBox 7.2.14
namnd/virtualbox 0.2.4
```

The VM creation reached VirtualBox successfully, but the Terraform provider failed while processing the VM information afterward.

This demonstrated that a Terraform configuration can be syntactically valid and the underlying infrastructure platform can work correctly while the provider integration still has problems.

### Lesson

When troubleshooting Terraform, think in layers:

```
Terraform Configuration
        |
        v
Terraform Core
        |
        v
Provider
        |
        v
Infrastructure API / CLI
        |
        v
Infrastructure
```

The failure can occur at any layer.

---

## 14. Provider Lock File

The project contains:

```
.terraform.lock.hcl
```

The lock file should be committed to the repository.

It helps Terraform consistently use the expected provider version and verifies provider packages using checksums.

---

## 15. What Should Not Be Committed

The project uses `.gitignore` to exclude local Terraform files such as:

```
.terraform/
*.tfstate
*.tfstate.*
```

These contain local state and generated files that should not be committed to this learning repository.

The provider lock file, however, is intentionally kept:

```
.terraform.lock.hcl
```

---

## 16. Overall Terraform Mental Model

The most useful mental model from this project is:

```
             Configuration
                   |
                   v
                Provider
                   |
                   v
            Infrastructure
                   |
                   v
             Terraform State
                   |
                   v
              Reconciliation
                   |
                   +------> Plan
                   |
                   +------> Apply
                   |
                   +------> Destroy
```

Terraform continuously works toward making the actual infrastructure match the desired configuration.

---

## 17. Main Lessons From the Lab

The most important lessons were:

### Terraform is declarative

We describe what we want instead of manually describing every operation.

### Providers are critical

Terraform depends on providers to communicate with external platforms.

### Resources represent infrastructure

VMs, disks, networks, and other infrastructure components can be represented as Terraform resources.

### Dependencies can be expressed through references

Terraform can construct a dependency graph from resource relationships.

### State matters

Terraform needs state to understand what it is currently managing.

### Plan matters

`terraform plan` allows changes to be reviewed before they are applied.

### Failed operations require investigation

A failed Terraform command does not necessarily mean that no infrastructure was created.

### Provider limitations matter

Provider support for operations such as import can affect how infrastructure is recovered and managed.

---

## 18. Next Phase

The next phase of the learning journey will move from VirtualBox to AWS.

The objective will be to apply the concepts learned here to cloud infrastructure:

```
Terraform
    |
    v
AWS Provider
    |
    +---- VPC
    |
    +---- Subnets
    |
    +---- Security Groups
    |
    +---- EC2
    |
    +---- IAM
```

The VirtualBox lab served as the first hands-on Terraform experiment and established the fundamental Terraform workflow before moving to a cloud environment.
