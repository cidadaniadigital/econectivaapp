import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/node_link_model.dart';
import 'package:unisinos_usp_app/models/node_map_model.dart';
import 'package:unisinos_usp_app/models/node_model.dart';
import 'package:unisinos_usp_app/models/node_type_model.dart';
import 'package:unisinos_usp_app/utils/safe_get_snackbar.dart';
import 'package:unisinos_usp_app/webclients/node_link_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_type_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class NodeGraphController extends GetxController {
  final NodeWebclient _nodeWebclient = NodeWebclient();
  final NodeLinkWebclient _nodeLinkWebclient = NodeLinkWebclient();
  final NodeTypeWebclient _nodeTypeWebclient = NodeTypeWebclient();

  final RxList<NodeGraphNodeState> graphNodes = <NodeGraphNodeState>[].obs;
  final RxList<NodeLinkModel> graphLinks = <NodeLinkModel>[].obs;
  final RxList<NodeTypeModel> nodeTypes = <NodeTypeModel>[].obs;
  final RxSet<int> selectedTypeIds = RxSet<int>({});
  final Rxn<int> selectedNodeId = Rxn<int>();
  final RxInt minimumDegree = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSavingNode = false.obs;
  final RxBool isDeletingNode = false.obs;
  final RxBool isSavingLink = false.obs;
  final RxBool isDeletingLink = false.obs;
  final Rxn<String> errorMessage = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    loadGraph();
  }

  Future<void> loadGraph() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final results = await Future.wait([
        _nodeWebclient.fetchMap(),
        _nodeTypeWebclient.fetch(limit: 200, offset: 0),
      ]);
      final NodeMapModel map = results[0] as NodeMapModel;
      final List<NodeTypeModel> types = results[1] as List<NodeTypeModel>;

      graphNodes.assignAll(_buildNodeStates(map.nodes, map.links));
      graphLinks.assignAll(map.links);
      nodeTypes.assignAll(types);
      final focus = int.tryParse(Get.parameters['focus'] ?? '');
      if (focus != null && graphNodes.any((e) => e.node.id == focus)) {
        selectedNodeId.value = focus;
      }
      selectedTypeIds
        ..clear()
        ..addAll(types.map((item) => item.id));
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      errorMessage.value = 'Não foi possível carregar o grafo agora.';
    } finally {
      isLoading.value = false;
    }
  }

  List<NodeGraphNodeState> _buildNodeStates(
      List<NodeGraphNode> nodes, List<NodeLinkModel> links) {
    final Map<int, int> degreeById = <int, int>{};
    for (final link in links) {
      degreeById.update(link.sourceNodeId, (value) => value + 1,
          ifAbsent: () => 1);
      degreeById.update(link.targetNodeId, (value) => value + 1,
          ifAbsent: () => 1);
    }

    final List<NodeGraphNodeState> states = nodes
        .map(
          (graphNode) => NodeGraphNodeState(
            node: graphNode.node,
            position: graphNode.position ?? Offset.zero,
            degree: degreeById[graphNode.node.id] ?? 0,
          ),
        )
        .toList();

    if (states.every((node) => node.position == Offset.zero)) {
      final double radius = math.max(260, states.length * 26).toDouble();
      for (int index = 0; index < states.length; index++) {
        final double angle = (2 * math.pi * index) / math.max(states.length, 1);
        states[index] = states[index].copyWith(
          position: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        );
      }
    }

    return states;
  }

  List<NodeGraphNodeState> get visibleNodes => graphNodes
      .where(
        (node) =>
            selectedTypeIds.contains(node.node.nodeTypeId) &&
            node.degree >= minimumDegree.value,
      )
      .toList();

  List<NodeLinkModel> get visibleLinks {
    final Set<int> ids = visibleNodes.map((item) => item.node.id).toSet();
    return graphLinks
        .where((link) =>
            ids.contains(link.sourceNodeId) && ids.contains(link.targetNodeId))
        .toList();
  }

  Set<int> get neighborNodeIds {
    final int? selected = selectedNodeId.value;
    if (selected == null) return const <int>{};
    final Set<int> ids = <int>{selected};
    for (final link in visibleLinks) {
      if (link.sourceNodeId == selected) ids.add(link.targetNodeId);
      if (link.targetNodeId == selected) ids.add(link.sourceNodeId);
    }
    return ids;
  }

  void toggleType(int nodeTypeId, bool enabled) {
    if (enabled) {
      selectedTypeIds.add(nodeTypeId);
    } else {
      selectedTypeIds.remove(nodeTypeId);
    }
    _ensureSelectedNodeVisible();
  }

  void updateMinimumDegree(double value) {
    minimumDegree.value = value.round();
    _ensureSelectedNodeVisible();
  }

  void selectNode(int? nodeId) {
    if (selectedNodeId.value == nodeId) {
      selectedNodeId.value = null;
      return;
    }
    selectedNodeId.value = nodeId;
  }

  void updateNodePosition(int nodeId, Offset position) {
    final int index = graphNodes.indexWhere((item) => item.node.id == nodeId);
    if (index == -1) return;
    graphNodes[index] = graphNodes[index].copyWith(position: position);
    graphNodes.refresh();
  }

  Future<NodeModel?> createNode({
    required String name,
    required String color,
    required int nodeTypeId,
  }) async {
    try {
      isSavingNode.value = true;
      final Offset initialPosition = _nextNewNodePosition();
      final NodeModel created = await _nodeWebclient.create(
        NodeModel(
          id: 0,
          name: name.trim(),
          color: color.trim(),
          nodeTypeId: nodeTypeId,
          x: initialPosition.dx,
          y: initialPosition.dy,
        ),
      );

      final NodeTypeModel? type =
          nodeTypes.firstWhereOrNull((item) => item.id == created.nodeTypeId);
      if (type != null) created.nodeType = type;

      final NodeGraphNodeState state = NodeGraphNodeState(
        node: created,
        position: Offset(
            created.x ?? initialPosition.dx, created.y ?? initialPosition.dy),
        degree: 0,
      );

      graphNodes.add(state);
      selectedTypeIds.add(created.nodeTypeId);
      selectedNodeId.value = created.id;
      graphNodes.refresh();
      SafeGetSnackbar.success('Nó criado com sucesso.');
      return created;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível criar o nó.');
      return null;
    } finally {
      isSavingNode.value = false;
    }
  }

  Future<NodeModel?> updateNode({
    required int id,
    required String name,
    required String color,
    required int nodeTypeId,
  }) async {
    final int index = graphNodes.indexWhere((item) => item.node.id == id);
    if (index == -1) return null;

    final NodeModel current = graphNodes[index].node;
    final NodeModel updatedModel = NodeModel(
      id: id,
      name: name.trim(),
      color: color.trim(),
      nodeTypeId: nodeTypeId,
      x: graphNodes[index].position.dx,
      y: graphNodes[index].position.dy,
    );

    try {
      isSavingNode.value = true;
      final NodeModel saved = await _nodeWebclient.update(updatedModel);
      final NodeTypeModel? type =
          nodeTypes.firstWhereOrNull((item) => item.id == saved.nodeTypeId);
      if (type != null) saved.nodeType = type;

      graphNodes[index] = graphNodes[index].copyWith(node: saved);
      selectedTypeIds.add(saved.nodeTypeId);
      graphNodes.refresh();
      SafeGetSnackbar.success('Nó atualizado com sucesso.');
      return saved;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      graphNodes[index] = graphNodes[index].copyWith(node: current);
      graphNodes.refresh();
      SafeGetSnackbar.error('Erro', 'Não foi possível atualizar o nó.');
      return null;
    } finally {
      isSavingNode.value = false;
    }
  }

  Future<bool> deleteNode(int id) async {
    final int nodeIndex = graphNodes.indexWhere((item) => item.node.id == id);
    if (nodeIndex == -1) return false;

    final NodeGraphNodeState removedNode = graphNodes[nodeIndex];
    final List<NodeLinkModel> removedLinks = graphLinks
        .where((link) => link.sourceNodeId == id || link.targetNodeId == id)
        .toList();

    try {
      isDeletingNode.value = true;
      await _nodeWebclient.delete(id);
      graphNodes.removeAt(nodeIndex);
      graphLinks.removeWhere(
          (link) => link.sourceNodeId == id || link.targetNodeId == id);
      if (selectedNodeId.value == id) selectedNodeId.value = null;
      _syncNodeDegrees();
      SafeGetSnackbar.success('Nó removido com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      if (!graphNodes.any((item) => item.node.id == id)) {
        graphNodes.insert(nodeIndex, removedNode);
      }
      for (final link in removedLinks) {
        if (!graphLinks.any((item) => item.id == link.id)) {
          graphLinks.add(link);
        }
      }
      _syncNodeDegrees();
      SafeGetSnackbar.error('Erro', 'Não foi possível remover o nó.');
      return false;
    } finally {
      isDeletingNode.value = false;
    }
  }

  Future<void> persistNodePosition(int nodeId) async {
    final int index = graphNodes.indexWhere((item) => item.node.id == nodeId);
    if (index == -1) return;

    final NodeGraphNodeState state = graphNodes[index];
    final NodeModel current = state.node;

    try {
      final NodeModel saved = await _nodeWebclient.update(
        NodeModel(
          id: current.id,
          name: current.name,
          color: current.color,
          nodeTypeId: current.nodeTypeId,
          x: state.position.dx,
          y: state.position.dy,
        ),
      );
      saved.nodeType = current.nodeType;
      graphNodes[index] = graphNodes[index].copyWith(node: saved);
      graphNodes.refresh();
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível salvar a posição do nó.');
    }
  }

  Future<NodeLinkModel?> createLink({
    required int sourceNodeId,
    required int targetNodeId,
  }) async {
    if (sourceNodeId == targetNodeId) {
      SafeGetSnackbar.error(
          'Erro', 'Escolha nós diferentes para criar a ligação.');
      return null;
    }

    final bool exists = graphLinks.any(
      (item) =>
          (item.sourceNodeId == sourceNodeId &&
              item.targetNodeId == targetNodeId) ||
          (item.sourceNodeId == targetNodeId &&
              item.targetNodeId == sourceNodeId),
    );
    if (exists) {
      SafeGetSnackbar.error('Erro', 'Esses nós já estão conectados.');
      return null;
    }

    try {
      isSavingLink.value = true;
      final NodeLinkModel created = await _nodeLinkWebclient.create(
        NodeLinkModel(
          id: 0,
          sourceNodeId: sourceNodeId,
          targetNodeId: targetNodeId,
        ),
      );

      graphLinks.add(created);
      _syncNodeDegrees();
      selectedNodeId.value = sourceNodeId;
      SafeGetSnackbar.success('Ligação criada com sucesso.');
      return created;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível criar a ligação.');
      return null;
    } finally {
      isSavingLink.value = false;
    }
  }

  Future<bool> deleteLink(int linkId) async {
    final int linkIndex = graphLinks.indexWhere((item) => item.id == linkId);
    if (linkIndex == -1) return false;

    final NodeLinkModel removedLink = graphLinks[linkIndex];
    try {
      isDeletingLink.value = true;
      await _nodeLinkWebclient.delete(linkId);
      graphLinks.removeAt(linkIndex);
      _syncNodeDegrees();
      SafeGetSnackbar.success('Ligação removida com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      if (!graphLinks.any((item) => item.id == linkId)) {
        graphLinks.insert(linkIndex, removedLink);
      }
      _syncNodeDegrees();
      SafeGetSnackbar.error('Erro', 'Não foi possível remover a ligação.');
      return false;
    } finally {
      isDeletingLink.value = false;
    }
  }

  Offset _nextNewNodePosition() {
    final int? selectedId = selectedNodeId.value;
    if (selectedId != null) {
      final NodeGraphNodeState? anchor =
          graphNodes.firstWhereOrNull((item) => item.node.id == selectedId);
      if (anchor != null) {
        final double angle = (graphNodes.length % 8) * (math.pi / 4);
        return anchor.position +
            Offset(math.cos(angle) * 140, math.sin(angle) * 140);
      }
    }

    final int index = graphNodes.length;
    if (index == 0) return Offset.zero;
    final double angle = (2 * math.pi * index) / math.max(index + 1, 1);
    final double radius = math.max(120, index * 18).toDouble();
    return Offset(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  List<NodeModel> availableTargetsFor(int sourceNodeId) {
    final Set<int> connectedIds = graphLinks
        .where((item) =>
            item.sourceNodeId == sourceNodeId ||
            item.targetNodeId == sourceNodeId)
        .map((item) => item.sourceNodeId == sourceNodeId
            ? item.targetNodeId
            : item.sourceNodeId)
        .toSet();

    return graphNodes
        .map((item) => item.node)
        .where((node) =>
            node.id != sourceNodeId && !connectedIds.contains(node.id))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  List<NodeLinkModel> connectionsFor(int nodeId) {
    final List<NodeLinkModel> connections = graphLinks
        .where((item) =>
            item.sourceNodeId == nodeId || item.targetNodeId == nodeId)
        .toList();
    connections.sort((a, b) {
      final String aName =
          otherNodeForLink(a, nodeId)?.name.toLowerCase() ?? '';
      final String bName =
          otherNodeForLink(b, nodeId)?.name.toLowerCase() ?? '';
      return aName.compareTo(bName);
    });
    return connections;
  }

  NodeModel? otherNodeForLink(NodeLinkModel link, int referenceNodeId) {
    final int otherId = link.sourceNodeId == referenceNodeId
        ? link.targetNodeId
        : link.sourceNodeId;
    final NodeGraphNodeState? state =
        graphNodes.firstWhereOrNull((item) => item.node.id == otherId);
    return state?.node;
  }

  void _syncNodeDegrees() {
    final Map<int, int> degreeById = <int, int>{};
    for (final link in graphLinks) {
      degreeById.update(link.sourceNodeId, (value) => value + 1,
          ifAbsent: () => 1);
      degreeById.update(link.targetNodeId, (value) => value + 1,
          ifAbsent: () => 1);
    }

    for (int index = 0; index < graphNodes.length; index++) {
      final NodeGraphNodeState current = graphNodes[index];
      graphNodes[index] =
          current.copyWith(degree: degreeById[current.node.id] ?? 0);
    }
    graphNodes.refresh();
    graphLinks.refresh();
    _ensureSelectedNodeVisible();
  }

  void _ensureSelectedNodeVisible() {
    final int? selected = selectedNodeId.value;
    if (selected == null) return;
    final bool stillVisible =
        visibleNodes.any((node) => node.node.id == selected);
    if (!stillVisible) selectedNodeId.value = null;
  }
}

class NodeGraphNodeState {
  NodeGraphNodeState({
    required this.node,
    required this.position,
    required this.degree,
  });

  final NodeModel node;
  final Offset position;
  final int degree;

  double get radius => 34 + math.min(degree, 10) * 4.0;

  NodeGraphNodeState copyWith({
    NodeModel? node,
    Offset? position,
    int? degree,
  }) {
    return NodeGraphNodeState(
      node: node ?? this.node,
      position: position ?? this.position,
      degree: degree ?? this.degree,
    );
  }
}
