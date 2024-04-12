# 3. Interaction with Modules
Organizar os arquivos e reutilização de código, uso de variaveis e outputs, usar modulos do [Terraform Registry](https://registry.terraform.io/), criar um modulo novo local.

## O que é um modulo do Terraform
Um modulo do terraform é uma combinação de arquivos, dentro de diretório. 
-   Root Module
    -   Quando não cria um modulo, mas aplica um arquivo *.tf, é criado um "root module" our "minimal-module".
    -   Estrutura de arquivos:
        ```
        -   LICENCE
        -   README.md
        -   main.tf
        -   variables.tf
        -   outputs.tf
        ```

-   Local Module
    -   a
    -   Estrutura de arquivos:
        ```
        -   main.tf
        -   variables.tf
        -   outputs.tf
        -   modules/<MODULE_NAME>
            -   LICENCE
            -   README.md
            -   website.tf
            -   variables.tf
            -   outputs.tf
        ```

-   Remote Module
    -   Quando cria resources usando modulos que existem em um repositório (ao fazer o "terraform init", faz download do [Terraform Registry](https://registry.terraform.io/)).

## [Task 1 - Usar um modulo do Registry](#Task1)

## [Task 2 - Criar e usar um modulo local](#Task2)
Cria uma VM Intance, e conectada na rede (a referência myvpc_resource_network, só existe no scope atual, dentro do diretório, e possui os atributos do resource criado na [Task 1](#Task1)).

-   Criar o Modulo
    -   Editar o arquivo modules/gcs-static-website-bucket/website.tf, adicionar o resource abaixo:
        ```json
        resource "google_storage_bucket" "bucket" {
            name               = var.name
            project            = var.project_id
            location           = var.location
            storage_class      = var.storage_class
            labels             = var.labels
            force_destroy      = var.force_destroy
            uniform_bucket_level_access = true

            versioning {
                enabled = var.versioning
            }

            dynamic "retention_policy" {
                for_each = var.retention_policy == null ? [] : [var.retention_policy]
                content {
                    is_locked        = var.retention_policy.is_locked
                    retention_period = var.retention_policy.retention_period
                }
            }

            dynamic "encryption" {
                for_each = var.encryption == null ? [] : [var.encryption]
                content {
                    default_kms_key_name = var.encryption.default_kms_key_name
                }
            }

            dynamic "lifecycle_rule" {
                for_each = var.lifecycle_rules
                content {
                    action {
                        type          = lifecycle_rule.value.action.type
                        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
                    }
                    condition {
                        age                   = lookup(lifecycle_rule.value.condition, "age", null)
                        created_before        = lookup(lifecycle_rule.value.condition, "created_before", null)
                        with_state            = lookup(lifecycle_rule.value.condition, "with_state", null)
                        matches_storage_class = lookup(lifecycle_rule.value.condition, "matches_storage_class", null)
                        num_newer_versions    = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
                    }
                }
            }
        }
        ```

    -   Editar o arquivo modules/gcs-static-website-bucket/variables.tf, adicionar o resource abaixo:
        ```json
        variable "name" {
            description = "The name of the bucket."
            type        = string
        }

        variable "project_id" {
            description = "The ID of the project to create the bucket in."
            type        = string
        }

        variable "location" {
            description = "The location of the bucket."
            type        = string
        }

        variable "storage_class" {
            description = "The Storage Class of the new bucket."
            type        = string
            default     = null
        }

        variable "labels" {
            description = "A set of key/value label pairs to assign to the bucket."
            type        = map(string)
            default     = null
        }


        variable "bucket_policy_only" {
            description = "Enables Bucket Policy Only access to a bucket."
            type        = bool
            default     = true
        }

        variable "versioning" {
            description = "While set to true, versioning is fully enabled for this bucket."
            type        = bool
            default     = true
        }

        variable "force_destroy" {
            description = "When deleting a bucket, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects."
            type        = bool
            default     = true
        }

        variable "iam_members" {
            description = "The list of IAM members to grant permissions on the bucket."
            type = list(object({
                role   = string
                member = string
            }))
            default = []
        }

        variable "retention_policy" {
            description = "Configuration of the bucket's data retention policy for how long objects in the bucket should be retained."
            type = object({
                is_locked        = bool
                retention_period = number
            })
            default = null
        }

        variable "encryption" {
            description = "A Cloud KMS key that will be used to encrypt objects inserted into this bucket"
            type = object({
                default_kms_key_name = string
            })
            default = null
        }

        variable "lifecycle_rules" {
            description = "The bucket's Lifecycle Rules configuration."
            type = list(object({
                # Object with keys:
                # - type - The type of the action of this Lifecycle Rule. Supported values: Delete and SetStorageClass.
                # - storage_class - (Required if action type is SetStorageClass) The target Storage Class of objects affected by this Lifecycle Rule.
                action = any

                # Object with keys:
                # - age - (Optional) Minimum age of an object in days to satisfy this condition.
                # - created_before - (Optional) Creation date of an object in RFC 3339 (e.g. 2017-06-13) to satisfy this condition.
                # - with_state - (Optional) Match to live and/or archived objects. Supported values include: "LIVE", "ARCHIVED", "ANY".
                # - matches_storage_class - (Optional) Storage Class of objects to satisfy this condition. Supported values include: MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, STANDARD, DURABLE_REDUCED_AVAILABILITY.
                # - num_newer_versions - (Optional) Relevant only for versioned objects. The number of newer versions of an object to satisfy this condition.
                condition = any
            }))
            default = []
        }
        ```

    -   Editar o arquivo modules/gcs-static-website-bucket/output.tf, adicionar o resource abaixo:
        ```json
        output "bucket" {
            description = "The created storage bucket"
            value       = google_storage_bucket.bucket
        }
        ```

---
-   Root directory, que usa o module local
    -   Editar o arquivo main.tf, adicionar o resource abaixo:
        ```json
        module "gcs-static-website-bucket" {
            source = "./modules/gcs-static-website-bucket"

            name       = var.name
            project_id = var.project_id
            location   = "<REGION>"

            lifecycle_rules = [{
                action = {
                    type = "Delete"
                }
                condition = {
                    age        = 365
                    with_state = "ANY"
                }
            }]
        }
        ```

    -   Editar o arquivo output.tf, adicionar o resource abaixo:
        ```json
        output "bucket-name" {
            description = "Bucket names."
            value       = "module.gcs-static-website-bucket.bucket"
        }
        ```

    -   Editar o arquivo variables.tf, adicionar o resource abaixo:
        ```json
        variable "project_id" {
            description = "The ID of the project in which to provision resources."
            type        = string
            default     = "FILL IN YOUR PROJECT ID HERE"
        }

        variable "name" {
            description = "Name of the buckets to create."
            type        = string
            default     = "FILL IN A (UNIQUE) BUCKET NAME HERE"
        }
        ```
---
-   Executar os comandos.

    1.  [Inicialização do Terraform Scope](../1.Treinamento/README.md#inicialização-do-terraform-scope)
        ```bash
        terraform init
        ```
    2.  [Aplicando as configurações](../1.Treinamento/README.md#aplicando-as-configurações)
        ```bash
        terraform apply
        ```