# Política de Segurança

## Versões suportadas

A linha estável atual é a v1.x.

Correções de segurança são priorizadas para a última versão estável publicada.

## Não publique segredos

Nunca faça commit ou cole em issues públicas:

- tokens;
- senhas;
- chaves privadas;
- arquivos .env reais;
- certificados internos;
- dados de clientes;
- credenciais de cloud;
- cookies de sessão;
- logs com informações privadas desnecessárias.

## Certificados corporativos

O Super Dev Kit pode auxiliar na importação de uma CA corporativa autorizada, mas:

- o fluxo é opcional;
- a CA deve vir da própria organização/rede autorizada;
- certificados internos não devem ser versionados;
- TLS não deve ser desativado como solução permanente.

## Docker

No Linux, pertencer ao grupo docker pode conceder controle elevado sobre a máquina.

Adicione usuários ao grupo somente quando necessário.

## Cleanup e sobrescrita

Revise o preview antes de executar:

~~~text
devkit cleanup --apply
~~~

Ao gerar projetos, use --force somente quando compreender quais arquivos serão substituídos.

## Dependências externas

O projeto depende de ecossistemas como winget, apt, Docker Hub e VS Code Marketplace.

Mantenha o sistema operacional e suas ferramentas atualizados.

## Reportar vulnerabilidades

Evite publicar detalhes sensíveis em uma issue pública.

Quando o GitHub oferecer um canal privado de reporte de vulnerabilidade para o repositório, prefira esse canal.

Se precisar abrir uma issue pública, compartilhe apenas informação suficiente para indicar que existe um problema e aguarde orientação.

Leia também [Threat Model](docs/THREAT-MODEL.md).
