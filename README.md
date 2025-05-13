```
#Terraform

enterprise-terraform-structure/
├── modules/
│   ├── network/                # VPC, subnets, routing, etc.
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── eks/                    # EKS cluster provisioning and worker nodes
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── rds/                    # RDS provisioning for PostgreSQL
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── security/               # AWS Shield, WAF, Firewall Manager setups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── ...                     # Additional modules as needed (CI/CD configurations, S3 buckets, etc.)
├── environments/
│   ├── dex_backend/
│   │   ├── main.tf             # Aggregates modules for the dev environment
│   │   ├── backend.tf          # Remote state configuration (e.g., S3 bucket, DynamoDB for locking)
│   │   ├── variables.tf        # Environment-specific variable definitions
│   │   ├── terraform.tfvars    # Concrete values for dev
│   │   └── README.md
│   ├── dex_frontend/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── README.md
    ├── dex_nonprod/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── README.md
│   └── dex_prod/
│       ├── main.tf
│       ├── backend.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── README.md
└── docs/
    └── architecture.md       # Documentation of overall infrastructure design and module usage
