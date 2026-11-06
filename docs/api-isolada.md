# API exclusiva Atopos

A Atopos usa `https://api.atopos.spotec.app/api`. Educação OnLIFE permanece em `https://api.uniusp.gpedu.com.br/api`. As duas instâncias usam o mesmo código de API, mas bancos, credenciais e arquivos separados.

O build e o pipeline fixam `API_BASE_URL` no domínio da Atopos. Prévia local pode sobrescrever com `--dart-define=API_BASE_URL=http://localhost:8084/api`.

Os usuários existentes foram copiados. A sessão anterior precisa ser renovada com um novo login; as credenciais cadastradas permanecem válidas. Alterações futuras de pistas, contas, chats, agentes e arquivos pertencem somente à plataforma em que forem realizadas.

A Geo API continua compartilhada, via proxy autenticado de cada API. Não embutir seu token no front. Os QR Codes e links compartilhados da Atopos continuam no domínio `plataforma.atopos.spotec.app`.
