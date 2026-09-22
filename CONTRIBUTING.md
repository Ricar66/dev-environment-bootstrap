# Contribuindo

Obrigado por ajudar a melhorar o projeto.

## Antes de abrir um PR

1. explique o problema que a mudança resolve;
2. mantenha os scripts legíveis;
3. evite comandos que reduzam segurança apenas para contornar erros;
4. não inclua tokens, senhas, certificados internos ou dados pessoais;
5. atualize a documentação quando alterar comportamento.

## Testes recomendados

### Windows

Execute o PowerShell Script Analyzer quando disponível:

```powershell
Invoke-ScriptAnalyzer .\windows\setup-windows.ps1
Invoke-ScriptAnalyzer .\diagnostics\dev-doctor.ps1
Invoke-ScriptAnalyzer .\setup.ps1
```

### Linux

```bash
bash -n linux/bootstrap-vm-ubuntu.sh
bash -n diagnostics/dev-doctor.sh
bash -n setup.sh
shellcheck linux/bootstrap-vm-ubuntu.sh diagnostics/dev-doctor.sh setup.sh
```

## Commits

Prefira mensagens objetivas, por exemplo:

```text
feat: adiciona instalação opcional do Docker Desktop
fix: melhora detecção de certificado corporativo
docs: adiciona guia de SSH no VirtualBox
```
