#!/usr/bin/env python3
"""
Knowledge Graph Generator para Proyecto Chismes
Analiza el código Flutter/Dart y genera un grafo de dependencias
"""

import os
import re
import json
import networkx as nx
import matplotlib.pyplot as plt
from pathlib import Path
from typing import Dict, List, Set, Tuple

class ChismesKnowledgeGraph:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.lib_path = self.project_root / "lib"
        self.graph = nx.DiGraph()
        self.files_analyzed = 0
        self.pending_edges = []  # ✅ FIX: Guardar edges temporalmente

    def analyze_project(self):
        """Analiza todo el proyecto y construye el grafo"""
        print(f"🔍 Analizando proyecto en: {self.project_root}")

        # PASO 1: Analizar archivos Dart (crear nodos)
        for dart_file in self.lib_path.rglob("*.dart"):
            self._analyze_file(dart_file)

        # PASO 2: ✅ FIX: Crear edges solo entre nodos existentes
        print(f"🔗 Resolviendo dependencias...")
        edges_created = 0
        edges_skipped = 0

        for source, target in self.pending_edges:
            if target in self.graph:
                self.graph.add_edge(source, target, relation="imports")
                edges_created += 1
            else:
                # Nodo fantasma detectado, no crear edge
                edges_skipped += 1

        if edges_skipped > 0:
            print(f"⚠️  Imports no resueltos (nodos fantasmas evitados): {edges_skipped}")

        print(f"✅ Análisis completo: {self.files_analyzed} archivos")
        print(f"📊 Nodos: {self.graph.number_of_nodes()}")
        print(f"📊 Relaciones: {edges_created}")

    def _analyze_file(self, file_path: Path):
        """Analiza un archivo Dart individual"""
        self.files_analyzed += 1

        relative_path = file_path.relative_to(self.lib_path)
        node_id = str(relative_path).replace(".dart", "").replace("/", ".")

        # Categorizar nodo
        node_type = self._get_node_type(relative_path)
        layer = self._get_layer(relative_path)
        feature = self._get_feature(relative_path)

        # ✅ MEJORA: Extraer evidence (metadata semántica)
        evidence = []
        detail = ""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                evidence, detail = self._extract_evidence(content, node_type)
                self._extract_dependencies(node_id, content)
        except Exception as e:
            print(f"⚠️  Error leyendo {file_path}: {e}")

        # Agregar nodo con metadata rica
        self.graph.add_node(
            node_id,
            file=str(relative_path),
            type=node_type,
            layer=layer,
            feature=feature,
            evidence=evidence,      # ✅ NUEVO: Evidence semántica
            detail=detail,          # ✅ NUEVO: Detalle del nodo
        )

    def _get_node_type(self, path: Path) -> str:
        """Determina el tipo de nodo basado en el path"""
        parts = path.parts

        if "entities" in parts:
            return "entity"
        elif "repositories" in parts:
            return "repository"
        elif "datasources" in parts:
            return "datasource"
        elif "models" in parts:
            return "model"
        elif "usecases" in parts:
            return "usecase"
        elif "controllers" in parts:
            return "controller"
        elif "screens" in parts:
            return "screen"
        elif "widgets" in parts:
            return "widget"
        elif "services" in parts:
            return "service"
        elif "config" in parts:
            return "config"
        elif "theme" in parts:
            return "theme"
        elif "validation" in parts:
            return "validator"
        else:
            return "other"

    def _get_layer(self, path: Path) -> str:
        """Determina la capa de Clean Architecture"""
        parts = path.parts

        if "domain" in parts:
            return "domain"
        elif "data" in parts:
            return "data"
        elif "presentation" in parts:
            return "presentation"
        elif "core" in parts:
            return "core"
        else:
            return "shared"

    def _get_feature(self, path: Path) -> str:
        """Determina el feature"""
        parts = path.parts

        if "features" in parts:
            feature_idx = parts.index("features")
            if feature_idx + 1 < len(parts):
                return parts[feature_idx + 1]
        elif "core" in parts:
            return "core"

        return "shared"

    def _extract_dependencies(self, node_id: str, content: str):
        """Extrae dependencias de imports"""
        # Pattern para imports relativos
        import_pattern = r"import\s+['\"]([^'\"]+)['\"]"

        for match in re.finditer(import_pattern, content):
            import_path = match.group(1)

            # Solo procesar imports internos del proyecto
            if not import_path.startswith("package:"):
                # Convertir path relativo a node_id
                dep_node_id = self._resolve_import(node_id, import_path)
                if dep_node_id:
                    # ✅ FIX: Guardar edge para resolver después
                    # (cuando todos los nodos existan)
                    self.pending_edges.append((node_id, dep_node_id))

    def _resolve_import(self, current_node: str, import_path: str) -> str:
        """Resuelve un import relativo a un node_id"""
        # Simplificación: convertir path a node_id
        # Eliminar ../ y .dart
        clean_path = import_path.replace("../", "").replace("./", "").replace(".dart", "")
        return clean_path.replace("/", ".")

    def _extract_evidence(self, content: str, node_type: str) -> tuple:
        """
        Extrae evidence semántica del código

        Returns:
            (evidence: List[str], detail: str)
        """
        evidence = []
        detail = ""

        # Extraer clase principal
        class_match = re.search(r'class\s+(\w+)', content)
        if class_match:
            class_name = class_match.group(1)
            evidence.append(f"class {class_name}")
            detail = class_name

        # Extraer extends/implements
        extends_match = re.search(r'extends\s+(\w+)', content)
        if extends_match:
            evidence.append(f"extends {extends_match.group(1)}")

        implements_match = re.search(r'implements\s+(\w+)', content)
        if implements_match:
            evidence.append(f"implements {implements_match.group(1)}")

        # Extraer métodos públicos principales
        methods = re.findall(r'(?:Future<\w+>|void|String|\w+)\s+(\w+)\s*\([^)]*\)', content)
        public_methods = [m for m in methods if not m.startswith('_') and m not in ['build', 'main']]
        if public_methods:
            evidence.extend([f"method:{m}" for m in public_methods[:3]])  # Max 3

        # Tipo específico
        if node_type == "entity":
            # Buscar propiedades final
            properties = re.findall(r'final\s+(\w+)\s+(\w+);', content)
            if properties:
                evidence.extend([f"field:{prop[1]}" for prop in properties[:3]])  # Max 3

        elif node_type == "controller":
            # Buscar estado
            if "ChangeNotifier" in content or "StateNotifier" in content:
                evidence.append("stateful")

        elif node_type == "repository":
            # Buscar retorno Result/Future
            if "Result<" in content:
                evidence.append("returns:Result")

        return evidence[:8], detail  # Max 8 evidence items

    def search(self, query: str) -> List[Dict]:
        """Busca nodos en el grafo"""
        results = []

        for node_id, data in self.graph.nodes(data=True):
            if query.lower() in node_id.lower():
                # Obtener relaciones
                dependencies = list(self.graph.successors(node_id))
                dependents = list(self.graph.predecessors(node_id))

                results.append({
                    "node_id": node_id,
                    "type": data.get("type"),
                    "layer": data.get("layer"),
                    "feature": data.get("feature"),
                    "file": data.get("file"),
                    "dependencies": dependencies[:10],  # Max 10
                    "used_by": dependents[:10],  # Max 10
                })

        return results

    def impact_analysis(self, node_id: str) -> Dict:
        """Análisis de impacto de cambios en un nodo"""
        if node_id not in self.graph:
            return {"error": f"Node {node_id} not found"}

        # Dependencias directas (lo que este nodo usa)
        direct_deps = list(self.graph.successors(node_id))

        # Dependientes directos (lo que usa este nodo)
        direct_dependents = list(self.graph.predecessors(node_id))

        # Dependientes indirectos (transitivos)
        indirect_dependents = set()
        for dependent in direct_dependents:
            # BFS para encontrar todos los dependientes transitivos
            try:
                paths = nx.single_source_shortest_path(self.graph, dependent)
                indirect_dependents.update(paths.keys())
            except:
                pass

        # Remover dependientes directos de los indirectos
        indirect_dependents -= set(direct_dependents)
        indirect_dependents.discard(node_id)

        # Calcular nivel de riesgo
        total_affected = len(direct_dependents) + len(indirect_dependents)
        if total_affected == 0:
            risk_level = "LOW"
        elif total_affected < 5:
            risk_level = "MEDIUM"
        elif total_affected < 15:
            risk_level = "HIGH"
        else:
            risk_level = "CRITICAL"

        return {
            "node_id": node_id,
            "direct_dependencies": direct_deps,
            "direct_dependents": direct_dependents,
            "indirect_dependents": list(indirect_dependents)[:20],  # Max 20
            "total_affected": total_affected,
            "risk_level": risk_level,
        }

    def get_feature_graph(self, feature: str) -> Dict:
        """Obtiene el subgrafo de un feature específico"""
        feature_nodes = [
            node for node, data in self.graph.nodes(data=True)
            if data.get("feature") == feature
        ]

        subgraph = self.graph.subgraph(feature_nodes)

        # Agrupar por layer
        by_layer = {}
        for node in feature_nodes:
            layer = self.graph.nodes[node].get("layer", "unknown")
            if layer not in by_layer:
                by_layer[layer] = []
            by_layer[layer].append(node)

        return {
            "feature": feature,
            "nodes": len(feature_nodes),
            "edges": subgraph.number_of_edges(),
            "by_layer": by_layer,
        }

    def detect_violations(self) -> List[Dict]:
        """Detecta violaciones de Clean Architecture"""
        violations = []

        for edge in self.graph.edges(data=True):
            source, target, _ = edge
            source_layer = self.graph.nodes[source].get("layer")
            target_layer = self.graph.nodes[target].get("layer")

            # Regla: Presentation NO debe importar Data directamente
            if source_layer == "presentation" and target_layer == "data":
                violations.append({
                    "type": "layer_violation",
                    "from": source,
                    "to": target,
                    "rule": "Presentation should not depend on Data directly",
                    "severity": "HIGH",
                })

            # Regla: Data NO debe importar Presentation
            if source_layer == "data" and target_layer == "presentation":
                violations.append({
                    "type": "layer_violation",
                    "from": source,
                    "to": target,
                    "rule": "Data should not depend on Presentation",
                    "severity": "CRITICAL",
                })

        return violations

    def export_json(self, output_path: str):
        """Exporta el grafo a JSON"""
        data = {
            "nodes": [],
            "edges": [],
            "stats": {
                "total_nodes": self.graph.number_of_nodes(),
                "total_edges": self.graph.number_of_edges(),
                "files_analyzed": self.files_analyzed,
            }
        }

        # Nodos
        for node_id, attrs in self.graph.nodes(data=True):
            data["nodes"].append({
                "id": node_id,
                **attrs
            })

        # Edges
        for source, target, attrs in self.graph.edges(data=True):
            data["edges"].append({
                "from": source,
                "to": target,
                **attrs
            })

        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

        print(f"💾 Grafo exportado a: {output_path}")

    def visualize(self, output_path: str = "graph.png", layout: str = "spring"):
        """Visualiza el grafo (simplified)"""
        print("🎨 Generando visualización...")

        # Layout
        if layout == "spring":
            pos = nx.spring_layout(self.graph, k=0.5, iterations=50)
        elif layout == "circular":
            pos = nx.circular_layout(self.graph)
        else:
            pos = nx.kamada_kawai_layout(self.graph)

        # Colores por layer
        layer_colors = {
            "domain": "#4CAF50",    # Verde
            "data": "#2196F3",      # Azul
            "presentation": "#FF9800",  # Naranja
            "core": "#9C27B0",      # Púrpura
            "shared": "#607D8B",    # Gris
        }

        node_colors = [
            layer_colors.get(self.graph.nodes[node].get("layer", "shared"), "#999")
            for node in self.graph.nodes()
        ]

        # Plot
        plt.figure(figsize=(20, 20))
        nx.draw(
            self.graph,
            pos,
            node_color=node_colors,
            node_size=50,
            with_labels=False,
            arrows=True,
            edge_color="#cccccc",
            width=0.5,
            alpha=0.8,
        )

        plt.title("Chismes Project Knowledge Graph", fontsize=16)
        plt.tight_layout()
        plt.savefig(output_path, dpi=150, bbox_inches='tight')
        print(f"🖼️  Visualización guardada en: {output_path}")


