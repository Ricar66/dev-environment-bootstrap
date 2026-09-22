# Project Templates — v0.7

A v0.7 adiciona geração de projetos locais sem depender de um gerador remoto para criar a estrutura inicial.

Os templates ficam versionados em:

~~~text
templates/
~~~

## Templates disponíveis

| Template | Conteúdo |
| --- | --- |
| react-vite | React + Vite |
| node-nest | NestJS + TypeScript |
| dotnet-webapi | ASP.NET Core Web API |
| python-api | FastAPI |
| docker-compose | Compose + Nginx |

## Listar templates

CMD:

~~~cmd
tools\create-project.cmd -List
~~~

PowerShell:

~~~powershell
.\tools\create-project.ps1 -List
~~~

Linux:

~~~bash
bash tools/create-project.sh --list
~~~

## Dry-run

Antes de criar qualquer coisa:

~~~cmd
tools\create-project.cmd -Template react-vite -Name meu-app -DryRun
~~~

~~~bash
bash tools/create-project.sh --template react-vite --name meu-app --dry-run
~~~

O dry-run mostra o destino e todos os arquivos planejados sem alterar o disco.

## Criar um projeto

PowerShell:

~~~powershell
.\tools\create-project.ps1 -Template react-vite -Name "Meu App" -OutputPath .\projects
~~~

Linux:

~~~bash
bash tools/create-project.sh --template react-vite --name "Meu App" --output ./projects
~~~

O nome é normalizado para um slug seguro, por exemplo:

~~~text
Meu App -> meu-app
~~~

## Dev Container

Adicione .devcontainer/devcontainer.json:

~~~powershell
.\tools\create-project.ps1 -Template python-api -Name minha-api -WithDevContainer
~~~

~~~bash
bash tools/create-project.sh --template python-api --name minha-api --with-devcontainer
~~~

Cada template declara sua imagem recomendada no catálogo templates/catalog.json.

## Instalar dependências

Por segurança, dependências **não são instaladas automaticamente**.

Para gerar e instalar:

~~~powershell
.\tools\create-project.ps1 -Template node-nest -Name api -InstallDependencies
~~~

~~~bash
bash tools/create-project.sh --template node-nest --name api --install-deps
~~~

A instalação usa comandos explícitos por template, sem eval, e possui até três tentativas para falhas transitórias de rede.

## Proteção contra sobrescrita

Se o destino já existir e tiver arquivos, a geração é interrompida.

Use -Force / --force apenas quando quiser permitir sobrescrita dos arquivos controlados pelo template.

O modo force não apaga o diretório inteiro.

## Metadados do projeto

Cada projeto recebe:

~~~text
.devkit-project.json
~~~

Exemplo:

~~~json
{
  "schema_version": 1,
  "template": "react-vite",
  "project_name": "Meu App",
  "project_slug": "meu-app",
  "generated_by": "Super Dev Kit",
  "devcontainer": true
}
~~~

## Project Wizard

CMD:

~~~cmd
tools\project-wizard.cmd
~~~

PowerShell:

~~~powershell
.\tools\project-wizard.ps1
~~~

Linux:

~~~bash
bash tools/project-wizard.sh
~~~

O wizard pergunta template, nome, destino, Dev Container e se deve instalar dependências.

## Criando novos templates

1. crie uma pasta em templates/<slug>;
2. adicione a entrada correspondente em templates/catalog.json;
3. use {{PROJECT_NAME}} para o nome de exibição;
4. use {{PROJECT_SLUG}} para identificadores seguros;
5. use __PROJECT_NAME__ no nome de um arquivo quando precisar renomeá-lo;
6. adicione smoke tests no GitHub Actions.

Templates devem ser pequenos, legíveis e funcionais sem segredos.
