# Certificados locais

Esta pasta contém os utilitários do Super Dev Kit para trabalhar com certificados CA de redes corporativas.

## Exportar no Windows

Procure pelo emissor:

```powershell
.\certificates\export-root-ca.ps1 -Search "nome-do-emissor"
```

Por padrão, o certificado público é salvo em:

```text
certificates\local\devkit-root-ca.cer
```

A pasta `certificates/local` é ignorada pelo Git. Isso ajuda a manter certificados internos fora do repositório público.

Se a VM VirtualBox usa a pasta Downloads do Windows como compartilhamento, você pode exportar diretamente para Downloads:

```powershell
.\certificates\export-root-ca.ps1 -Search "nome-do-emissor" -OutputPath "$env:USERPROFILE\Downloads\devkit-root-ca.cer"
```

## Importar no Ubuntu

Com um caminho conhecido:

```bash
sudo bash certificates/import-ca-linux.sh /caminho/devkit-root-ca.cer
```

Ou procurar automaticamente em Downloads, `/media` e `/mnt`:

```bash
sudo bash certificates/import-ca-linux.sh --auto
```

Antes de confiar no certificado, o script mostra Subject, Issuer, validade e fingerprint SHA-256.

## Segurança

O exportador usa `Export-Certificate`, que exporta apenas o certificado público. Ele não exporta a chave privada.

Mesmo assim, certificados internos podem revelar informações sobre uma organização. Não os publique sem autorização.
