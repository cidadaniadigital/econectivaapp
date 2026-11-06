import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/models/ai_assistant_screen_context.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final UserController _controller = Get.find<UserController>();

  @override
  Widget build(BuildContext context) {
    Get.find<AiAssistantContextService>().registerProvider(
      Get.currentRoute,
      _buildAiContext,
    );

    final menus = <_HomeMenu>[
      _HomeMenu(
          title: 'Catálogo',
          subtitle: 'Pesquisar pistas e conteúdos',
          icon: Icons.explore_outlined,
          color: const Color(0xFF43D4C2),
          onTap: () => Get.toNamed('/catalog')),
      _HomeMenu(
        title: 'Categorias',
        subtitle: 'Organize categorias e temas',
        icon: Icons.category_rounded,
        color: const Color(0xFF29B6F6),
        onTap: () => Get.toNamed('/categories'),
      ),
      _HomeMenu(
        title: 'Pistas',
        subtitle: 'Lista e gestão de pistas',
        icon: Icons.radar_rounded,
        color: const Color(0xFF3CE4C8),
        onTap: () => Get.toNamed('/living_clues'),
      ),
      _HomeMenu(
        title: 'Mapa de pistas',
        subtitle: 'Visualização territorial',
        icon: Icons.map_rounded,
        color: const Color(0xFFFFB74D),
        onTap: () => Get.toNamed('/living_clues/map'),
      ),
      _HomeMenu(
        title: 'Conexões',
        subtitle: 'Relacionar pistas e contexto',
        icon: Icons.hub_rounded,
        color: const Color(0xFFEF6EB0),
        onTap: () => Get.toNamed('/clue_connections'),
      ),
      _HomeMenu(
        title: 'Tipos de conexão',
        subtitle: 'Cadastre e edite tipos',
        icon: Icons.link_rounded,
        color: const Color(0xFF7D8BFF),
        onTap: () => Get.toNamed('/connection_types'),
      ),
      _HomeMenu(
        title: 'Agentes',
        subtitle: 'Templates e chats de IA',
        icon: Icons.psychology_alt_rounded,
        color: const Color(0xFF56D5FF),
        onTap: () => Get.toNamed('/chat_templates'),
      ),
      _HomeMenu(
        title: 'Tipos de nó',
        subtitle: 'Taxonomias de análise',
        icon: Icons.label_rounded,
        color: const Color(0xFFF3C45F),
        onTap: () => Get.toNamed('/node_types'),
      ),
      _HomeMenu(
        title: 'Problemáticas',
        subtitle: 'Visualização estilo grafo',
        icon: Icons.account_tree_rounded,
        color: const Color(0xFFFF8A65),
        onTap: () => Get.toNamed('/nodes/graph'),
      ),
      _HomeMenu(
        title: 'Usuários',
        subtitle: 'Cadastro e gestão de acesso',
        icon: Icons.groups_rounded,
        color: const Color(0xFF78E08F),
        onTap: () => Get.toNamed('/users'),
      ),
    ];

    final userName = _controller.user.value?.name.trim();
    final displayName =
        (userName == null || userName.isEmpty) ? 'Usuário' : userName;
    final isCompact = MediaQuery.sizeOf(context).width < 920;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _CidigScenicBackground()),
          SafeArea(
            child: Column(
              children: [
                _HomeTopBar(
                  userName: displayName,
                  onProfileTap: () => Get.toNamed('/profile'),
                  onLogout: _controller.logout,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _HeroPanel(),
                            const SizedBox(height: 20),
                            const _SectionTitle(
                              title: 'Módulos',
                              subtitle: 'Acessos da plataforma',
                            ),
                            const SizedBox(height: 10),
                            Obx(() => _AllModulesGrid(
                                menus: menus
                                    .where((menu) =>
                                        menu.title != 'Usuários' ||
                                        _controller
                                                .user.value?.isAdministrator ==
                                            true)
                                    .toList(),
                                compact: isCompact)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AiAssistantScreenContext _buildAiContext() {
    return AiAssistantScreenContext(
      screenName: 'Home',
      route: Get.currentRoute,
      stage: 'navegação principal',
      goal: 'acessar uma das áreas principais do sistema',
      visibleFields: const <String>[
        'categorias',
        'pistas',
        'mapa de pistas',
        'tipos de conexão',
        'conexões',
        'agentes',
        'tipos de nó',
        'problemáticas',
        'usuários',
      ],
      filledFields: <String, String>{
        'usuário': _controller.user.value?.name ?? 'não identificado',
      },
      notes: const <String>[
        'A tela inicial funciona como atalho para os módulos principais.',
      ],
    );
  }
}

class _HomeMenu {
  _HomeMenu({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.userName,
    required this.onProfileTap,
    required this.onLogout,
  });

  final String userName;
  final VoidCallback onProfileTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Image.asset('assets/logo_atopos.png', height: compact ? 36 : 52),
          const SizedBox(width: 12),
          if (!compact)
            const Expanded(
              child: Text(
                'Plataforma para a Cidadania Digital',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFD6E7FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (compact) const Spacer(),
          _ProfilePill(
              userName: userName, onTap: onProfileTap, compact: compact),
          const SizedBox(width: 10),
          if (compact)
            IconButton(
                tooltip: 'Sair',
                onPressed: onLogout,
                icon:
                    const Icon(Icons.logout_rounded, color: Color(0xFFFFB49B)))
          else
            FilledButton.tonalIcon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sair'),
              style: FilledButton.styleFrom(
                foregroundColor: const Color(0xFFFFB49B),
                backgroundColor: const Color(0x2CE6512D),
                side: const BorderSide(color: Color(0x40FF7F5B)),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill(
      {required this.userName, required this.onTap, this.compact = false});

  final String userName;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final initial =
        userName.isEmpty ? '?' : userName.substring(0, 1).toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x500C2B56),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0x3A4CC1F2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF1C7FCC),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!compact) const SizedBox(width: 8),
              if (!compact)
                SizedBox(
                  width: 120,
                  child: Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC8DBFA),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xE80B2C5A), Color(0xD3051632)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x2949C3F8)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CIDIG',
            style: TextStyle(
              color: Color(0xFF57D2FF),
              fontSize: 13,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Uma iniciativa internacional para o avanço da cidadania digital',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Navegue por conteúdos, trilhas e ferramentas da plataforma com uma experiência visual unificada entre app e site.',
            style: TextStyle(
              color: Color(0xFFA6C5EF),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE7F0FF),
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF91AED7), fontSize: 13),
        ),
      ],
    );
  }
}

