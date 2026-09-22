# Mídia pública

As capturas públicas do Super Dev Kit devem ser baseadas em **execuções reais da CLI**.

A partir da v1.0, elas são geradas por:

~~~text
python tools/generate-cli-media.py
~~~

O script executa a CLI, sanitiza dados específicos da máquina e renderiza os resultados em imagens de terminal.

## Arquivos gerados

A automação cria em docs/media/generated/:

~~~text
cli-help.png
setup-fullstack-dry-run.png
dev-doctor.png
project-react-vite-dry-run.png
cli-demo.gif
capture-manifest.json
~~~

O GIF é construído a partir das mesmas capturas reais.

## Comandos capturados

~~~text
devkit help
devkit setup fullstack --dry-run
devkit doctor
devkit project react-vite demo --dry-run
~~~

No workflow Linux, os launchers são executados como bash devkit.sh ....

## Sanitização

Antes de renderizar, o gerador remove ou substitui:

- caminhos absolutos do repositório;
- diretório home;
- usuário;
- hostname;
- endereços IPv4;
- e-mails;
- caminho temporário usado pela captura.

A saída longa pode ser encurtada apenas para caber no layout visual. O manifesto registra o comando e o exit code real de cada execução.

## Regra de segurança

Antes de publicar qualquer nova mídia, confirme que ela não mostra:

- nome de usuário pessoal;
- hostname corporativo;
- IP interno;
- tokens;
- e-mail privado;
- nomes de clientes;
- certificados internos;
- histórico de terminal com segredos.

## Regra de autenticidade

Imagens geradas por IA podem ser usadas como **capa promocional**, mas nunca como evidência de que a CLI foi executada.

As screenshots e a demo técnica do README devem vir do gerador de mídia ou de uma captura real revisada.

## Geração automática

O workflow .github/workflows/media-capture.yml roda quando o gerador de mídia é alterado na main.

Ele:

1. executa os comandos reais;
2. gera screenshots e GIF;
3. atualiza a seção de mídia do README;
4. envia os arquivos para uma branch dedicada;
5. permite revisão antes do merge final.

## Execução local

Instale Pillow:

~~~bash
python -m pip install pillow
~~~

Depois:

~~~bash
python tools/generate-cli-media.py
~~~

Revise todos os arquivos antes de publicá-los.
