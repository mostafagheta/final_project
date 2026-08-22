/*
  JTE Pipeline Configuration for Spring Petclinic
  Filename must be pipeline_config.groovy at the repo root.
*/

jte {
    pipeline_template = "app_pipeline"
}

libraries {
    s3_versioning
    java_build
    security_scan
    registry
    gitops
    deploy
    infra
    infra_validation
    common
}

application_environments {
    dev
    test
    prod
}

app_name = "spring-petclinic"
sonar_project_key = "spring-petclinic-main"

ecr_registry = "130299714330.dkr.ecr.eu-central-1.amazonaws.com"
ecr_repo = "petclinic"
aws_region = "eu-central-1"

gitops_repo = "https://github.com/mostafagheta/gitops-repo.git"

s3_bucket = "atos-versioning-bucket"
s3_version_file = "versions/version.json"
