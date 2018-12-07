
variable "arm_subscription_id" {}
variable "arm_tenant_id" {}
variable "arm_client_id" {}
variable "arm_client_secret" {}


variable "namespace" {
  default = "we123"
}

variable "location" {
  default = "East US"
}

variable "adminusername" {
  default = "albino"
}

variable "adminpassword" {
  default = "P@ssword1"
}

variable "vmsize" {
  #default = "Standard_DS2_v2" # 0.14592 CAD/hour 2vcpu, 7GB RAM
  #default = "Standard_D4s_v3" # 0.24576 CAD/hour 4vcpu, 16GB RAM
  default = "Standard_D2s_v3" # 0.12288 CAD / hour 2vcpu, 8gb ram
}