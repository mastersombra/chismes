#!/bin/bash
# Script de instalación para Knowledge Graph Generator

set -e

echo "=================================================="
echo "🧠 Chismes Knowledge Graph - Instalación"
echo "=================================================="
echo

# Detectar sistema operativo
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo "🖥️  Sistema detectado: $MACHINE"
echo

# Verificar Python 3
echo "🐍 Verificando Python 3..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 no encontrado"
    echo "   Instalar desde: https://www.python.org/downloads/"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo "✅ Python $PYTHON_VERSION encontrado"
echo

# Verificar pip3
echo "📦 Verificando pip3..."
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 no encontrado"
    echo "   Instalar: curl https://bootstrap.pypa.io/get-pip.py | python3"
    exit 1
fi

echo "✅ pip3 encontrado"
echo

# Instalar dependencias
echo "📦 Instalando dependencias..."
echo

pip3 install --upgrade pip --quiet

echo "  → networkx"
pip3 install networkx --quiet

echo "  → matplotlib"
pip3 install matplotlib --quiet

echo "  → pillow"
pip3 install pillow --quiet

echo
echo "✅ Dependencias instaladas"
echo

# Crear directorio output
echo "📁 Creando directorio de salida..."
mkdir -p output
echo "✅ Directorio output/ creado"
echo

# Test rápido
echo "🧪 Ejecutando test básico..."
python3 -c "import networkx; import matplotlib.pyplot; print('✅ Imports OK')"
echo

# Make executable
chmod +x generate_graph.py

echo "=================================================="
echo "✅ INSTALACIÓN COMPLETADA"
echo "=================================================="
echo
echo "🚀 Comandos disponibles:"
echo
echo "  Generar grafo:"
echo "    python3 generate_graph.py"
echo
echo "  Buscar:"
echo "    python3 generate_graph.py search \"GossipRepository\""
echo
echo "  Análisis de impacto:"
echo "    python3 generate_graph.py impact \"features.gossip.domain.repositories.gossip_repository\""
echo
echo "📖 Ver README.md para más información"
echo
