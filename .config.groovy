/*
   JTE configuration for Spring Petclinic Application
*/


pipelineConfig {
    /* Application Pipeline Library Setup */
    libraries {
        merge = true
    }


    /* Build/App Config */
    app_name = "spring-petclinic"
    sonar_project_key = "spring-petclinic-main"
    
    /* ECR Config */
    ecr_registry = "130299714330.dkr.ecr.eu-central-1.amazonaws.com"
    ecr_repo = "petclinic"
    aws_region = "eu-central-1"
    
    /* GitOps Config */
    gitops_repo = "https://github.com/mostafagheta/gitops-repo.git"
    
    /* Versioning Config */
    s3_bucket = "atos-versioning-bucket"
    s3_version_file = "versions/version.json"
}
