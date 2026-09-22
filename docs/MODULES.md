# Arquitetura de módulos

A partir da v0.5, o Super Dev Kit separa **o que uma tecnologia precisa** da lógica que executa a instalação.

O catálogo fica em:

```text
modules/catalog.json
```

Cada módulo pode declarar:

```json
{
  "node": {
    "name": "Node.js",
    "description": "Runtime JavaScript e npm.",
    "depends_on": [],
    "windows_packages": ["OpenJS.NodeJS.LTS"],
    "linux_packages": ["nodejs", "npm"],
    "vscode_extensions": [
      "dbaeumer.vscode-eslint",
      "esbenp.prettier-vscode"
    ]
  }
}
```

## Campos

- `name`: nome amigável;
- `description`: objetivo do módulo;
- `depends_on`: outros módulos necessários;
- `windows_packages`: IDs usados pelo winget;
- `linux_packages`: pacotes usados pelo apt;
- `vscode_extensions`: extensões recomendadas.

## Dependências

Um módulo pode depender de outro.

Exemplo conceitual:

```text
nestjs
├── node
└── docker
```

O instalador de stacks resolve essas dependências antes da instalação e remove duplicatas.

## Como adicionar um módulo

1. edite `modules/catalog.json`;
2. escolha um identificador curto e estável;
3. declare apenas dependências realmente necessárias;
4. use IDs oficiais do gerenciador de pacotes;
5. adicione extensões VS Code somente quando agregarem valor;
6. crie ou atualize uma stack que utilize o módulo;
7. execute o dry-run no Windows e no Linux;
8. deixe o GitHub Actions validar o JSON e os scripts.

## Princípio

Um módulo deve ser pequeno.

Evite um módulo chamado `everything` com dezenas de ferramentas. Prefira composição:

```text
fullstack-react-node
├── react
│   └── node
├── nestjs
│   ├── node
│   └── docker
└── sql
```

Isso facilita manutenção, contribuição e testes.
