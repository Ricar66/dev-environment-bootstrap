# Como adicionar um adapter de version manager

Adapters permitem ao Super Dev Kit usar um version manager já instalado.

## Princípio

O projeto não deve baixar e executar automaticamente instaladores remotos de managers.

## 1. Registre o manager

Edite versions/managers.json e associe o manager ao runtime correto.

## 2. Implemente Windows e Linux

Arquivos principais:

~~~text
tools/runtime-manager.ps1
tools/runtime-manager.sh
~~~

## 3. Nunca use eval

Monte comandos como listas ou arrays de argumentos. A versão informada deve passar por validação antes de chegar ao processo externo.

## 4. Mantenha fallback

Se o manager não existir, o bootstrap padrão não deve quebrar. O fluxo deve cair para native e permitir validação posterior pela constraint.

## 5. Dry-run obrigatório

Todo adapter precisa mostrar o comando planejado sem executá-lo.

## 6. CI

Inclua smoke tests com --dry-run ou -DryRun.

## Checklist

- [ ] catálogo atualizado;
- [ ] PowerShell;
- [ ] Bash;
- [ ] validação de argumento;
- [ ] sem eval;
- [ ] fallback nativo;
- [ ] dry-run;
- [ ] CI;
- [ ] documentação.
