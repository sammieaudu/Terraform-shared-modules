variable "domain_name" {
  description = "Name of the CodeArtifact domain"
  type        = string
}

variable "repository_name" {
  description = "Name of the CodeArtifact repository"
  type        = string
}

variable "description" {
  description = "Description for the repository"
  type        = string
  default     = ""
}

variable "external_connections" {
  description = "Optional list of external connections like public:npmjs"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}