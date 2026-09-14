# Mac Explorer

**Gerenciador de arquivos nativo para Apple Silicon, com organização de pastas inspirada no Windows Explorer.**

[English](../README.md) · Português (Brasil) · [Español](README.es.md)

Árvore de pastas, abas, ordenação e agrupamento independentes, com organização salva por pasta. Feito com SwiftUI e AppKit, sem dependências externas, conta, anúncios ou análises de uso.

**[Baixar o Mac Explorer](https://github.com/wbarreto00/mac-explorer/releases/latest)** · [Guia de uso](USER_GUIDE.pt-BR.md) · [Relatar um problema](https://github.com/wbarreto00/mac-explorer/issues)

## Instalação

1. Use um Mac com **Apple Silicon (M1 ou posterior)**. Intel e Rosetta não são compatíveis. O alvo mínimo é **macOS 14**; esta versão foi testada somente no macOS 26.6.2.
2. Baixe **Mac-Explorer-Apple-Silicon.zip** na [versão mais recente](https://github.com/wbarreto00/mac-explorer/releases/latest). Os arquivos “Source code” são para desenvolvedores.
3. Abra o ZIP e arraste **Mac Explorer.app** para **Aplicativos**.
4. Abra o app e conceda acesso às pastas que deseja utilizar quando o macOS solicitar.

**Assinatura:** a versão usa assinatura local, sem Apple Developer ID ou notarização. O macOS pode bloquear a cópia baixada. Se você confiar nesta versão, tente abrir uma vez e acesse **Ajustes do Sistema → Privacidade e Segurança → Abrir Mesmo Assim**, conforme o [guia da Apple](https://support.apple.com/pt-br/guide/mac-help/mh40616/mac). Também é possível compilar o código. É uma primeira versão pública; outros Macs e versões do macOS ainda não foram verificados.

Para conferir a integridade, baixe `SHA256SUMS.txt` na mesma pasta do ZIP e execute `shasum -a 256 -c SHA256SUMS.txt`. Para atualizar, encerre o app e substitua a cópia em Aplicativos. Favoritos e organização são preservados. Para desinstalar, mova o app para a Lixeira; ele não instala serviços nem itens de início.

## Idioma

O padrão é **inglês**. Acesse **Mac Explorer → Settings…** (⌘,), escolha **Português (Brasil)** e encerre e reabra o app. Depois, esse menu aparecerá como **Ajustes…**. Também há inglês, espanhol e **Seguir o idioma do macOS**. Essa última opção usa um idioma compatível das preferências do sistema, com inglês como alternativa. Variantes de português usam a tradução brasileira. Nomes de arquivos permanecem iguais; datas e tamanhos seguem os formatos regionais do Mac.

## Recursos

- Árvore expansível, favoritos, abas, janelas, voltar, avançar, subir e caminho editável.
- Detalhes, lista, quatro tamanhos de ícones, blocos, conteúdo, propriedades e prévia nativa.
- Ordenação por nome, tipo, tamanho, extensão, etiquetas e datas de modificação, criação e adição; ordem crescente ou decrescente e pastas primeiro.
- Agrupamento independente por nome, tipo, tamanho, extensão, etiquetas, modificação ou criação.
- Colunas selecionáveis, redimensionáveis e reordenáveis; organização por pasta ou padrão.
- Criar pasta, renomear, copiar, recortar, colar, copiar/mover para, etiquetas, Lixeira e desfazer a última movimentação.
- Busca por nome na pasta ou nas subpastas, limitada a 10.000 resultados.
- Discos locais, removíveis e compartilhamentos de rede já montados no macOS.

Arrastar e soltar **copia**. Para mover, use Recortar/Colar ou Mover para. Conflitos de cópia ou movimentação preservam os dois itens com um número no nome. Não há substituição automática nem mesclagem de pastas. O comando de desfazer restaura a última movimentação, renomeação ou envio à Lixeira na sessão, recusando conflitos no destino original. Cópias, novas pastas e etiquetas não têm desfazer. A busca não lê o conteúdo dos documentos.

O app funciona com arquivos locais e volumes montados, sem telemetria própria, conta ou atualização automática. Pastas em nuvem e de rede continuam usando seus respectivos provedores. Não substitui o Finder. Não inclui dois painéis, extração de arquivos, renomeação em lote, conexão direta a SMB nem histórico completo. Atualize buscas recursivas com ⌘R após alterações nas subpastas. Veja os atalhos e detalhes no [guia](USER_GUIDE.pt-BR.md).

## Compilar

Em um Mac Apple Silicon, use macOS 14+ e Xcode ou Command Line Tools com Swift 5.9+. A ferramenta verificada é Swift 6.4 com SDK macOS 26. Se necessário, execute `xcode-select --install` e conclua o instalador da Apple.

```sh
git clone https://github.com/wbarreto00/mac-explorer.git
cd mac-explorer
./script/test.sh
./script/build_and_run.sh
```

O script gera o app otimizado e o ZIP em `outputs/`, assina localmente e abre o app. `--build-only` compila sem abrir. Os testes não exigem XCTest nem Xcode completo. Consulte as [notas de desenvolvimento em inglês](DEVELOPMENT.md).

Contribuições e relatos em português são bem-vindos. Consulte [CONTRIBUTING.md](../CONTRIBUTING.md), [SECURITY.md](../SECURITY.md) e o [histórico](../CHANGELOG.md). Licença [MIT](../LICENSE). Projeto independente de [wbarreto00](https://github.com/wbarreto00), sem vínculo com Apple ou Microsoft.
