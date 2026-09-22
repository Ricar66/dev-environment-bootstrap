# Draft — LinkedIn

Depois de algumas versões evoluindo automação, diagnóstico e reprodutibilidade, o **Super Dev Kit** está chegando à v0.9.

A ideia do projeto é simples: reduzir o trabalho repetitivo de preparar uma máquina de desenvolvimento nova.

Em vez de configurar manualmente Git, Node, Python, Docker, SSH, VS Code, stacks, templates e ferramentas de diagnóstico, o projeto oferece uma CLI única:

~~~text
devkit setup fullstack
devkit doctor
devkit stack react
devkit project react-vite meu-app
devkit export
devkit compare
~~~

O projeto funciona em Windows com CMD/PowerShell e em Ubuntu/Linux com Bash.

Também inclui dry-run, manifesto local, detecção de drift, lock file reproduzível, suporte opcional a CA corporativa e templates de projeto.

Na v0.9 o foco deixou de ser adicionar features grandes e passou a ser preparar o projeto para uso público: documentação, arquitetura, troubleshooting, contribuição, testes e onboarding.

Repositório:
https://github.com/Ricar66/dev-environment-bootstrap

Se você trabalha com onboarding de devs, laboratórios, VMs ou simplesmente reinstala ambientes com frequência, feedback é bem-vindo.

#opensource #devtools #docker #linux #windows #developerexperience
