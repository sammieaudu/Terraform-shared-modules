variable "env" {
  type    = string
}

variable "repository_name" {
  description = "Name of the CodeArtifact repository"
  type        = string
}

variable "external_connections" {
  description = "Optional list of external connections like public:npmjs"
  type        = map(string)
}