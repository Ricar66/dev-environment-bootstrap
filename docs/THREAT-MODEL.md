# Threat Model — Super Dev Kit v1

Este documento resume os principais riscos considerados pelo projeto.

## Ativos protegidos

- credenciais do usuário;
- arquivos pessoais;
- configuração da máquina;
- trust store de certificados;
- ambiente Docker;
- PATH;
- repositórios e projetos;
- manifesto e lock file.

## Ameaças principais

### Execução de comandos privilegiados

Setup e cleanup podem usar privilégios elevados.

Mitigações:

- dry-run;
- comandos explícitos;
- scripts versionados;
- CI;
- nenhuma instalação silenciosa de version managers remotos.

### Certificados corporativos

Adicionar uma CA altera confiança TLS da máquina.

Mitigações:

- fluxo opcional;
- inspeção de subject/issuer/fingerprint;
- confirmação;
- certificados locais ignorados pelo Git;
- nenhuma CA privada distribuída pelo projeto.

### Cleanup destrutivo

Remover software incorreto pode quebrar a máquina.

Mitigações:

- preview padrão;
- --apply explícito;
- manifesto;
- diferenciação entre preexistente e instalado pelo kit.

### Sobrescrita de projetos

Mitigações:

- diretórios não vazios são protegidos;
- --force explícito;
- templates sem segredos.

### Atualização do kit

Mitigações:

- git pull --ff-only;
- bloqueio quando há mudanças locais;
- código versionado e revisável.

### Dependências externas

winget, apt, Docker Hub, VS Code Marketplace e runtimes podem mudar fora do controle do projeto.

Mitigações:

- validação após instalação;
- constraints;
- fallbacks;
- Dev Doctor;
- CI recorrente.

### Docker

Acesso ao grupo docker em Linux equivale a alto privilégio.

Mitigação:

- documentação explícita;
- uso somente quando Docker é necessário.

## Fora de escopo

O projeto não tenta proteger contra:

- sistema operacional já comprometido;
- repositório Git comprometido;
- pacote upstream malicioso assinado/servido pelo fornecedor;
- administrador local malicioso.

## Reporte

Consulte SECURITY.md e nunca publique segredos em issues públicas.
