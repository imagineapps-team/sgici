#!/bin/bash
# Script para criar o banco ecoenel_ce a partir de ecoenel_ce_local
#
# Uso:
#   ./scripts/setup_ecoenel_ce.sh
#
# Pré-requisitos:
#   - PostgreSQL rodando localmente
#   - Banco ecoenel_ce_local existente com dados
#   - Usuário postgres com permissão

set -e

# Configurações
DB_USER="${DATABASE_USERNAME:-postgres}"
DB_HOST="${DATABASE_HOST:-localhost}"
SOURCE_DB="ecoenel_ce_local"
TARGET_DB="ecoenel_ce"

echo "=== Setup EcoEnel CE Database ==="
echo "Source: $SOURCE_DB"
echo "Target: $TARGET_DB"
echo "Host: $DB_HOST"
echo "User: $DB_USER"
echo ""

# Verifica se o banco source existe
echo "Verificando banco de origem..."
if ! psql -h "$DB_HOST" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$SOURCE_DB"; then
    echo "ERRO: Banco '$SOURCE_DB' não encontrado!"
    exit 1
fi
echo "OK: Banco '$SOURCE_DB' encontrado."

# Verifica se o banco target já existe
echo ""
echo "Verificando banco de destino..."
if psql -h "$DB_HOST" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$TARGET_DB"; then
    echo "AVISO: Banco '$TARGET_DB' já existe!"
    read -p "Deseja dropar e recriar? (s/N): " confirm
    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        echo "Dropando banco existente..."
        dropdb -h "$DB_HOST" -U "$DB_USER" "$TARGET_DB"
    else
        echo "Operação cancelada."
        exit 0
    fi
fi

# Cria o banco target
echo ""
echo "Criando banco '$TARGET_DB'..."
createdb -h "$DB_HOST" -U "$DB_USER" "$TARGET_DB"

# Faz o dump e restore
echo ""
echo "Copiando dados de '$SOURCE_DB' para '$TARGET_DB'..."
pg_dump -h "$DB_HOST" -U "$DB_USER" "$SOURCE_DB" | psql -h "$DB_HOST" -U "$DB_USER" "$TARGET_DB"

echo ""
echo "=== Concluído! ==="
echo "Banco '$TARGET_DB' criado com sucesso a partir de '$SOURCE_DB'."
echo ""
echo "Para verificar, execute:"
echo "  psql -h $DB_HOST -U $DB_USER -d $TARGET_DB -c 'SELECT COUNT(*) FROM usuarios;'"
