/*
  JTE Pipeline Configuration for Spring Petclinic
  Library parameters are read by steps via the autowired `config` map.
*/

jte {
    pipeline_template = "app_pipeline"
}

libraries {
    s3_versioning {
        s3_bucket = "atos-versioning-bucket"
        s3_version_file = "version.json"
    }
    java_build
    security_scan {
        sonar_project_key = "spring-petclinic-main"
        sonar_token_credential = "spring-petclinic-main"
        sonar_server = "SonarQube"
        nvd_api_key_credential = "nvd-api-key"
    }
    registry {
        ecr_registry = "130299714330.dkr.ecr.eu-central-1.amazonaws.com"
        ecr_repo = "petclinic"
        aws_region = "eu-central-1"
    }
    gitops {
        gitops_repo = "https://github.com/mostafagheta/gitops-repo.git"
    }
    deploy
    infra
    infra_validation
    common
}

keywords {
    app_name = "spring-petclinic"
    sonar_project_key = "spring-petclinic-main"
    ecr_registry = "130299714330.dkr.ecr.eu-central-1.amazonaws.com"
    ecr_repo = "petclinic"
    aws_region = "eu-central-1"
    gitops_repo = "https://github.com/mostafagheta/gitops-repo.git"
    s3_bucket = "atos-versioning-bucket"
    s3_version_file = "version.json"
}
