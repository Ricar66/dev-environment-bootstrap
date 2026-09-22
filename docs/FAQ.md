# FAQ

## O Super Dev Kit substitui Docker, Node, Python ou VS Code?

Não. Ele automatiza a preparação e validação dessas ferramentas.

## Preciso usar a CLI global?

Não. Você pode usar diretamente devkit.cmd, .\devkit.ps1 ou bash devkit.sh. O comando global devkit é opcional.

## O projeto funciona no CMD?

Sim. O Windows possui launchers CMD que reutilizam a implementação PowerShell.

## Funciona no PowerShell 5.1?

O projeto mantém compatibilidade com Windows PowerShell 5.1 e também valida PowerShell 7 nos fluxos suportados.

## Preciso de certificado corporativo?

Na maioria das máquinas, não. Use esse fluxo apenas quando a rede fizer inspeção HTTPS e aparecer erro como x509: certificate signed by unknown authority.

## O projeto distribui o certificado da minha empresa ou escola?

Não. Certificados internos não devem ser enviados ao repositório. O projeto ajuda a exportar, localizar, validar e importar a CA autorizada da própria rede.

## Posso executar primeiro sem alterar nada?

Sim. Prefira --dry-run quando o comando oferecer essa opção.

~~~text
devkit setup fullstack --dry-run
devkit stack react --dry-run
devkit project react-vite meu-app --dry-run
~~~

## O cleanup pode remover programas que já estavam instalados?

O objetivo é não remover itens preexistentes. O manifesto registra o que já existia e o que foi instalado pelo kit. Confira o preview antes de usar --apply.

## Onde ficam os dados locais?

Principalmente em .super-dev-kit/. Esse diretório é ignorado pelo Git.

## O lock file contém senhas?

Não deve conter tokens, senhas, chaves privadas nem conteúdo de certificados. Mesmo assim, revise arquivos antes de compartilhá-los.

## Posso usar em uma VM?

Sim. Ubuntu em VirtualBox é um cenário suportado e documentado.

## Posso usar WSL?

O setup Windows consegue habilitar ou instalar WSL quando solicitado. O bootstrap Linux foi desenhado principalmente para Ubuntu/Linux e VMs.

## Por que version managers não são instalados automaticamente?

Porque baixar e executar scripts externos automaticamente aumenta risco e reduz previsibilidade. Os adapters usam managers já disponíveis e mantêm fallback nativo.

## Por que alguns runtimes usam constraints em vez de patch exato?

Porque winget, apt e distribuições diferentes não possuem necessariamente os mesmos builds. O kit prefere declarar a política desejada e validar o resultado.

## Como vejo se meu ambiente está saudável?

~~~text
devkit doctor
~~~

## Como reproduzo meu ambiente em outra máquina?

~~~text
devkit export
devkit import --dry-run
devkit import
devkit compare
~~~

## Como crio um projeto inicial?

~~~text
devkit project list
devkit project react-vite meu-app
~~~

## Como reporto um bug?

Abra uma issue usando o template de bug e inclua sistema operacional, versão do Super Dev Kit, comando executado, saída do Dev Doctor e mensagem de erro sem dados sensíveis.
