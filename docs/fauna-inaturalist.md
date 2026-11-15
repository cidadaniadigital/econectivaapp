# Fauna observada — USP Atopos

Adaptação da implementação Educação OnLIFE `60881a1` (UU-105), preservando o mapa, as pistas e o contexto ambiental da USP.

## Configuração e implantação

Usa exclusivamente a base `WebClient.apiBaseUrl`, configurável por `API_BASE_URL`, cujo padrão USP permanece `https://api.atopos.spotec.app/api`. Os dois GETs passam pelos interceptadores existentes de API e token do usuário:

- `/biodiversity/nearby`: latitude, longitude e radius_m (500, 1000 ou 5000).
- `/biodiversity/observations`: north, south, east e west da área visível.

Nenhum segredo GEOAPI é distribuído no app e nenhuma chamada de dados é feita diretamente ao iNaturalist. Fotos licenciadas e o link externo da observação usam as URLs retornadas pela API. Não há criação de pistas nem vínculos.

**Verificação em 15/11/2026:** o status da API Atopos responde 200, mas os dois endpoints de biodiversidade respondem 404. A instalação Atopos ainda utiliza a imagem `atopos-api:release-a6619e9`; a instalação OnLIFE utiliza `onlife-api:fauna-a0896dc`. Logo, endpoints publicados para OnLIFE não significam endpoints publicados na instância USP. Não alterar a base USP para OnLIFE: são instalações e sessões distintas. A disponibilização do backend já existente na instância USP é pré-requisito para validar dados reais. Nenhum backend foi alterado ou publicado nesta entrega.

## Comportamento

Pistas sem coordenadas não consultam fauna. Nas demais, a seção aparece mesmo quando o snapshot ambiental está indisponível. Inicia em 1 km e mostra no máximo 12 espécies. Troca de raio/localização invalida respostas anteriores. Carregamento, vazio, erro com nova tentativa e foto indisponível são tratados localmente.

A camada do mapa inicia desligada e integra o painel Camadas e Desativar todas. Mostra no máximo 100 marcadores verdes de pata, independentes das pistas. Só consulta com zoom >=8 e limites de até 3 graus por eixo, sem atravessar o antimeridiano. Mudanças de câmera invalidam resultados e usam debounce de 700 ms. Desativação e descarte da tela invalidam consultas pendentes. Atualizar fauna permite repetir uma consulta.

Os detalhes compartilhados entre seção e mapa mostram nomes, foto, crédito, licença, data, localização pública aproximada/obscurecida quando informada e link HTTPS para a observação. Os textos esclarecem que são registros históricos e amostrais: não garantem presença atual nem demonstram ausência de fauna.

## Validação

- Testes de widgets da seção em 390 e 1280 pixels: detalhes, autoria, licença e foto indisponível.
- Troca rápida de raio com respostas fora de ordem; falha, nova tentativa e vazio.
- Controlador: padrão desligado, zoom, área máxima, debounce, resposta antiga, desativação durante consulta, falha e limite de 100.
- Tela real do mapa USP em 390 e 1280 pixels com fonte controlada e tiles locais: ativar camada, mover mapa, abrir detalhes e Desativar todas.
- Contrato HTTP: base configurada, endpoints, parâmetros e Bearer normal; 404 tratado como indisponibilidade.
- Regressões de contexto ambiental, camadas, conexões e navegação do mapa.

Dados controlados nos testes não constituem validação de fauna real da API Atopos. A consulta autenticada com dados reais deve ser repetida após os endpoints estarem disponíveis nessa instância.
