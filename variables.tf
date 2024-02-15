variable "amount"{
  type = number
  default = 2
}

variable "image_flavor" {
  type = string
  default = "Ubuntu-20.04.1-202008"
}

variable "compute_flavor" {
  type = string
  default = "STD2-2-2"
}

variable "availability_zone_name" {
  type = string
  default = "MS1"
}