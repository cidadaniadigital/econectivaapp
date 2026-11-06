import 'package:flutter/material.dart';

const _bg = Color(0xFF090F20);
const _card = Color(0xFF141E32);
const _muted = Color(0xFFA1AEC4);
const _teal = Color(0xFF43D4C2);

void main() => runApp(const PlantLayoutPreview());

/// Standalone visual proposal. All readings are synthetic; no API is called.
class PlantLayoutPreview extends StatelessWidget {
  const PlantLayoutPreview({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cidig • Planta Unisinos',
        theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: _bg,
            colorScheme: const ColorScheme.dark(primary: _teal, surface: _card),
            fontFamily: 'Roboto',
            useMaterial3: true),
        home: const _PlantPage(),
      );
}

class _PlantPage extends StatelessWidget {
  const _PlantPage();
  void _preview(BuildContext context, String title, String text) =>
      showDialog<void>(
          context: context,
          builder: (context) =>
              AlertDialog(title: Text(title), content: Text(text), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Entendi'))
              ]));
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: LayoutBuilder(builder: (context, bounds) {
        final mobile = bounds.maxWidth < 760;
        return SingleChildScrollView(
            child: Column(children: [
          Container(
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF243047)))),
              padding: EdgeInsets.symmetric(
                  horizontal: mobile ? 20 : 48, vertical: 20),
              child: Row(children: [
                const Text('cidig.',
                    style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1.7)),
                const SizedBox(width: 14),
                const Flexible(
                    child: Text('ATOPOS / USP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10, letterSpacing: 1.4, color: _muted))),
                const Spacer(),
                if (!mobile) ...[
                  const Text('Explorar', style: TextStyle(color: _muted)),
                  const SizedBox(width: 28),
                  const Text('Pistas vivas',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 28),
                  const Text('Conexões', style: TextStyle(color: _muted)),
                  const SizedBox(width: 36)
                ],
                const CircleAvatar(
                    radius: 17,
                    backgroundColor: Color(0xFF253B49),
                    child: Icon(Icons.person_outline, size: 19, color: _teal))
              ])),
          Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1232),
                  child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          mobile ? 20 : 48, 28, mobile ? 20 : 48, 40),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                'EXPLORAR   /   PISTAS VIVAS   /   PLANTA UNISINOS',
                                style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.3,
                                    color: _muted)),
                            const SizedBox(height: 24),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF29251F),
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.science_outlined,
                                          size: 17, color: Color(0xFFF7B977)),
                                      SizedBox(width: 10),
                                      Expanded(
                                          child: Text(
                                              'Piloto de demonstração • Metadados e leituras fictícios. O contexto ambiental é do cadastro existente.',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFFEAC69C),
                                                  height: 1.5)))
                                    ])),
                            const SizedBox(height: 28),
                            Flex(
                                direction:
                                    mobile ? Axis.vertical : Axis.horizontal,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!mobile)
                                    Expanded(
                                        flex: 6, child: _intro(context, mobile))
                                  else
                                    _intro(context, mobile),
                                  SizedBox(
                                      width: mobile ? 0 : 40,
                                      height: mobile ? 24 : 0),
                                  if (!mobile)
                                    const Expanded(flex: 5, child: _PlantArt())
                                  else
                                    const _PlantArt(),
                                ]),
                            const SizedBox(height: 32),
                            Wrap(spacing: 22, runSpacing: 12, children: const [
                              _SectionLabel('Visão geral', active: true),
                              _SectionLabel('Leituras'),
                              _SectionLabel('Conexões'),
                              _SectionLabel('Fontes')
                            ]),
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFF263247), height: 1),
                            const SizedBox(height: 28),
                            Flex(
                                direction:
                                    mobile ? Axis.vertical : Axis.horizontal,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!mobile)
                                    Expanded(
                                        flex: 7, child: _mainColumn(context))
                                  else
                                    _mainColumn(context),
                                  SizedBox(
                                      width: mobile ? 0 : 24,
                                      height: mobile ? 24 : 0),
                                  if (!mobile)
                                    Expanded(
                                        flex: 4, child: _sideColumn(context))
                                  else
                                    _sideColumn(context),
                                ]),
                            const SizedBox(height: 38),
                            const Divider(color: Color(0xFF263247)),
                            const SizedBox(height: 16),
                            const Text('cidig.   ATOPOS / USP',
                                style: TextStyle(color: _muted, fontSize: 13)),
                            const SizedBox(height: 8),
                            const Text(
                                'Conectar pessoas, territórios e biodiversidades.',
                                style: TextStyle(color: _muted, fontSize: 11)),
                            const SizedBox(height: 12),
                            const Text(
                                'Proposta visual para revisão • As ações desta prévia não alteram dados.',
                                style: TextStyle(color: _muted, fontSize: 10)),
                          ]))))
        ]));
      }));

  Widget _intro(BuildContext context, bool mobile) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Pill('PISTA VIVA  /  PLANTA'),
        const SizedBox(height: 16),
        Text('Planta Unisinos',
            style: TextStyle(
                fontSize: mobile ? 36 : 46,
                height: 1.1,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.5)),
        const SizedBox(height: 10),
        const Text('Uma planta. Muitas conexões.',
            style: TextStyle(fontSize: 19, color: _muted)),
        const SizedBox(height: 18),
        const Text(
            'Um convite para explorar as relações entre uma planta, seu ambiente e os dados que nos ajudam a conhecer esse pequeno ecossistema.',
            style: TextStyle(fontSize: 14, height: 1.7, color: _muted)),
        const SizedBox(height: 18),
        const Row(children: [
          Icon(Icons.place_outlined, color: _teal, size: 17),
          SizedBox(width: 7),
          Expanded(
              child: Text('Unisinos · Centro redondo',
                  style: TextStyle(fontSize: 12, color: _muted)))
        ]),
        const SizedBox(height: 23),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilledButton.icon(
              onPressed: () => _preview(context, 'Conversa com a pista',
                  'Prévia visual. A integração do chat contextual será preservada na implementação da tela aprovada.'),
              icon: const Icon(Icons.chat_bubble_outline, size: 17),
              label: const Text('Conversar com a pista'),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF653E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 19, vertical: 18))),
          OutlinedButton.icon(
              onPressed: () => _preview(context, 'QR Code da pista',
                  'Link previsto:\nhttps://plataforma.atopos.spotec.app/#/living_clues/show?id=8\n\nA geração do código e o retorno após login fazem parte da próxima implementação.'),
              icon: const Icon(Icons.qr_code, size: 18),
              label: const Text('QR Code'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 18))),
        ]),
      ]);

  Widget _mainColumn(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Panel(
            title: 'Conheça esta pista',
            eyebrow: 'IDENTIDADE',
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Manjericão',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              const Text('Ocimum basilicum · Identificação fictícia',
                  style: TextStyle(
                      color: _teal, fontStyle: FontStyle.italic, fontSize: 12)),
              const SizedBox(height: 17),
              const Text(
                  'Neste cenário didático, um manjericão em vaso se conecta a um sensor virtual, a um canteiro e a um pesquisador fictício. Acompanhe as medições e descubra o que elas podem — e o que não podem — nos dizer.',
                  style: TextStyle(height: 1.7, fontSize: 13, color: _muted)),
              const SizedBox(height: 18),
              Wrap(spacing: 8, runSpacing: 8, children: const [
                _Pill('Biodiversidade'),
                _Pill('Sensores'),
                _Pill('Demonstração')
              ]),
            ])),
        const SizedBox(height: 22),
        _Panel(
            title: 'O que os sensores registram',
            eyebrow: 'LEITURAS SIMULADAS',
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LayoutBuilder(
                  builder: (context, size) =>
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        for (final entry in [
                          (
                            Icons.thermostat_outlined,
                            'Temperatura do ar',
                            '24,7',
                            '°C'
                          ),
                          (
                            Icons.water_drop_outlined,
                            'Umidade do ar',
                            '60',
                            '%UR'
                          ),
                          (Icons.grass, 'Umidade do solo', '48', '% relativo')
                        ])
                          SizedBox(
                              width: (size.maxWidth - 20) / 3,
                              child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: _bg.withValues(alpha: .65),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(entry.$1, size: 20, color: _teal),
                                        const SizedBox(height: 12),
                                        Text(entry.$2,
                                            style: const TextStyle(
                                                color: _muted, fontSize: 10)),
                                        const SizedBox(height: 8),
                                        Text(entry.$3,
                                            style: const TextStyle(
                                                fontSize: 27,
                                                fontWeight: FontWeight.w600)),
                                        Text(entry.$4,
                                            style: const TextStyle(
                                                color: _muted, fontSize: 10))
                                      ]))),
                      ])),
              const SizedBox(height: 22),
              const Text('Umidade do solo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text(
                  'Uma irrigação fictícia muda a série a partir de 14:15 UTC.',
                  style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
              const SizedBox(height: 20),
              const SizedBox(
                  height: 105,
                  width: double.infinity,
                  child: CustomPaint(painter: _Chart())),
              const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('14:00',
                        style: TextStyle(color: _muted, fontSize: 10)),
                    Text('14:15',
                        style: TextStyle(color: _muted, fontSize: 10)),
                    Text('14:25 UTC',
                        style: TextStyle(color: _muted, fontSize: 10))
                  ]),
              const SizedBox(height: 18),
              const Text(
                  '26 out. 2026 • 6 leituras fictícias • Sensor DEMO-USP-008\nEscala relativa do solo sem calibração física. Não é um diagnóstico da planta.',
                  style: TextStyle(fontSize: 10, height: 1.7, color: _muted)),
            ])),
        const SizedBox(height: 22),
        _Panel(
            title: 'Uma rede ao redor da planta',
            eyebrow: 'CONEXÕES',
            child: Column(children: [
              for (final item in [
                (
                  Icons.sensors,
                  'Sensor virtual',
                  'Relaciona-se com a planta · Mede o ambiente'
                ),
                (
                  Icons.yard_outlined,
                  'Canteiro demonstrativo',
                  'Ambiente associado à planta'
                ),
                (
                  Icons.person_outline,
                  'Pesquisador fictício',
                  'Acompanha a planta no cenário didático'
                )
              ])
                Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: const Color(0xFF1C3540),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(item.$1, color: _teal, size: 20)),
                      const SizedBox(width: 13),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(item.$2,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 5),
                            Text(item.$3,
                                style: const TextStyle(
                                    color: _muted, fontSize: 11, height: 1.4))
                          ])),
                      const Icon(Icons.arrow_outward, size: 16, color: _muted)
                    ])),
              const Text(
                  'Relações do piloto fictício. A ligação anterior da pista foi preservada e será apresentada na integração completa.',
                  style: TextStyle(fontSize: 10, color: _muted, height: 1.6)),
            ])),
      ]);

  Widget _sideColumn(BuildContext context) => Column(children: [
        const _Panel(
            title: 'O território desta pista',
            eyebrow: 'CONTEXTO AMBIENTAL',
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Datum('Bioma', 'Mata Atlântica'),
              _Datum('Cobertura predominante', 'Área urbanizada'),
              _Datum('Vegetação no entorno', '14,34%'),
              _Datum('Altitude', '52,49 m'),
              SizedBox(height: 6),
              Text('Análise do cadastro · 25 set. 2026',
                  style: TextStyle(fontSize: 10, color: _muted)),
              SizedBox(height: 12),
              Text(
                  'Dados do entorno geográfico. Não descrevem a saúde nem a espécie da planta.',
                  style: TextStyle(color: _muted, fontSize: 11, height: 1.6)),
            ])),
        const SizedBox(height: 22),
        _Panel(
            title: 'De onde vêm os dados',
            eyebrow: 'FONTES E TRANSPARÊNCIA',
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _Datum(
                  'Contexto territorial', 'Cadastro ambiental existente'),
              const Text(
                  'As referências de cada indicador serão exibidas a partir do retorno da API, sem atribuir uma fonte por suposição.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.6)),
              const SizedBox(height: 18),
              const _Datum(
                  'Leituras e identidade', 'Simulação didática identificada'),
              const Text(
                  'Valores preparados para este piloto. Nenhum dispositivo está transmitindo nesta prévia.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.6)),
            ])),
        const SizedBox(height: 22),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF133B43), Color(0xFF152238)]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF28505B))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.forum_outlined, color: _teal),
              const SizedBox(height: 15),
              const Text('O que você quer descobrir?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              const Text(
                  'Explore as relações entre as leituras e o ambiente. Uma pergunta pode abrir novas conexões.',
                  style: TextStyle(fontSize: 12, color: _muted, height: 1.7)),
              const SizedBox(height: 14),
              TextButton(
                  onPressed: () => _preview(context, 'Pergunta sugerida',
                      '“O que mudou nas leituras após a irrigação simulada?”\n\nPrévia de acesso ao chat, sem envio de mensagem.'),
                  child: const Text('Começar uma conversa  ↗',
                      style: TextStyle(color: _teal, fontSize: 12))),
            ])),
      ]);
}

