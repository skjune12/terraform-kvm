# terraform-kvm

Example file for managing 2 ubuntu servers on KVM.

**NOTE**: This is for my reference. I do not reccomend to use it in production environment.

## topology

For simplifying the explanation, the figure omits some technical details, for instance, the interface name connected to the external network etc.

![topology](./e.png)

Each VM has 2 interfaces: `end3` and `ens4`.
* `ens3` is connected to external network
* `ens4` is for managment interface.
  * terraform automatically create virtual network named `mgmt0`
  * `br-mgmt0` will be created on host OS by terraform.

We assume that host OS has `br0` interface (it is used for external network)
* network range is 192.168.128.0/24
* gateway address is 192.168.128.1
* no dhcp



By default, terraform creates 2 users (defined in `cloud_init.cfg` in each directory)
* user (with sudo): `terraform` / `UserPassword!`
* root: root / `RootPassword!`

## run

Before run this, you need to install [terraform-provider-libvirt](https://github.com/dmacvicar/terraform-provider-libvirt).

setup VM

```
# terraform init
# terraform apply
```

delete VM created by terraform

```
# terraform destroy
```
