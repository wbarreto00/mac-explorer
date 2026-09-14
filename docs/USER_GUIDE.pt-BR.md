# Guia de uso

[English](USER_GUIDE.md) · Português (Brasil) · [Español](USER_GUIDE.es.md) · [Instalação](README.pt-BR.md#instalação)

## Navegar e organizar

Expanda as setas na barra lateral para navegar pelas pastas. Clique em uma pasta para listar seu conteúdo. Dê dois cliques em uma pasta na área de arquivos para entrar nela, ou em um arquivo para abri-lo no aplicativo associado. O caminho clicável leva às pastas superiores; ⌘L aceita um caminho absoluto ou começando por `~`.

A estrela ao lado de Navegação adiciona ou remove a pasta atual dos favoritos. Discos e compartilhamentos de rede aparecem depois de montados pelo macOS. O app não conecta diretamente a servidores ainda não montados.

Em **Organizar**, escolha a ordenação e o agrupamento separadamente. Por exemplo, agrupe por Tipo e ordene por Modificado para ver os arquivos recentes dentro de cada tipo. A ordem dos grupos é independente da ordenação dos itens. Pastas primeiro é opcional. Em Detalhes, dê dois cliques no título do grupo para recolher; nos ícones, clique no título.

**Exibir** muda o modo de visualização e as colunas. Arraste a borda da coluna para redimensionar e seu título para reordenar. Cada pasta lembra sua organização. **Usar esta organização como padrão** vale para pastas sem configuração própria. Ative arquivos ocultos e extensões quando necessário.

## Seleção, busca e prévia

Use ⌘-clique para itens separados, Shift-clique para um intervalo e ⌘A para todos os itens visíveis. A busca filtra nomes na pasta atual; ative a opção de subpastas para procurar recursivamente. Há limite de 10.000 resultados; itens ilegíveis e limites aparecem no status. Atualize com ⌘R após mudanças nas subpastas.

O painel de propriedades mostra seleção, datas, etiquetas e prévias do Quick Look. Os formatos aceitos dependem do macOS e dos provedores instalados. O tamanho de pastas não é calculado recursivamente. A leitura de etiquetas pode aguardar o provedor de arquivos; a listagem comum só as solicita quando necessárias.

## Operações

Barra de ferramentas, menus e menus de contexto oferecem Nova pasta, Renomear, Copiar, Recortar, Colar, Copiar para, Mover para, Etiquetas e Lixeira. Arrastar e soltar copia. Separe etiquetas por vírgulas; um valor vazio remove as etiquetas. Na seleção múltipla, as etiquetas digitadas substituem as etiquetas de todos os itens selecionados.

Cópias e movimentações preservam conflitos acrescentando um número ao nome. Renomear para um nome ocupado é recusado. Não há mesclagem automática de pastas. A exclusão usa a Lixeira do macOS.

**Desfazer movimentação** restaura a última movimentação, renomeação ou envio à Lixeira enquanto o app estiver aberto, recusando substituir itens existentes no caminho original. É um registro de uma operação, não um histórico completo. Cópias, criação de pastas e etiquetas não têm desfazer. Mantenha suas cópias de segurança habituais.

## Atalhos

| Ação | Atalho |
|---|---|
| Nova janela / nova aba | ⌘N / ⌘T |
| Fechar aba / próxima aba | ⌘⇧W / Control+Tab |
| Nova pasta / buscar | ⌘⇧N / ⌘F |
| Ir para a pasta | ⌘L |
| Voltar / avançar / subir | ⌘← / ⌘→ / ⌘↑ |
| Abrir seleção | ⌘↓ ou Enter |
| Copiar / recortar / colar | ⌘C / ⌘X / ⌘V |
| Selecionar tudo | ⌘A |
| Renomear em Detalhes/Lista | F2 ou fn+F2 |
| Propriedades e prévia | Espaço ou ⌘⌥I |
| Atualizar / arquivos ocultos | ⌘R / ⌘⇧. |
| Mover para a Lixeira | ⌘⌫ |
| Desfazer movimentação | ⌘⌥Z |
| Ajustes de idioma | ⌘, |

## Problemas comuns

- **App bloqueado:** consulte a assinatura e as instruções da Apple em [Instalação](README.pt-BR.md#instalação).
- **Pasta não pode ser lida:** confira a existência da pasta, a conexão do disco e as permissões de Arquivos e Pastas do macOS. Atualize após reconectar o volume.
- **Idioma não mudou:** encerre completamente e reabra o app. A escolha fica em Mac Explorer → Ajustes; os formatos regionais são independentes.
- **Busca desatualizada:** pressione ⌘R. Observar a pasta aberta não monitora todas as subpastas.
- **Recurso ausente:** confira o escopo no [README](README.pt-BR.md). Ao relatar um problema, inclua versões do app e do macOS e passos para reproduzir, sem conteúdos pessoais.
