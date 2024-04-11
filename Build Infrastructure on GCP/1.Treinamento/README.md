# 1. Fundamentals
Entender o básico do funcionamento, principais comandos.


## Criar um arquivo instance.tf
Isso vai criar uma VM Instance dentro do GCP, controlada pelo Terraform.

```json
resource "google_compute_instance" "myfirst-resource-terraform" {
  project      = "<PROJECT_ID>"
  name         = "terraform"
  machine_type = "e2-medium"
  zone         = "<ZONE>"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }
}
```

## Bloco Resource
O bloco resource, tem possui dois atributos:
1. resource type - define o tipo do resource, isso depende do provider, nesse caso é o provider é o Google; (google_compute_instance)
2. resource name - nome a minha escolha, que referência esse resource dentro do scope do meu terraform; (myfirst-resource-terraform)

## Inicialização do Terraform Scope
Faz o download do(s) "plugin" para estabelecer a conexão e interpretar os comando do provider, nesse caso o provider é Google, e o plugin será "hashicorp/google" (ultima versão).

Executar o comando:
```bash
terraform init
```

## Planejamento de Execução
O terraform vai testar o conteudo do(s) arquivo(s) *.tf, dentro do diretorio, e vai simular a criação, devolvendo um resumo dos resources que vão ser criados/alterados/eliminados; caso identifique um erro, apresenta o erro;

Executar o comando:
```bash
terraform plan
```

## Aplicando as configurações
Com esse comando, o terraform repete uma simulação, como no comando "terraform plan", poem no final, se não identificar erros, ele pergunta se deve aplicar, se reponder "yes", ele inicializa a criação do resource; 

Executar o comando:
```bash
terraform apply
```

## Consultar Status
Apresenta o status atual das configurações aplicadas para os resources controlados dentro do diretório onde o comando foi executado; 

Executar o comando:
```bash
terraform show
```


## Obs.:
- O nome do arquivo não é obrigatório, mas seguir o padrão facilita por existir um padrão pré-definido;
- O scope do terraform, nesse capitulo, é definido como sendo o diretório onde foi criado o arquivo *.tf;
- O terraform identifica o provider com base no resource type;