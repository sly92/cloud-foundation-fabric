# Network filtering with Squid

This example shows how to deploy a filtering HTTP proxy to restrict Internet access. Here we show one way to do this using a VPC with two subnets:

- The first subnet (called "apps" in this example) hosts the VMs that will have their Internet access tightly controlled by a filtering forward proxy.
- The second subnet (called "proxy" in this example) hosts a Cloud NAT instance and a VM running [Squid](http://www.squid-cache.org/).

The VPC will be a Shared VPC and all the service projects will be located under a folder enforcing the `compute.vmExternalIpAccess` and `compute.restrictCloudNATUsage` [organization policies](https://cloud.google.com/resource-manager/docs/organization-policy/org-policy-constraints). This prevents the service projects from having external IPs or deploying Cloud NAT instances within the apps subnet (and thus preventing them from accessing the internet directly). The idea is to force all outbound Internet connections through the proxy.

To allow Internet connectivity from the proxy subnet Cloud NAT is configured there. All other subnets are not allowed to use the Cloud NAT instance.

To simplify the usage of the proxy, a Cloud DNS private zone is created and the IP address of the proxy is exposed with the FQDN `proxy.internal`. This allows clients VMs to use the proxy by simply setting the `HTTP_PROXY` and `HTTPS_PROXY` variables to `proxy.internal:3128`.
