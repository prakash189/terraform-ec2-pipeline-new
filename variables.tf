
variable "region" {
    description = "default region for vpc"
    default = "ap-southeast-1"
  
}
variable "cidr" {
    description = "vpc cidr block range for vpc"
    default = "10.0.0.0/16"
}

variable "cidr_subnet1" {
    description = "cidr range for subnet 1 "
    default = "10.0.1.0/24"
  
}

variable "cidr_subnet2" {
    description = "cidr range for subnet 2 "
    default = "10.0.2.0/24"
  
}

variable "zone1" {
    description = "availibility zone1"
    default = "ap-southeast-1a"
  
}

variable "zone2" {
    description = "availibility zone2"
    default = "ap-southeast-1b"
  
}

variable "ami_id" {
    description = "ami id for ec2 server"
    default = "ami-082105f875acab993"
  
}

variable "instance_type" {
    description = "choose instance type"
    default = "t2.nano"
}

variable "keyname" {
    description = "key name"
    default = "terraform-new"
  
}