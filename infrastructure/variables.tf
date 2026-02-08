variable "project_configs" {
  description = "ships_pj 用の Google Cloud プロジェクト"
  type        = map(string)
  default = {
    development = "linen-tempest-463722-f2"
    production  = "linen-tempest-463722-f2"
  }
}
