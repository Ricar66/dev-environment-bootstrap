# Contribuindo com o Super Dev Kit

Obrigado por ajudar a melhorar o projeto.

O objetivo é manter o Super Dev Kit legível, seguro, multiplataforma e útil também para quem está aprendendo.

Leia também o [Código de Conduta](CODE_OF_CONDUCT.md).

## Antes de começar

1. procure uma issue existente;
2. para mudanças maiores, descreva a proposta antes de implementar;
3. nunca publique credenciais, certificados internos ou dados privados;
4. use uma branch dedicada;
5. faça dry-run quando a mudança puder alterar a máquina.

## Ambiente de desenvolvimento

Clone:

~~~text
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
~~~

Valide a CLI:

~~~text
devkit.cmd version
.\devkit.ps1 version
bash devkit.sh version
~~~

## Arquitetura

Antes de alterar o projeto, leia [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

A regra principal é: **não duplicar lógica entre CLI, CMD, PowerShell e Bash**.

A CLI deve delegar para os componentes especializados.

## Padrões de segurança

Não aceite uma solução que dependa de:

- desabilitar TLS;
- usar curl -k como solução permanente;
- executar scripts remotos sem revisão;
- salvar segredos no repositório;
- apagar itens preexistentes sem confirmação;
- sobrescrever projetos silenciosamente.

## Testes locais recomendados

### Linux

~~~bash
bash -n devkit.sh
bash -n tools/devkit.sh
bash -n setup.sh
shellcheck devkit.sh tools/devkit.sh setup.sh
bash devkit.sh version
bash devkit.sh stack react --dry-run
python3 tools/check-docs.py
~~~

### Windows PowerShell 5.1

~~~powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\devkit.ps1 version
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\devkit.ps1 stack react --dry-run
~~~

### PowerShell 7

~~~powershell
pwsh -NoLogo -NoProfile -File .\tools\devkit.ps1 version
pwsh -NoLogo -NoProfile -File .\tools\devkit.ps1 stack react --dry-run
~~~

### CMD

~~~cmd
call devkit.cmd version
call devkit.cmd stack react --dry-run
~~~

## Mudanças em componentes declarativos

- stacks: [docs/ADDING-STACKS.md](docs/ADDING-STACKS.md)
- templates: [docs/ADDING-TEMPLATES.md](docs/ADDING-TEMPLATES.md)
- adapters de runtime: [docs/ADDING-ADAPTERS.md](docs/ADDING-ADAPTERS.md)

## Commits

Prefira mensagens curtas no estilo:

~~~text
feat: adiciona nova stack
fix: corrige detecção de Docker Compose
docs: melhora guia de troubleshooting
test: adiciona smoke test da CLI
chore: atualiza template de issue
~~~

## Pull requests

O PR deve explicar:

- problema;
- solução;
- plataformas afetadas;
- como foi testado;
- se existe breaking change.

O template do repositório contém o checklist completo.

## Documentação

Ao alterar comportamento público, atualize a documentação na mesma mudança.

Rode:

~~~text
python tools/check-docs.py
~~~

Esse check valida UTF-8 e links relativos da documentação.

## Bugs

Use o template de bug e inclua, quando possível:

~~~text
devkit version
devkit doctor
devkit state
~~~

Remova dados sensíveis antes de enviar.

## Compatibilidade

Consulte [docs/SUPPORT-MATRIX.md](docs/SUPPORT-MATRIX.md).

Mudanças que removam suporte precisam ser explicitamente discutidas e documentadas.
