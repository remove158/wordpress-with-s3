variable "region" {
  type    = string
  default = "ap-southeast-1"
}
variable "availability_zone" {
  type    = string
  default = "ap-southeast-1a"
}
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
variable "ami" {
  type    = string
  default = "ami-0d058fe428540cd89"
}
variable "bucket_name" {
  type    = string
  default = "default-bucket-name"
}
variable "database_name" {
  type    = string
  default = "default-db-name"
}
variable "database_user" {
  type    = string
  default = "default-db-user"
}
variable "database_pass" {
  type    = string
  default = "default-db-pass"
}
variable "admin_user" {
  type    = string
  default = "admin"
}
variable "admin_pass" {
  type    = string
  default = "pass"
}


