terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.22.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Create a network for our containers
resource "docker_network" "devnet" {
  name   = "devnet"
  driver = "bridge"
  ipv6   = false
  ipam_config {
    ip_range = "192.168.50.0/24"
    subnet   = "192.168.50.0/24"
    gateway  = "192.168.50.1"
  }
}

# Pull the images
resource "docker_image" "rocky8" {
  name = "rockylinux:8"
}

resource "docker_image" "postgres13" {
  name = "postgres:13"
}

resource "docker_image" "test" {
  name = "crccheck/hello-world"
}

resource "docker_image" "jirasvcsmgmt" {
  name = "atlassian/jira-servicemanagement:4.20"
}

# Create a container for a Rocky8 Bastion
resource "docker_container" "bastion" {
  image = docker_image.rocky8.image_id
  name  = "bastion"
  tty   = true
  networks_advanced {
    name         = docker_network.devnet.name
    ipv4_address = "192.168.50.15"
  }
}

# Create a container for a postgres db
resource "docker_container" "postgres" {
  image = docker_image.postgres13.image_id
  name  = "postgres"
  tty   = true
  networks_advanced {
    name         = docker_network.devnet.name
    ipv4_address = "192.168.50.12"
  }
  env = [
    "POSTGRES_PASSWORD=postgres"
  ]
}

# docker run -v jiraVolume:/var/atlassian/application-data/jira --name="jira" -d -p 8080:8080 atlassian/jira-software

# Create a docker volume for Jira
resource "docker_volume" "jira" {
  name = "jiraVolume"
}

# Create a container for Jira
resource "docker_container" "jira" {
  image = docker_image.jirasvcsmgmt.image_id
  name  = "jira"
  tty   = true
  networks_advanced {
    name         = docker_network.devnet.name
    ipv4_address = "192.168.50.11"
  }
  volumes {
    volume_name    = docker_volume.jira.name
    container_path = "/var/atlassian/application-data/jira"
  }
  ports {
    internal = 8080
    external = 8080
  }
}

# Create a container for a webserver test
resource "docker_container" "test" {
  image = docker_image.test.image_id
  name  = "test"
  tty   = true
  networks_advanced {
    name         = docker_network.devnet.name
    ipv4_address = "192.168.50.13"
  }
  ports {
    internal = 8000
    external = 8081
  }
}

