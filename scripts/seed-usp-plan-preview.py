"""Idempotent synthetic USP fixture. Refuses any API/database outside local preview."""
import json, re, subprocess
from pathlib import Path
from urllib.request import Request, urlopen
BASE = 'http://127.0.0.1:8082/api'
DB = 'onlife_validation_preview'
LOT = 'usp-plan-preview-v1'
credentials = json.loads(Path('/tmp/onlife-integration-preview-credentials.json').read_text())
container = json.loads(subprocess.check_output(['docker', 'inspect', 'rieonlife-validation-db']))[0]
assert container['HostConfig']['PortBindings']['3306/tcp'][0] == {'HostIp':'127.0.0.1','HostPort':'33419'}
token = None
def api(method, path, data=None):
    headers = {'Content-Type':'application/json'}
    if token: headers['Authorization'] = 'Bearer ' + token
    body = json.dumps(data).encode() if data is not None else None
    with urlopen(Request(BASE + path, body, headers, method=method), timeout=45) as response:
        raw = response.read()
        return json.loads(raw) if raw else None
login = api('POST', '/login', {'email':credentials['email'], 'password':credentials['password'], 'device_name':'usp-plan-local'})
token = login.get('token') or login.get('plain_text_token')
assert token
api('PUT','/me/preferences',{'usage_mode':'inventor'})
def reference(endpoint, name, data):
    rows = api('GET', '/' + endpoint) or []
    matches = [row for row in rows if row['name'] == name]
    assert len(matches) <= 1, 'Duplicate fixture reference'
    return matches[0] if matches else api('POST','/' + endpoint, {'name':name, **data})
def category(name):
    return reference('categories', name, {'type':'Pista Online','color_hex':'#43D4C2','metadata_tags':'observacao','description':'Categoria sintética USP.'})
ids = {}
for key, name, cat, description, metadata in [
 ('plant','USP piloto — planta fictícia','Planta USP validação','Espécie fictícia para demonstração. Não representa diagnóstico botânico.', {'especie':'Espécie demonstrativa fictícia'}),
 ('sensor','USP piloto — sensor virtual','Sensor USP validação','Dispositivo virtual; sem identidade física ou calibração verificada.', {'modelo':'Virtual USP','frequencia_leitura':'Amostras demonstrativas sem frequência garantida'}),
 ('environment','USP piloto — ambiente fictício','Ambiente USP validação','Ambiente de solo e ar da demonstração.', {}),
 ('researcher','USP piloto — pesquisador fictício','Pesquisador USP validação','Pessoa inteiramente fictícia, sem atribuição de autoria científica real.', {'referencia':'Demonstração sintética'}),
 ('text','USP conteúdo — texto fictício','Texto USP validação','Texto demonstrativo sobre relações socioambientais. https://example.org/texto-demonstrativo', {'formato_conteudo':'texto'}),
 ('video','USP conteúdo — vídeo fictício','Vídeo USP validação','Referência demonstrativa de vídeo, sem alegação de transcrição. https://example.org/video-demonstrativo', {'formato_conteudo':'vídeo'}),
 ('audio','USP conteúdo — áudio fictício','Áudio USP validação','Referência demonstrativa de podcast. https://example.org/audio-demonstrativo', {'formato_conteudo':'áudio'}),
 ('pending','USP estado — análise pendente','Ambiente USP validação','Estado sintético de análise pendente.',{}),
 ('partial','USP estado — indicadores parciais','Ambiente USP validação','Estado sintético com zero válido e indicadores ausentes.',{}),
 ('stale','USP estado — localização alterada','Ambiente USP validação','Snapshot de outra localização, não deve ser exibido como atual.',{}),
 ('failed','USP estado — análise falhou','Ambiente USP validação','Estado sintético de indisponibilidade.',{}),
 ('collection','USP coleção — piloto fictício','Coleção temática','Coleção de pesquisa inteiramente fictícia para validação.', {'destaque_catalogo':True}),
]:
    cat_id = category(cat)['id']
    data = {'category_id':cat_id,'description':description,'is_active':True,
            'metadata':{'dados_ficticios':True,'lote':LOT, **metadata}}
    if key in {'plant','environment','pending','partial','stale','failed'}:
        data.update(latitude=-29.794,longitude=-51.153)
    clue = reference('living_clues', name, data)
    assert clue.get('metadata',{}).get('lote') == LOT, 'Refusing unrelated existing clue'
    ids[key] = clue['id']
for source, target, name in [('researcher','plant','Pesquisador observa planta'),('sensor','environment','Sensor mede solo do ambiente'),('plant','environment','Planta situada no ambiente'),('plant','sensor','Recebe leituras declaradas de')]:
    kind = reference('connection_types', name, {'is_directional':True,'stroke_style':'solid'})
    links = api('GET',f"/living_clues/{ids[source]}/connections") or []
    if not any(row['source_clue_id']==ids[source] and row['target_clue_id']==ids[target] and row['connection_type_id']==kind['id'] for row in links):
        api('POST','/clue_connections',{'source_clue_id':ids[source],'target_clue_id':ids[target], 'connection_type_id':kind['id'], 'strength':1,'evidence':'Relação dirigida do piloto fictício USP'})
