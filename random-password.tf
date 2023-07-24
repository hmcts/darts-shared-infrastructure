
resource "random_password" "password" {
  length           = 16
  special          = true
  min_special      = 1
  min_numeric      = 1
  min_lower        = 1
  min_upper        = 1
  override_special = "!#$%&*()-_=+[]{}<>:?"
}