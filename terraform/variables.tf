variable "owner" {
  type = map
  default = {
    Name = "Graham Watts"
    Email = "mail@grahamwatts.com"
  }
}

variable "environment" {
  type = string
  default = "Dev"
}