kind = reference('connection_types','Coleção contém item',{'is_directional':True,'stroke_style':'solid'})
for key in ['plant','text','video','audio']:
    links = api('GET',f"/living_clues/{ids['collection']}/connections") or []
    if not any(row['source_clue_id']==ids['collection'] and row['target_clue_id']==ids[key] and row['connection_type_id']==kind['id'] for row in links):
        api('POST','/clue_connections',{'source_clue_id':ids['collection'],'target_clue_id':ids[key], 'connection_type_id':kind['id'],'strength':1})
collection = api('GET',f"/living_clues/{ids['collection']}")
collection['metadata']['colecao_ordem_itens_v1'] = [ids[k] for k in ['plant','text','video','audio']]
api('PUT',f"/living_clues/{ids['collection']}",collection)
def sql(statement):
    subprocess.run(['docker','exec','rieonlife-validation-db','sh','-c',
      'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" mariadb -uroot onlife_validation_preview -e "$1"',
      'usp-plan-fixture',statement],check=True,capture_output=True)
sources = {k:{'dataset':'Fonte sintética de '+k,'version':'fixture-v1','layer_id':'usp-fixture-'+k} for k in ['biome','land_cover','hydrography','altitude','slope','population']}
sources['land_cover']['radius_m']=250
source_sql = "CONVERT(0x" + json.dumps(sources).encode().hex() + " USING utf8mb4)"
for key in ['plant','pending','partial','stale','failed']:
    status = {'pending':'pending','failed':'failed'}.get(key,'completed')
    lat = -28 if key=='stale' else -29.794
    partial = key=='partial'
    sql(f"""INSERT INTO environmental_contexts (living_clue_id,status,analyzed_latitude,analyzed_longitude,biome,land_cover,vegetation_percent,water_distance_m,altitude_m,slope_percent,built_up_percent,population_density,sources,analyzed_at,created_at,updated_at)
      VALUES ({ids[key]},'{status}',{lat},-51.153,'Bioma fictício','Cobertura fictícia',0,{ 'NULL' if partial else 126.05 },{ 'NULL' if partial else 52.49 },{ 'NULL' if partial else 6.54 },{ 'NULL' if partial else 68.28 },{ 'NULL' if partial else 7.51 },{source_sql},'2026-09-25 15:04:56',NOW(),NOW())
      ON DUPLICATE KEY UPDATE status=VALUES(status),analyzed_latitude=VALUES(analyzed_latitude),analyzed_longitude=VALUES(analyzed_longitude),biome=VALUES(biome),land_cover=VALUES(land_cover),vegetation_percent=VALUES(vegetation_percent),water_distance_m=VALUES(water_distance_m),altitude_m=VALUES(altitude_m),slope_percent=VALUES(slope_percent),built_up_percent=VALUES(built_up_percent),population_density=VALUES(population_density),sources=VALUES(sources),analyzed_at=VALUES(analyzed_at)""")
existing = api('GET',f"/living_clues/{ids['plant']}").get('sensor_readings',[])
if not any(LOT in row.get('payload_raw','') for row in existing):
    for payload in [{'Temperatura':22.0,'Umidade':58,'UmidadeSolo':0,'unidades':{'Temperatura':'°C','Umidade':'%','UmidadeSolo':'%'},'instante_medicao':'2026-09-01T10:00:00-03:00','sensor_pista_id':ids['sensor'],'id_dispositivo':'USP-VIRTUAL','origem':'solo e ar do ambiente fictício','dados_ficticios':True,'lote':LOT}, {'Temperatura':21,'UmidadeSolo':42,'lote':LOT}]:
        api('POST',f"/living_clues/{ids['plant']}/sensor_readings",payload)

# Synthetic auxiliary records ensure every maintained edit route has valid input.
sql("INSERT INTO sample_details (sample_string,created_at,updated_at) SELECT 'USP detalhe sintético',NOW(),NOW() WHERE NOT EXISTS (SELECT 1 FROM sample_details WHERE sample_string='USP detalhe sintético')")
node_type = reference('node_types','USP problemática sintética',{'color':'#43D4C2'})
node_a = reference('nodes','USP nó sintético A',{'color':'#43D4C2','node_type_id':node_type['id']})
node_b = reference('nodes','USP nó sintético B',{'color':'#43D4C2','node_type_id':node_type['id']})
links = api('GET','/node_links') or []
if not any(row['source_node_id']==node_a['id'] and row['target_node_id']==node_b['id'] for row in links):
    api('POST','/node_links',{'source_node_id':node_a['id'],'target_node_id':node_b['id']})
reference('chat_templates','USP agente sintético',{'description':'Agente de validação fictício','system_instruction':'Responda em português, reconhecendo limites das informações disponíveis.'})

path = Path('/tmp/usp-plan-fixture-ids.json');path.touch(mode=0o600);path.chmod(0o600);path.write_text(json.dumps(ids))
print('Prepared synthetic USP fixture:', ', '.join(f'{key}={value}' for key,value in ids.items()))

# Remove only abandoned records from our earlier failed disposable test rounds.
# The guarded fixture above and all preexisting preview records are preserved.
abandoned = [row for row in api('GET','/living_clues') or [] if re.fullmatch(r'(?:Coleção USP teste|Outra coleção|Item [AB]) [0-9]{16}', row['name'])]
for row in abandoned:
    api('DELETE',f"/living_clues/{row['id']}")
print('Removed abandoned temporary test records:',len(abandoned))
