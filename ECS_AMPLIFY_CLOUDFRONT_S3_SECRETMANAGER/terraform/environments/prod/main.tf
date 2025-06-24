# S3 Module
module "s3" {
  source = "../../modules/s3"

  project_name    = var.project_name
  environment     = var.environment
  allowed_origins = ["*"]
  custom_domain_names  = ["cdn.${var.domain_name}"]
  acm_certificate_arn = var.certificate_arn
  agora_s3_user_arn = var.agora_s3_user_arn
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  project_name         = var.project_name
  environment          = var.environment
  backend_service_name = var.backend_service_name
}

# MediaConverter Module
module "mediaconvert" {
  source = "../../modules/mediaconvert"

  project_name    = var.project_name
  environment     = var.environment
  s3_bucket_name  = module.s3.bucket_name
  notification_endpoint = "https://api.${var.domain_name}/sns/media-converter"

  depends_on = [module.s3]
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  container_port       = var.container_port

  depends_on = [module.s3]
}

# Secrets Manager Module
module "secrets" {
  source = "../../modules/secrets"

  project_name    = var.project_name
  environment     = var.environment

  # App Configuration
  port           = var.port
  jwt_secret     = var.jwt_secret
  mongodb_url    = var.mongodb_url

  # AWS Configuration
  aws_access_key_id              = var.aws_access_key_id
  aws_secret_access_key          = var.aws_secret_access_key
  aws_bucket_name                = module.s3.bucket_name
  aws_bucket_name_for_cloud      = module.s3.bucket_name
  aws_region                     = var.aws_region
  cdn_url                        = "https://${module.s3.cloudfront_domain_name}/"
  aws_cloudfront_distribution_id = module.s3.cloudfront_distribution_id

  # Media Convert Configuration - now using module outputs
  mediaconvert_endpoint  = module.mediaconvert.mediaconvert_endpoint
  mediaconvert_queue_arn = module.mediaconvert.mediaconvert_queue_arn
  mediaconvert_role_arn  = module.mediaconvert.mediaconvert_role_arn
  sns_role_arn          = module.mediaconvert.sns_role_arn
  sns_topic_arn         = module.mediaconvert.sns_topic_arn

  depends_on = [module.s3, module.mediaconvert]
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# ECS Module
module "ecs" {
  source = "../../modules/ecs"

  project_name                = var.project_name
  environment                 = var.environment
  domain_name                 = var.domain_name
  container_port              = var.container_port
  certificate_arn            = var.certificate_arn
  mediaconvert_role_arn      = module.mediaconvert.mediaconvert_role_arn

  vpc_id                      = module.networking.vpc_id
  private_subnet_ids          = module.networking.private_subnet_ids
  public_subnet_ids           = module.networking.public_subnet_ids
  alb_security_group_id       = module.networking.alb_security_group_id
  ecs_tasks_security_group_id = module.networking.ecs_tasks_security_group_id
  ecr_repository_url          = module.ecr.repository_url

  depends_on = [module.networking, module.ecr, module.secrets]
}

# Amplify Module
module "amplify" {
  source = "../../modules/amplify"

  project_name       = var.project_name
  environment        = var.environment
  domain_name        = var.domain_name
  branch_name        = "main"
  api_endpoint       = module.ecs.cloudfront_domain_name
  frontend_sentry_dsn = var.frontend_sentry_dsn

  # Repository configurations
  frontend_repository = var.frontend_repository_url
  github_token       = var.github_token

  # Environment variables for frontend app
  frontend_environment_variables = {
    REACT_APP_API_ENDPOINT = module.ecs.cloudfront_domain_name
    REACT_APP_ENV         = "production"
    REACT_APP_frontend_SENTRY_DSN = var.frontend_sentry_dsn
  }

  depends_on = [module.ecs]
} 