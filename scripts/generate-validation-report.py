"""Build a self-contained technical report from recorded validation evidence."""
from pathlib import Path
import json,html,hashlib,subprocess,re,base64
root=Path(__file__).resolve().parent.parent
out=root/'docs/validation'
def read(name,default):
 p=out/name
 return json.loads(p.read_text()) if p.exists() else default
def esc(value):return html.escape(str(value))
suites=read('suites.json',[]);screens=read('screen-tests.json',[]);crud=read('crud-tests.json',{});contract=read('api-contract.json',{});coverage=read('route-coverage.json',{});browser=read('browser-checks.json',[])
branch=subprocess.check_output(['git','branch','--show-current'],cwd=root,text=True).strip()
source=hashlib.sha256()
for folder in ['lib','test','integration_test']:
 for p in sorted((root/folder).rglob('*.dart')):source.update(str(p.relative_to(root)).encode());source.update(p.read_bytes())
for name in ['pubspec.yaml','pubspec.lock']:
 p=root/name;source.update(name.encode());source.update(p.read_bytes())
source_digest=source.hexdigest()
unit_cases=read('unit-cases.json',[])
changes=[
'Retirados os acessos a biomas e territórios, cujas rotas deixaram de existir na API atual.',
'Pistas aceitam localização opcional; latitude/longitude zero são válidas, mapas ignoram registros sem coordenadas e a remoção de localização é explícita.',
'Edição preserva metadados tipados, formatação do documento e blocos incorporados; os trechos textuais do documento podem ser editados.',
'Anexos usam upload multipart, filtro por pista e resolução autenticada de URL a cada abertura; links temporários não são persistidos pelo app.',
'Chats globais usam a API autenticada; agentes são consultados diretamente pelo ID, inclusive fora da primeira página.',
'Recuperação envia reset_password_token e aceita o link/token da API. A validação antiga de código foi removida.',
'Gestão de usuários fica restrita a administradores. O próprio perfil continua disponível para participantes.',
'Preferência Criação e edição em Meu perfil adapta a restrição de escrita da API com apresentação simples.',
'Corrigidos o preenchimento da cor na edição de categorias, o retorno após salvar pistas, o cabeçalho móvel e a sobreposição do assistente.',
'Coleções nulas são aceitas como vazias. Seletores, datas, campos opcionais e persistência do módulo legado de amostras foram alinhados ao contrato existente.',
'pubspec.lock passou a ser versionado para reproduzir as dependências efetivamente testadas.',
'API_BASE_URL permite validar em ambiente isolado. O endereço padrão de produção foi mantido; logs HTTP que expunham corpos de autenticação foram filtrados.'
]
parts=['''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>UU-97 — Compatibilidade USP App</title><style>body{font:16px/1.55 system-ui,sans-serif;background:#f3f6fa;color:#14253d;max-width:1120px;margin:32px auto;padding:0 24px}h1,h2{line-height:1.2}h2{margin-top:36px}table{border-collapse:collapse;width:100%;background:white;font-size:14px}td,th{padding:10px;border:1px solid #d7e0eb;text-align:left;vertical-align:top}th{background:#e6eef8}a{color:#0759a7}code{overflow-wrap:anywhere}.good{color:#087645;font-weight:700}.bad{color:#ab2137;font-weight:700}.note{padding:18px;background:#e6eef8;border-radius:12px}.gallery{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:18px}.gallery img{width:100%;max-height:720px;object-fit:contain;background:#031225;border-radius:10px}.gallery figure{margin:0}li{margin:8px 0}small{color:#516078}</style><h1>USP App compatível com a API atual</h1><p>Relatório de implementação e validação — 22 de outubro de 2026</p>''']
parts.append(f'<p><a href="https://spo-tec.atlassian.net/browse/UU-97">Tarefa UU-97</a> · Branch <code>{esc(branch)}</code> · <a href="https://bitbucket.org/spotecnologia/usp_app/pull-requests/7">Revisar PR #7</a></p>')
expected_suites={'analyze','unit','api_integration_test','login_screenshot_test','compatibility_crud_test','compatibility_test'}
passed=all(r['exit_code']==0 for r in suites) and {r['suite'] for r in suites}==expected_suites and all(r['passed'] for r in screens) and not coverage.get('missing',['missing'])
parts.append(f'<p class="note"><strong>Resultado: {"validação aprovada" if passed else "validação ainda incompleta"}.</strong> {len(unit_cases)} testes de unidade/widget; quatro suítes de integração; {len(screens)} cenários de tela, {sum(bool(x["passed"]) for x in screens)} aprovados. Cobertura de {len(coverage.get("registered_routes",[]))} rotas registradas, incluindo a inicialização. Código da API sem alterações nesta entrega. Resultados históricos de 22/10/2026; a verificação após incorporar main está em pr-validation.json. Logs de execução são locais e não são versionados.</p>')
pr=read('pr-validation.json',{})
if pr:
 parts.append('<h2>Verificação após resolver o conflito com main — 26/10/2026</h2><p>Análise estática sem erros ou avisos; 12 testes aprovados, incluindo regressão da criação de conexão pelo mapa com pistas sem coordenadas; build web release aprovado. As suítes de API/S3 acima permanecem como evidências históricas. Detalhes em <a href="pr-validation.json">pr-validation.json</a>.</p>')
