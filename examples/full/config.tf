provider "aws" {
  access_key = "dev-tfstate-backend"
  secret_key = "dev-tfstate-backend"
  region     = "us-east-1"

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#s3_use_path_style
  # s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    # s3       = "http://localhost:4566"
    s3 = "http://s3.127-0-0-1.nip.io:4566"
    dynamodb = "http://localhost:4566"
    iam      = "http://localhost:4566"
  }
}

provider "aws" {
  alias = "secondary"
  access_key = "dev-tfstate-backend"
  secret_key = "dev-tfstate-backend"
  region     = "us-west-2"

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#s3_use_path_style
  # s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    # s3       = "http://localhost:4566"
    s3 = "http://s3.127-0-0-1.nip.io:4566"
    dynamodb = "http://localhost:4566"
    iam      = "http://localhost:4566"
  }
}
