# 2. Infrastructure Code
Criar novos recursos, e alterar recursos já controlados pelo terraform, destrutir/remover recursos, entender a sequencia (workflow/dependencias) de passos para alterar e/ou destruir um recurso, e casos em que uma alteração requer que o recurso seja destruido e criado novamente.

## Criar um arquivo main.tf


## [Task 1 - Criar uma resource (Rede VPC)](#Task1)
O arquivo define qual é o provider e versão que pretendo usar. E uma rede VPC.

-   Criar um arquivo main.tf
    ```json
    terraform {
        required_providers {
            google = {
                source = "hashicorp/google"
                version = "3.5.0"
            }
        }
    }

    provider "google" {
        project = "<PROJECT_ID>"
        region  = "<REGION>"
        zone    = "<ZONE>"
    }

    resource "google_compute_network" "myvpc_resource_network" {
        name = "terraform-network"
    }
    ```
    -   ### Bloco Terraform
        Define qual plugin será utilizado e qual versão;

    -   ### Bloco Provider
        Define dentro do Provedor de Cloud, no caso Google GCP, onde os recursos serão criado, qual projeto, em qual região, etc...

    -   ### Bloco Resource
        Cria uma rede VPC, com nome "terraform-network";
---
-   Executar os comandos.

    1.  [Inicialização do Terraform Scope](../1.Treinamento/README.md#inicialização-do-terraform-scope)
    ```bash
    terraform init
    ```
    2.   [Aplicando as configurações](../1.Treinamento/README.md#aplicando-as-configurações)
    ```bash
    terraform apply
    ```

    3.   [Consultar Status](../1.Treinamento/README.md#consultar-status)
    ```bash
    terraform show
    ```
---

## [Task 2 - Adicionar um novo resource](#Task2)
Cria uma VM Intance, e conectada na rede (a referência myvpc_resource_network, só existe no scope atual, dentro do diretório, e possui os atributos do resource criado na [Task 1](#Task1)).

-   Alterar o arquivo main.tf, adicionar o resource abaixo:
    ```json
    resource "google_compute_instance" "myvm_resource_instance" {
        name         = "terraform-instance"
        machine_type = "e2-micro"

        boot_disk {
            initialize_params {
                image = "debian-cloud/debian-11"
            }
        }

        network_interface {
            network = google_compute_network.myvpc_resource_network.name
            access_config {
            }
        }
    }
    ```
    -   Executar os comandos ([Aplicando as configurações](../1.Treinamento/README.md#aplicando-as-configurações)).
        ```bash
        terraform apply
        ```
---
-   Alterar o arquivo main.tf, adicionar tags ao resource myvm_resource_instance (Essa alteração só altera a VM Instance):
    ```json
    resource "google_compute_instance" "myvm_resource_instance" {
        name         = "terraform-instance"
        machine_type = "e2-micro"
        
        tags         = ["web","dev"]

        boot_disk {
            initialize_params {
                image = "debian-cloud/debian-11"
            }
        }

        network_interface {
            network = google_compute_network.myvpc_resource_network.name
            access_config {
            }
        }
    }
    ```
    -   Executar os comandos ([Aplicando as configurações](../1.Treinamento/README.md#aplicando-as-configurações)).
        ```bash
        terraform apply
        ```
---
-   Alterar o arquivo main.tf, mudar a iamge para "cos-cloud/cos-stable" do resource myvm_resource_instance (Essa alteração destroi/elimina e re-cria a VM Instance):
    ```json
    resource "google_compute_instance" "myvm_resource_instance" {
        name         = "terraform-instance"
        machine_type = "e2-micro"
        
        tags         = ["web","dev"]

        boot_disk {
            initialize_params {
                image = "cos-cloud/cos-stable"
            }
        }

        network_interface {
            network = google_compute_network.myvpc_resource_network.name
            access_config {
            }
        }
    }
    ```
    -   Executar os comandos ([Aplicando as configurações](../1.Treinamento/README.md)).
        ```bash
        terraform apply
        ```
---
-   Para destruir todos os resources, controlados pelo terraform dentro do diretório.
    -   Executar os comandos ([Destruir/Eliminar resources](../1.Treinamento/README.md)).
        ```bash
        terraform destroy
        ```

## [Task 3 - Adicionar dependência em novo resource](#Task3)
Criar um IP estático, e adicionar a VM Instance.

-   Adicionar no arquivo main.tf
    ```json
    resource "google_compute_address" "myvpc_resource_static_ip" {
        name = "terraform-static-ip"
    }
    ```
    -   Executar os comandos ([Planejamento de Execução](../1.Treinamento/README.md#planejamento-de-execução)).
        ```bash
        terraform plan
        ```

-   Atualizar o resource myvm_resource_instance no arquivo main.tf
    ```json
    resource "google_compute_instance" "myvm_resource_instance" {
        name         = "terraform-instance"
        machine_type = "e2-micro"
        
        tags         = ["web","dev"]

        boot_disk {
            initialize_params {
                image = "cos-cloud/cos-stable"
            }
        }

        network_interface {
            network = google_compute_network.myvpc_resource_network.self_link
            access_config {
                nat_ip  = google_compute_address.myvpc_resource_static_ip.address
            }
        }
    }
    ```
    -   Executar os comandos ([Planejamento de Execução](../1.Treinamento/README.md#planejamento-de-execução)).
        ```bash
        terraform plan -out static_ip
        ```
        -   Exporta o planejamento para um arquivo que pode ser utilizado depois, indepêndente de alterações no arquivo de configuração, gerando uma imagem de "backup" da configuração.

    ---

    -   Executar os comandos ([Aplicando as configurações](../1.Treinamento/README.md#aplicando-as-configurações)).
        ```bash
        terraform apply "static_ip"
        ```

    -   Dependências implicita e explicita
        -   Implicita: O terraform analisa os arquivos *.tf e identifica as dependências entre os diferêntes resources, quando possível.
        -   Explicita: Definindo um atributo em cada resource "depends_on", em formato array, e recebendo como valor o nome definido para o resource que ele depende.

    ```json
    # New resource for the storage bucket our application will use.
    resource "google_storage_bucket" "example_bucket" {
        name     = "<UNIQUE-BUCKET-NAME>"
        location = "US"

        website {
            main_page_suffix = "index.html"
            not_found_page   = "404.html"
        }
    }

    # Create a new instance that uses the bucket
    resource "google_compute_instance" "another_instance" {
        # Tells Terraform that this VM instance must be created only after the
        # storage bucket has been created.
        depends_on = [google_storage_bucket.example_bucket]

        name         = "terraform-instance-2"
        machine_type = "e2-micro"

        boot_disk {
            initialize_params {
                image = "cos-cloud/cos-stable"
            }
        }

        network_interface {
            network = google_compute_network.vpc_network.self_link
            access_config {
            }
        }
    }
    ```

## [Task 4 - Provisão de infraestrutura](#Task4)
Criar um IP estático, e adicionar a VM Instance.

-   Alterar no arquivo main.tf
    ```json
    resource "google_compute_instance" "myvm_resource_instance" {
        name         = "terraform-instance"
        machine_type = "e2-micro"
        tags         = ["web", "dev"]

        provisioner "local-exec" {
            command = "echo ${google_compute_instance.myvm_resource_instance.name}:  ${google_compute_instance.myvm_resource_instance.network_interface[0].access_config[0].nat_ip} >> ip_address.txt"
        }

    # ...
    }
    ```
    -   Executar os comandos para forçar ser re-criado  ([Contâminar Instância](../1.Treinamento/README.md#marcar-como-contâminado-um-resources)).
        ```bash
        terraform taint google_compute_instance.myvm_resource_instance
        ```

    -   Executar os comandos ([Aplicando as configurações](../1.Treinamento/README.md#aplicando-as-configurações)).
        ```bash
        terraform apply
        ```

## Obs.:
- É recomendado definir o provider e versão que pretende usar, para evitar que atualizações de plugin funcionem de forma diferente daquela que ocorreu na primeira execução, e permite controlar quando é mais conveniente partir para novas versões;
- Provisão de infraestrutura só ocorre quando cria/recria o resource, no caso a VM instância;
- Uma instância pode ser marcada como "contaminada", para obrigar o terraform a eliminar e re-criar a instância.