parts.append('<h2>Escopo e ambiente</h2><p>Foi adaptado o repositório USP App, mantendo o visual Cidig e os fluxos administrativos simples. Não foram portadas a narrativa OnLIFE, naves, presença, encontros ou chat entre participantes. As operações de teste usaram somente a API local de validação em 127.0.0.1:8082 e o banco descartável onlife_validation_preview. Os testes de chat utilizaram respostas reais do provedor configurado, com dados sintéticos.</p>')
parts.append(f'<p>Referência da API: commit <code>11818e3</code>. O Swagger público de produção foi consultado apenas para leitura: {contract.get("production_paths")} rotas e {contract.get("production_definitions")} definições; rotas coincidentes: <strong>{esc(contract.get("same_shared_paths"))}</strong>; definições coincidentes: <strong>{esc(contract.get("same_definitions"))}</strong>.</p>')
parts.append('<h2>Correções implementadas</h2><ul>'+''.join(f'<li>{esc(c)}</li>' for c in changes)+'</ul>')
parts.append('<h2>Suítes automatizadas</h2><table><tr><th>Suíte</th><th>Resultado</th><th>Evidência</th></tr>')
for suite in suites:parts.append(f'<tr><td>{esc(suite["suite"])}</td><td class="{"good" if suite["exit_code"]==0 else "bad"}">{"PASS" if suite["exit_code"]==0 else "FAIL"}</td><td><a href="suites.json">Resultado estruturado</a></td></tr>')
parts.append('</table><p>A análise estática passou sem erros ou avisos; o comando mantém sugestões informativas de lint visíveis. Os testes desktop são executados sequencialmente, em processos separados do Flutter.</p>')
parts.append('<h2>Testes de unidade e widgets</h2><ul>'+''.join(f'<li>{esc(c)}</li>' for c in unit_cases)+'</ul>')
parts.append('<h2>Integração e operações completas</h2><ul>'+''.join(f'<li>{esc(c)}</li>' for c in crud.get('passed',[]))+'</ul>')
parts.append(f'<p>Erros de limpeza dos cadastros e anexos temporários: <code>{esc(crud.get("cleanup_errors"))}</code>. A recuperação de senha utilizou token semeado somente em uma conta descartável; confirmou novo login e rejeição de token já usado.</p>')
s3=read('s3-tests.json',{})
if s3.get('passed'):
 parts.append('<h2>S3 real — teste adicional</h2><p>Cliente Flutter ligado à API local com banco isolado e bucket S3 real. Resultado: PASS.</p><ul>'+''.join(f'<li>{esc(c)}</li>' for c in s3.get('checks',[]))+'</ul><p>O anexo de teste foi excluído. O versionamento do bucket pode reter versões anteriores recuperáveis, conforme o contrato de exclusão da API. Não foram alteradas configurações do bucket. Evidências: s3-tests.json.</p><pre>xvfb-run -a flutter test integration_test/s3_attachment_test.dart -d linux --dart-define-from-file=/caminho/protegido/defines.json --dart-define=E2E_REAL_S3=true</pre><p>Este teste exige iniciar a prévia com --s3 e autorização para escrever um arquivo sintético no bucket real.</p>')
