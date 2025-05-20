# Lines starting with '#' are comments.
# Each line is a file pattern followed by one or more owners.

# More details are here: https://help.github.com/articles/about-codeowners/

# Order is important. The last matching pattern has the most precedence.
# The folders are ordered as follows:

# In each subsection folders are ordered first by depth, then alphabetically.
# This should make it easy to add new rules without breaking existing ones.
* @OutSystems/Terraform-shared-modules

# The alert.policies folder will be owned by the ODC Engineering teams and are responsible for maintaining them.
/docs/
/environments/
/environments/dex-backend @sammieaudu/Terraform-shared-modules
/environments/dex-frontend @sammieaudu/Terraform-shared-modules
/environments/dex-nonprod @sammieaudu/Terraform-shared-modules
/environments/dex-prod @sammieaudu/Terraform-shared-modules
/modules/
/modules/amplify @sammieaudu/Terraform-shared-modules
/modules/eks @sammieaudu/Terraform-shared-modules
/modules/iam @sammieaudu/Terraform-shared-modules
/modules/lambda @sammieaudu/Terraform-shared-modules
/modules/lambda/*** @sammieaudu/Terraform-shared-modules

/modules/network @sammieaudu/Terraform-shared-modules
/modules/rds @sammieaudu/Terraform-shared-modules
/modules/s3 @sammieaudu/Terraform-shared-modules
/modules/secretmanger @sammieaudu/Terraform-shared-modules
/modules/secretmanger/sm-rotate @sammieaudu/Terraform-shared-modules
/modules/sg @sammieaudu/Terraform-shared-modules


# This file itself is owned by members who are assigned the Project Admin role in this project.
CODEOWNERS @sammieaudu/Terraform-shared-modules
README @sammieaudu/Terraform-shared-modules