class _Panel extends StatelessWidget {
  const _Panel(
      {required this.title, required this.eyebrow, required this.child});
  final String title;
  final String eyebrow;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF233049))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow,
            style: const TextStyle(
                fontSize: 9,
                letterSpacing: 1.7,
                color: _teal,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 20, height: 1.25, fontWeight: FontWeight.w600)),
        const SizedBox(height: 22),
        child
      ]));
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFF203541),
          borderRadius: BorderRadius.circular(5)),
      child: Text(text,
          style:
              const TextStyle(fontSize: 9, color: _teal, letterSpacing: .4)));
}

class _Datum extends StatelessWidget {
  const _Datum(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))
      ]));
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.active = false});
  final String text;
  final bool active;
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          color: active ? _teal : _muted,
          fontSize: 12,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400));
}

class _PlantArt extends StatelessWidget {
  const _PlantArt();
  @override
  Widget build(BuildContext context) => Container(
      height: 285,
      width: double.infinity,
      decoration: BoxDecoration(
          gradient: const RadialGradient(
              center: Alignment(.25, -.15),
              radius: 1,
              colors: [Color(0xFF204E49), Color(0xFF101E2C)]),
          borderRadius: BorderRadius.circular(18)),
      child: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: _Leaves())),
        const Positioned(
            top: 17, left: 17, child: _Pill('ECOSSISTEMA EM CONEXÃO')),
        const Positioned(
            bottom: 17,
            left: 17,
            child: Text('Ilustração do cenário • Planta demonstrativa',
                style: TextStyle(color: _muted, fontSize: 10))),
        Positioned(
            bottom: 17,
            right: 17,
            child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFF294943)),
                child: const Icon(Icons.eco_outlined, color: _teal, size: 18))),
      ]));
}

