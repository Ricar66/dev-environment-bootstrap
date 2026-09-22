# Certificados corporativos e erro `x509`

A maioria das máquinas **não precisa** instalar nenhum certificado adicional.

O fluxo recomendado do Super Dev Kit é:

1. instalar/configurar normalmente;
2. testar HTTPS e Docker;
3. somente se houver erro de confiança TLS, identificar o emissor;
4. exportar o certificado público autorizado;
5. importar esse certificado na VM.

## Quando esse problema aparece

Em redes de empresas, escolas e universidades, um firewall ou proxy pode fazer **inspeção HTTPS**.

Nesse cenário, a conexão pode ser reemitida por uma autoridade certificadora interna. O Windows corporativo pode já confiar nessa CA, enquanto uma VM Ubuntu recém-instalada não.

Os sintomas mais comuns são:

```text
x509: certificate signed by unknown authority
```

ou:

```text
SSL certificate problem: self-signed certificate in certificate chain
```

## 1. Testar antes de instalar qualquer CA

No Ubuntu:

```bash
curl https://registry-1.docker.io/v2/
```

ou:

```bash
docker run --rm hello-world
```

Se funcionar, não instale certificado adicional.

## 2. Descobrir o emissor apresentado pela rede

```bash
curl -vk https://registry-1.docker.io/v2/ 2>&1 | grep -i issuer
```

Exemplos de emissores que podem aparecer incluem nomes de proxy, firewall, antivírus ou da própria organização.

## 3. Exportar o certificado público no Windows

O Super Dev Kit possui um helper:

```powershell
.\certificates\export-root-ca.ps1 -Search "nome-do-emissor"
```

Ele procura nos stores confiáveis do Windows e exporta **somente a parte pública** do certificado.

Por padrão, o arquivo fica em:

```text
certificates\local\devkit-root-ca.cer
```

Essa pasta é ignorada pelo Git.

### VirtualBox com Downloads compartilhado

Se a pasta Downloads do Windows está compartilhada com a VM, exporte diretamente para ela:

```powershell
.\certificates\export-root-ca.ps1 -Search "nome-do-emissor" -OutputPath "$env:USERPROFILE\Downloads\devkit-root-ca.cer"
```

Na VM, ela pode aparecer como:

```text
/media/sf_Downloads/devkit-root-ca.cer
```

## 4. Importar no Linux

Se você sabe o caminho:

```bash
sudo bash certificates/import-ca-linux.sh /media/sf_Downloads/devkit-root-ca.cer
```

Se não sabe o caminho, o Super Dev Kit pode procurar certificados em Downloads, `/media` e `/mnt`:

```bash
sudo bash certificates/import-ca-linux.sh --auto
```

Antes de instalar, o helper mostra:

- Subject;
- Issuer;
- validade;
- fingerprint SHA-256.

E pede confirmação.

## 5. Testar novamente

```bash
curl https://registry-1.docker.io/v2/
```

Uma resposta semelhante a `UNAUTHORIZED` pode ser normal. Isso indica que a conexão TLS foi aceita e o Registry respondeu, mas exige autenticação para aquela chamada.

Depois:

```bash
docker run --rm hello-world
```

## Uso direto no bootstrap

Se o certificado já está disponível:

```bash
sudo bash linux/bootstrap-vm-ubuntu.sh --profile fullstack --ca /caminho/certificado.cer
```

Ou para procurar automaticamente:

```bash
sudo bash linux/bootstrap-vm-ubuntu.sh --profile fullstack --auto-ca
```

## Por que o certificado não fica publicado no repositório?

O Super Dev Kit contém **as ferramentas para exportar e importar a CA**, mas não deve distribuir certificados internos de uma instituição.

Mesmo um certificado público interno pode revelar nomes e detalhes de infraestrutura. Além disso, cada organização pode usar uma CA diferente.

Por isso:

```text
certificates/local/
```

existe para uso local e é ignorada pelo Git.

## O que não fazer

Evite:

- desabilitar globalmente a validação TLS;
- usar `curl -k` como solução permanente;
- marcar Docker Hub como registry inseguro;
- publicar certificados internos sem autorização;
- exportar ou copiar chaves privadas;
- instalar uma CA sem conferir Subject, Issuer e fingerprint.

`curl -k` pode ser útil pontualmente para diagnóstico, mas não é a correção do problema.
