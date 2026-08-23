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
        sonar_agent = "master"
        ecr_registry = "130299714330.dkr.ecr.eu-central-1.amazonaws.com"
        ecr_repo = "petclinic"
    }
    registry {
        ecr_registry = "130299714330.dkr.ecr.eu-central-1.amazonaws.com"
        ecr_repo = "petclinic"
        aws_region = "eu-central-1"
    }
    gitops {
        gitops_repo = "https://github.com/mostafagheta/gitops-repo.git"
        git_credential = "40064b7c-67f3-4b2c-8d3d-57d801eb56c3"
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
