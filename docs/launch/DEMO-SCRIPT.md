# Roteiro de demo — 60 a 90 segundos

## Cena 1 — problema

Mostrar uma máquina/VM limpa.

Fala:

> Toda vez que você prepara uma máquina de desenvolvimento nova, acaba repetindo a mesma configuração: Git, Node, Docker, VS Code, SSH, banco e várias ferramentas.

## Cena 2 — clone

~~~text
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
~~~

Fala:

> O Super Dev Kit transforma isso em um fluxo reproduzível.

## Cena 3 — dry-run

~~~text
devkit.cmd setup fullstack --dry-run
~~~

ou Linux:

~~~text
bash devkit.sh setup fullstack --dry-run
~~~

Fala:

> Antes de alterar a máquina, eu consigo visualizar exatamente o que será feito.

## Cena 4 — diagnóstico

~~~text
devkit doctor
~~~

Fala:

> Depois, o Dev Doctor valida o ambiente e aponta o próximo passo quando encontra algum problema.

## Cena 5 — stack

~~~text
devkit stack react --dry-run
~~~

Fala:

> Também dá para preparar stacks específicas.

## Cena 6 — projeto

~~~text
devkit project react-vite meu-app --dry-run
~~~

Fala:

> E gerar um projeto inicial sem depender de copiar boilerplate manualmente.

## Cena 7 — encerramento

Mostrar o GitHub.

Fala:

> O projeto é open source, funciona em Windows e Ubuntu/Linux e a v0.9 está focada em deixar tudo pronto para a comunidade.
