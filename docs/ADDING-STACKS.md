# Como adicionar uma stack

Stacks combinam módulos existentes em um ambiente reutilizável.

## 1. Verifique os módulos

Consulte modules/catalog.json. Se a tecnologia já existe como módulo, reutilize-a.

## 2. Crie o manifest da stack

Crie stacks/minha-stack.json e use uma stack existente como referência.

A stack deve declarar composição e metadados, evitando duplicar listas de pacotes.

## 3. Prefira dependências entre módulos

Se um módulo depende de outro, essa relação deve ficar no catálogo de módulos.

~~~json
{
  "depends_on": ["node", "docker"]
}
~~~

## 4. Teste dry-run

~~~text
devkit stack minha-stack --dry-run
~~~

Windows e Linux devem resolver a mesma intenção, mesmo que usem pacotes diferentes.

## 5. Atualize documentação e CI

Inclua objetivo, módulos, runtimes, limitações e um smoke test.

## Checklist

- [ ] nome curto e previsível;
- [ ] JSON válido;
- [ ] módulos reutilizados;
- [ ] sem segredos;
- [ ] dry-run Windows;
- [ ] dry-run Linux;
- [ ] documentação atualizada.