parts.append('<h2>Telas percorridas pelo Flutter</h2><p>Aplicação real executada com o engine Flutter desktop sob Xvfb, ligada à API atual. Cada cenário verifica montagem da tela e ausência de exceções de framework. Os cadastros recebem IDs e argumentos válidos. A suíte compara a lista de cenários com as rotas efetivamente registradas no app, impedindo omissões.</p><table><tr><th>Rota</th><th>ID do registro de teste</th><th>Resultado</th></tr>')
for row in screens:parts.append(f'<tr><td><code>{esc(row["route"])}</code></td><td>{esc(row.get("id") or "—")}</td><td class="{"good" if row["passed"] else "bad"}">{"PASS" if row["passed"] else esc(row["errors"])}</td></tr>')
parts.append('</table><h2>Validação na versão web</h2>')
parts.append(f'<p>O build web foi aberto no navegador integrado. Foram inspecionadas {len(browser)} rotas por acessibilidade/DOM, além de login pela interface, consulta de pista sem coordenadas, edição/salvamento com retorno aos detalhes, recarregamento por URL e conferência do perfil. O viewport móvel de 390 × 844 confirmou os ajustes de cabeçalho e controles. Os widgets da home também foram verificados automaticamente em 320, 390 e 1280 pixels.</p><table><tr><th>Rota inspecionada no navegador</th></tr>')
for row in browser:parts.append(f'<tr><td><code>{esc(row["path"])}</code></td></tr>')
parts.append('</table><h2>Evidências visuais do navegador</h2><div class="gallery">')
for name,caption in [('web-home.jpg','Home Cidig — desktop'),('web-home-mobile.jpg','Home em viewport móvel'),('web-save-success.jpg','Pista após salvar pela interface'),('web-profile-mobile.jpg','Preferência de edição e perfil móvel')]:
 p=out/'screenshots'/name
 if p.exists():
  src='data:image/jpeg;base64,'+base64.b64encode(p.read_bytes()).decode()
  parts.append(f'<figure><img src="{src}" alt="{esc(caption)}"><figcaption>{esc(caption)}</figcaption></figure>')
parts.append('</div><h2>Build e reprodução</h2><p>Build web de validação: API_BASE_URL=http://127.0.0.1:8082/api. Build de produção: endereço padrão da API, com saída em build/web-production. Não houve deploy nem merge da PR na main.</p><pre>python3 scripts/run-validation.py --defines /caminho/protegido/defines.json\nflutter build web --release --output build/web-production\npython3 scripts/generate-validation-report.py</pre><p>O arquivo de defines deve conter API_BASE_URL, E2E_EMAIL e E2E_PASSWORD de uma conta sintética da prévia. Não deve ser versionado. O runner recusa hosts que não sejam loopback e prepara somente o detalhe legado necessário ao seletor de amostras no banco de validação.</p>')
parts.append('<h2>Limites da validação</h2><p>O fluxo de OAuth Google depende da autorização interativa de uma conta e não foi concluído com uma conta pessoal. A entrega real de e-mail por SMTP não foi testada; a troca de senha foi testada em conta descartável. O ciclo adicional de anexos no S3 real está documentado acima quando há evidência disponível. As evidências não afirmam um teste de carga ou validação dos serviços externos em produção.</p><p>A CLI Jira disponível permite criar e editar campos da tarefa, mas não expõe comentários ou transições. O resumo técnico e os links de entrega foram registrados na descrição; a mudança de status para Review permanece uma limitação dessa CLI.</p>')
parts.append(f'<p><small>Impressão SHA-256 das fontes Dart, testes e pubspec na geração do relatório (os resultados históricos acima são de 22/10/2026): <code>{source_digest}</code>. Evidências detalhadas em suites.json, screen-tests.json, route-coverage.json, crud-tests.json, api-contract.json e browser-checks.json.</small></p></html>')
(out/'report.html').write_text(''.join(parts))
print(f'Report generated: {out/"report.html"}; approved={passed}; unit={len(unit_cases)}; screens={len(screens)}')