def main():
    """Función principal"""
    import sys

    # Detectar raíz del proyecto
    current_dir = Path(__file__).parent
    project_root = current_dir.parent.parent  # tools/knowledge-graph -> project root

    print("=" * 60)
    print("🧠 Chismes Knowledge Graph Generator")
    print("=" * 60)

    # Crear grafo
    kg = ChismesKnowledgeGraph(project_root)

    # Analizar proyecto
    kg.analyze_project()

    print("\n" + "=" * 60)
    print("📊 ESTADÍSTICAS")
    print("=" * 60)

    # Estadísticas por feature
    features = set(data.get("feature") for _, data in kg.graph.nodes(data=True) if data.get("feature"))
    for feature in sorted(features):
        if feature:
            info = kg.get_feature_graph(feature)
            print(f"  {feature}: {info['nodes']} nodos, {info['edges']} relaciones")

    # Detectar violaciones
    print("\n" + "=" * 60)
    print("⚠️  VIOLACIONES DE ARQUITECTURA")
    print("=" * 60)
    violations = kg.detect_violations()
    if violations:
        for v in violations:
            print(f"  [{v['severity']}] {v['from']} → {v['to']}")
            print(f"           {v['rule']}")
    else:
        print("  ✅ No se detectaron violaciones")

    # Exportar
    output_dir = current_dir / "output"
    output_dir.mkdir(exist_ok=True)

    kg.export_json(str(output_dir / "graph.json"))
    kg.visualize(str(output_dir / "graph.png"))

    # Modo interactivo
    if len(sys.argv) > 1:
        command = sys.argv[1]

        if command == "search" and len(sys.argv) > 2:
            query = sys.argv[2]
            print(f"\n🔍 Búsqueda: {query}")
            results = kg.search(query)
            for r in results[:5]:  # Max 5 resultados
                print(f"\n  📄 {r['node_id']}")
                print(f"     Tipo: {r['type']} | Layer: {r['layer']} | Feature: {r['feature']}")
                if r['dependencies']:
                    print(f"     Depende de: {', '.join(r['dependencies'][:3])}")
                if r['used_by']:
                    print(f"     Usado por: {', '.join(r['used_by'][:3])}")

        elif command == "impact" and len(sys.argv) > 2:
            node_id = sys.argv[2]
            print(f"\n💥 Análisis de Impacto: {node_id}")
            impact = kg.impact_analysis(node_id)

            if "error" in impact:
                print(f"  ❌ {impact['error']}")
            else:
                print(f"\n  Nivel de riesgo: {impact['risk_level']}")
                print(f"  Componentes afectados: {impact['total_affected']}")

                if impact['direct_dependents']:
                    print(f"\n  Dependientes directos ({len(impact['direct_dependents'])}):")
                    for dep in impact['direct_dependents'][:10]:
                        print(f"    - {dep}")

                if impact['indirect_dependents']:
                    print(f"\n  Dependientes indirectos ({len(impact['indirect_dependents'])}):")
                    for dep in impact['indirect_dependents'][:10]:
                        print(f"    - {dep}")

    print("\n" + "=" * 60)
    print("✅ COMPLETADO")
    print("=" * 60)
    print(f"Archivos generados en: {output_dir}")
    print("\nComandos disponibles:")
    print("  python3 generate_graph.py search <query>")
    print("  python3 generate_graph.py impact <node_id>")
    print()


if __name__ == "__main__":
    main()
