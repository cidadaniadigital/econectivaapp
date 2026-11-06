# Cidadania Digital — Aplicativo USP Atopos

Aplicativo Flutter da plataforma USP Atopos para explorar pistas, conteúdos, territórios e conexões da cidadania digital.

[Acessar a plataforma](https://plataforma.atopos.spotec.app/) · [API](https://api.atopos.spotec.app/api/status)

## Funcionalidades

- Autenticação por e-mail e Google, cadastro e recuperação de senha.
- Catálogo de pistas, coleções, capas e conteúdos multimídia.
- Mapa com camadas ambientais e integração com a Geo API.
- Conexões, comentários, leituras recentes e referências salvas.
- Assistente IAraeté e recursos de voz, conforme configuração da API.

O backend é independente do aplicativo. A integração com Firebase foi removida; o login Google usa OAuth e a API própria.

## Preparação

É necessário Flutter compatível com `pubspec.yaml`, com Dart 3, e as ferramentas da plataforma escolhida. A dependência `widgets_spo` está fixada em `pubspec.lock` e exige acesso ao repositório Git configurado em `pubspec.yaml`.

```sh
git clone git@github.com:cidadaniadigital/econectivaapp.git
cd econectivaapp
flutter pub get
flutter run -d chrome
```

Por padrão, o aplicativo usa exclusivamente `https://api.atopos.spotec.app/api`. Para um backend local de desenvolvimento:

```sh
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8084/api
```

Preserve os clientes OAuth configurados no HTML, no serviço Google e no Info.plist para as distribuições autorizadas. Novos domínios e aplicativos precisam de configuração própria no Google Cloud. Não inclua segredos ou credenciais de assinatura no código.

## Validação

```sh
flutter analyze
flutter test
python3 scripts/test_web_release.py
node scripts/test-messaging-retirement.js
```

Testes de integração autenticados exigem uma conta exclusiva de teste e valores `E2E_EMAIL` e `E2E_PASSWORD` fornecidos pelo ambiente de execução. O repositório não fornece contas nem senhas padrão. Use uma API de testes para operações de escrita.

## Compilação e publicação

```sh
flutter build web --release --no-tree-shake-icons --dart-define=API_BASE_URL=https://api.atopos.spotec.app/api
python3 scripts/deploy-web-release.py --build build/web --revision "$(git rev-parse HEAD)" --prepare-only
```

O build fica em `build/web`. O script prepara entradas versionadas e aposenta workers legados sem ciclos de recarga. O envio ao servidor exige acesso operacional próprio e deve apontar somente para o ambiente Atopos. Não use o diretório de outra plataforma.

Para Android, configure localmente a assinatura de produção antes de gerar uma distribuição release. Para iOS, use macOS/Xcode e a assinatura correspondente. Builds, chaves e configurações locais não são versionados.

## Financiamento

A plataforma conta com financiamento da Fundação de Amparo à Pesquisa do Estado de São Paulo (FAPESP) e da Fundação de Amparo à Pesquisa do Estado do Rio Grande do Sul (FAPERGS).

<p>
  <img src="assets/logo_fapesp.svg" alt="FAPESP" width="260">
  &nbsp;&nbsp;
  <img src="assets/logo_fapergs.jpg" alt="FAPERGS" width="280">
</p>

As fontes das marcas constam nos arquivos `assets/logo_fapesp.source.md` e `assets/logo_fapergs.source.md`. Nomes e marcas pertencem às respectivas instituições.

## Publicação inicial

Versão `0.3.2+8`. Este repositório começa com uma cópia limpa do código versionado da USP Atopos. O histórico anterior do Bitbucket e evidências operacionais locais não integram esta publicação. Alterações de trabalho ainda não commitadas não foram incluídas.
