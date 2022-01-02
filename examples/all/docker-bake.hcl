variable "GOXX_BASE" {
  default = "crazymax/goxx:latest"
}

target "_commons" {
  args = {
    GOXX_BASE = GOXX_BASE
  }
}

group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["_commons"]
  tags = ["all-xx:local"]
}

target "image-local" {
  inherits = ["image"]
  output = ["type=docker"]
}

target "image-all" {
  inherits = ["image"]
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}
