# Proposta visual Cidig — Planta Unisinos

Tela Flutter independente para revisão visual. Paleta e composição baseadas em `figma/home.png`, `figma/trilha.png` e `figma/capa.png`.

Executar:

```sh
flutter run -d chrome --target lib/preview/plant_layout_preview.dart
```

Build:

```sh
flutter build web --release --target lib/preview/plant_layout_preview.dart --output build/layout-preview
```

Usa uma cópia estática dos dados preparados para o piloto. Não consulta a API, não altera registros nem substitui a tela atual. Chat e QR Code abrem explicações da prévia; navegação do cabeçalho, atalhos de seções e setas nas conexões demonstram a composição visual e ainda não navegam. A ilustração é vetorial, desenhada no Flutter, sem afirmar representar a planta real. As fontes ambientais específicas serão integradas após a aprovação.

Capturas de revisão foram entregues no diretório da conversa `entregas/layout_planta_unisinos`. Logs e builds não são versionados.

Validação: análise estática do projeto (sem erros; avisos e lints preexistentes no projeto), build web release e teste de layout/diálogo em 320, 390 e 1440 pixels. A edição preexistente de `living_clue_update_screen.dart` foi preservada e não integra o commit.

A implementação está na main local a pedido do usuário. O pipeline de main publica automaticamente; o push foi deixado para a decisão de publicação, sem deploy nesta etapa de revisão visual.