class _AllModulesGrid extends StatelessWidget {
  const _AllModulesGrid({required this.menus, required this.compact});

  final List<_HomeMenu> menus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = compact ? 1 : 4;
    final ratio = compact ? 4.2 : 3.8;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: ratio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        return _ModuleCard(menu: menus[index]);
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.menu});

  final _HomeMenu menu;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: menu.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xB50A1C3D), Color(0xA9061430)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x8A46B6EC), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF020814).withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: menu.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: menu.color.withValues(alpha: 0.45)),
                ),
                child: Icon(menu.icon, color: menu.color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      menu.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFA4C0E6),
                        fontSize: 11.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF66CFFF),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CidigScenicBackground extends StatelessWidget {
  const _CidigScenicBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF020914), Color(0xFF03162F), Color(0xFF051F3D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -260,
            top: -180,
            child: Container(
              width: 560,
              height: 560,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x2E2AB9FF), Color(0x0032B9FF)],
                ),
              ),
            ),
          ),
          Positioned(
            right: -190,
            top: 90,
            child: Container(
              width: 480,
              height: 480,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x1D58DFFF), Color(0x0058DFFF)],
                ),
              ),
            ),
          ),
          Positioned(
            left: -120,
            bottom: -260,
            child: Container(
              width: 760,
              height: 520,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x1B00D0FF), Color(0x0000D0FF)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
