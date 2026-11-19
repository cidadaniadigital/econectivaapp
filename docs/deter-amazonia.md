# DETER Amazônia na plataforma USP Atopos

Adaptação da entrega Educação OnLIFE UU-106, app `3bfb9f8`, API `f4cd06c` e Geo API `538e040`. A interface USP e a integração iNaturalist são preservadas.

## Pistas

Pistas com coordenadas exibem “Alterações da vegetação no entorno” dentro do contexto ambiental, independentemente da disponibilidade do snapshot ambiental anterior. A consulta começa em 1 km e permite 500 m e 5 km. A seção apresenta quantidade, classes, período, sincronização e indicação de dados desatualizados. Distingue falha de consulta, ausência de avisos e localização fora da cobertura. Trocar raio ou coordenadas invalida respostas anteriores; a falha não impede abrir a pista ou consultar fauna.

Usa `GET /api/deter/nearby?latitude=...&longitude=...&radius_m=1000`, com Bearer normal e a base já configurada (`https://api.atopos.spotec.app/api` por padrão). O app não recebe o segredo da Geo API, não consulta diretamente o INPE e não cria pistas ou vínculos.

## Mapa

A camada `deter-amazonia` chega pelo catálogo autenticado `/api/environmental_layers`. O mapa USP já desenha essas camadas através de `/api/environmental_tiles`, com controle de opacidade, legenda e “Desativar todas”. Não é necessário criar outro mecanismo de camadas. A nova camada começa desligada para quem ainda não a ativou; a escolha do usuário é lembrada pelo mecanismo existente.

A Geo API fornece `min_zoom=10`, `max_zoom=18`, opacidade padrão 0,75, fonte INPE/TerraBrasilis e legenda dos avisos. São polígonos históricos dos últimos 365 dias na cobertura Amazônia; não correspondem à taxa anual PRODES. Fora da cobertura ou do zoom de exibição, a falta de polígonos não comprova ausência de alteração ambiental.

Assim como na referência OnLIFE, a camada é rasterizada: clicar nos polígonos não abre detalhes individuais. O resumo é consultado pelo entorno da pista. A fauna continua usando seus próprios marcadores e detalhes.

## Disponibilidade por instalação

A Geo API é compartilhada e já recebeu o conjunto DETER. A instância Go da USP é independente da instância OnLIFE, embora use o mesmo código. Antes da publicação de 19/11/2026, Atopos executava `onlife-api:fauna-a0896dc` e respondia 404 ao novo endpoint. Em 19/11/2026, a instância Atopos foi atualizada para `onlife-api:deter-f4cd06c`, imagem também validada na OnLIFE.

O procedimento de publicação utiliza a imagem já validada `onlife-api:deter-f4cd06c` na instância Atopos, mantendo seu `.env`, banco `atopos_api`, origem e armazenamento próprios. O diff `a0896dc..f4cd06c` adiciona apenas proxy DETER, testes e documentação, sem migração de banco. Não é necessário alterar ou reimportar a Geo API. A atualização Atopos preservou um backup privado e conferiu os registros existentes das 35 tabelas, sem diferenças. A instância OnLIFE não foi reiniciada. A publicação direta na main e no site foi autorizada pelo responsável nesta sessão.

## Verificação

Testes cobrem celular e desktop, carregamento, erro e nova tentativa, vazio, cobertura, sincronização pendente, troca rápida de raio, troca de coordenadas, descarte após remoção, integração com o detalhe da pista, contrato HTTP e regressões das camadas/fauna. O catálogo DETER é exercitado no mapa com tiles locais, para validar ativação, opacidade, legenda e desativação sem depender da rede.

Validação desta adaptação: 26 testes selecionados aprovados, incluindo o mapa em 390 e 1280 pixels e a seção em 320, 390 e 1280 pixels; `flutter analyze` sem erros (há avisos e sugestões no projeto); `flutter build web --release --no-tree-shake-icons --dart-define=API_BASE_URL=https://api.atopos.spotec.app/api` concluído. As consultas de dados nos testes são controladas; a validação autenticada em produção é registrada abaixo após a atualização da API.
