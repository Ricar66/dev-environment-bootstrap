# Certificados corporativos e erro `x509`

Em redes de empresas, escolas e universidades, um firewall ou proxy pode fazer **inspeção HTTPS**.

Nesse cenário, a conexão pode ser reemitida por uma autoridade certificadora interna. O computador corporativo normalmente já confia nessa CA, mas uma VM Ubuntu recém-instalada pode não confiar.

O resultado pode ser:

```text
x509: certificate signed by unknown authority
```

ou:

```text
SSL certificate problem: self-signed certificate in certificate chain
```

## Diagnóstico

Teste:

```bash
curl https://registry-1.docker.io/v2/
```

Para descobrir o emissor apresentado pela rede:

```bash
curl -vk https://registry-1.docker.io/v2/ 2>&1 | grep -i issuer
```

## Solução correta

Obtenha o **certificado raiz autorizado** com sua organização ou exporte-o do armazenamento de certificados confiáveis do sistema, quando permitido.

Depois, na VM:

```bash
sudo cp certificado.cer /usr/local/share/ca-certificates/rede-local-ca.crt
sudo update-ca-certificates
sudo systemctl restart docker
```

Teste novamente:

```bash
curl https://registry-1.docker.io/v2/
```

Uma resposta `UNAUTHORIZED` do Registry pode ser normal: significa que a conexão TLS funcionou e o servidor respondeu.

Depois:

```bash
docker run --rm hello-world
```

## O que não fazer

Evite soluções como:

- desabilitar globalmente a validação TLS;
- usar `curl -k` permanentemente;
- marcar registries públicos como inseguros;
- publicar certificados internos no GitHub;
- copiar chaves privadas.

`curl -k` pode ser usado pontualmente para diagnóstico, mas não como correção permanente.
