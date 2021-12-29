target "_common" {
  args = {
    BUILDKIT_CONTEXT_KEEP_GIT_DIR = 1
  }
}

// Special target: https://github.com/docker/metadata-action#bake-definition
target "docker-metadata-action" {
  tags = ["goxx:local"]
}

group "default" {
  targets = ["go-local"]
}

target "base" {
  inherits = ["_common"]
  target = "base"
  output = ["type=cacheonly"]
}

target "osxcross" {
  inherits = ["_common"]
  target = "osxcross"
  output = ["type=cacheonly"]
}

target "go" {
  inherits = ["_common", "docker-metadata-action"]
}

target "go-local" {
  inherits = ["go-latest"]
  output = ["type=docker"]
}

target "go-latest" {
  inherits = ["go-1.17"]
}

target "go-1.17" {
  inherits = ["go-1.17.5"]
}

target "go-1.17.5" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.17.5"
  }
}

target "go-1.17.4" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.17.4"
  }
}

target "go-1.17.3" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.17.3"
  }
}

target "go-1.17.2" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.17.2"
  }
}

target "go-1.17.1" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.17.1"
  }
}

target "go-1.17.0" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.17"
  }
}

target "go-1.16" {
  inherits = ["go-1.16.12"]
}

target "go-1.16.12" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.16.12"
  }
}

target "go-1.16.11" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.16.11"
  }
}

target "go-1.16.10" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.16.10"
  }
}

target "go-1.16.9" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.16.9"
  }
}

target "go-1.16.8" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.16.8"
  }
}

target "go-1.16.7" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.16.7"
  }
}

target "go-1.16.6" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.16.6"
  }
}

target "go-1.16.5" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.16.5"
  }
}

target "go-1.16.4" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.16.4"
  }
}

target "go-1.16.3" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.16.3"
  }
}

target "go-1.16.2" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.16.2"
  }
}

target "go-1.16.1" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.16.1"
  }
}

target "go-1.16.0" {
  inherits = ["go"]
  args = {
    GO_VERSION = "1.16"
  }
}