class _Leaves extends CustomPainter {
  const _Leaves();
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .53, size.height * .74);
    final stroke = Paint()
      ..color = const Color(0xFF6EAB82)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, Offset(center.dx - 5, 48), stroke);
    for (final spec in [
      (-1.0, .42, 62.0),
      (1.0, .50, 69.0),
      (-1.0, .63, 52.0),
      (1.0, .74, 51.0),
      (-1.0, .83, 36.0)
    ]) {
      final y = size.height * spec.$2;
      final origin = Offset(center.dx, y);
      final tip = Offset(center.dx + spec.$1 * spec.$3, y - spec.$3 * .70);
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..quadraticBezierTo(
            origin.dx + spec.$1 * spec.$3 * .12, y - spec.$3, tip.dx, tip.dy)
        ..quadraticBezierTo(origin.dx + spec.$1 * spec.$3 * 1.15,
            y + spec.$3 * .13, origin.dx, origin.dy);
      canvas.drawPath(
          path,
          Paint()
            ..shader = const LinearGradient(
                    colors: [Color(0xFF71AD77), Color(0xFF275A43)])
                .createShader(path.getBounds()));
      canvas.drawLine(
          origin,
          tip,
          Paint()
            ..color = const Color(0xFF8BC38D).withValues(alpha: .6)
            ..strokeWidth = 1);
    }
    final pot = Path()
      ..moveTo(center.dx - 40, center.dy)
      ..lineTo(center.dx + 40, center.dy)
      ..lineTo(center.dx + 28, center.dy + 42)
      ..lineTo(center.dx - 28, center.dy + 42)
      ..close();
    canvas.drawPath(pot, Paint()..color = const Color(0xFFB87555));
    canvas.drawOval(Rect.fromCenter(center: center, width: 80, height: 13),
        Paint()..color = const Color(0xFF5B3E32));
    canvas.drawLine(
        Offset(center.dx + 29, center.dy - 5),
        Offset(center.dx + 29, center.dy - 46),
        Paint()
          ..color = _teal
          ..strokeWidth = 3);
    canvas.drawCircle(
        Offset(center.dx + 29, center.dy - 46), 5, Paint()..color = _teal);
    canvas.drawCircle(Offset(size.width * .82, size.height * .35), 26,
        Paint()..color = _teal.withValues(alpha: .08));
    canvas.drawCircle(Offset(size.width * .82, size.height * .35), 18,
        Paint()..color = _teal.withValues(alpha: .13));
  }

  @override
  bool shouldRepaint(covariant _Leaves oldDelegate) => false;
}

class _Chart extends CustomPainter {
  const _Chart();
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFF28374D)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = 8 + i * (size.height - 20) / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final points = <Offset>[];
    const values = [28, 27, 26, 45, 49, 48];
    for (var i = 0; i < values.length; i++) {
      points.add(Offset(i * size.width / 5,
          size.height - ((values[i] - 20) / 35) * (size.height - 12) - 6));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _teal.withValues(alpha: .2),
                _teal.withValues(alpha: 0)
              ]).createShader(Offset.zero & size));
    canvas.drawPath(
        path,
        Paint()
          ..color = _teal
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke);
    for (final point in points) {
      canvas.drawCircle(point, 3, Paint()..color = _teal);
    }
  }

  @override
  bool shouldRepaint(covariant _Chart oldDelegate) => false;
}
