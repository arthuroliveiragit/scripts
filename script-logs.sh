#!/bin/bash

# Numero de dias para manter os logs
DAYS_TO_KEEP=10

# Numero de dias para considerar se há logs gerados recentemente
DAYS_TO_CHECK=1

# Caminho completo para o diretório de logs onde apagaremos os antigos
LOG_DIR=/path/to/log/directory

# Caminho completo para o arquivo de log deste script
LOG_FILE=/path/to/log/file.log

# Obter a data atual em formato Unix timestamp
CURRENT_DATE=$(date +%s)

# Verificar se o diretório de logs existe
if [ ! -d "$LOG_DIR" ]; then
    echo "Diretório de logs não encontrado."
    exit 1
fi

# Verificar se há logs gerados recentemente
#RECENT_LOGS=$(find "$LOG_DIR" -type f -name "*.log" -mtime "-$DAYS_TO_CHECK")
#if [ -n "$RECENT_LOGS" ]; then
#    echo "Existem logs gerados nos últimos $DAYS_TO_CHECK dias. Operação de exclusão cancelada."
#    exit 0
#fi

RECENT_LOGS=$(find "$LOG_DIR" -type f -name "*.log" -mtime "-$DAYS_TO_CHECK")
if [ ! -n "$RECENT_LOGS" ]; then
    echo "Não existem logs gerados em todos os últimos $DAYS_TO_CHECK dias. Operação de exclusão cancelada."
    exit 0
fi


# Obter a lista de arquivos de log no diretório
LOG_FILES=$(find "$LOG_DIR" -type f -name "*.log" -mtime +"$DAYS_TO_KEEP")

# Verificar se há arquivos de log suficientes para excluir
NUM_LOG_FILES=$(echo "$LOG_FILES" | wc -l)
if [ $NUM_LOG_FILES -lt $DAYS_TO_KEEP ]; then
    echo "Não há arquivos de log suficientes para excluir."
    exit 0
fi

# Excluir os arquivos de log encontrados
echo "$LOG_FILES" | xargs rm

# Obter a lista atualizada de arquivos de log no diretório
UPDATED_LOG_FILES=$(find "$LOG_DIR" -type f -name "*.log" -mtime +"$DAYS_TO_KEEP")

# Contar o número de arquivos de log atualizados
NUM_UPDATED_LOG_FILES=$(echo "$UPDATED_LOG_FILES" | wc -l)

# Verificar o tamanho total dos arquivos de log restantes:
LOG_FILES_SIZE=$(du -sh "$LOG_DIR")

# Registrar o resultado da operação no arquivo de log
echo "$(date) - Operação de exclusão de arquivos de log concluída." >> "$LOG_FILE"
echo "Número de arquivos de log antes da operação: $NUM_LOG_FILES." >> "$LOG_FILE"
echo "Número de arquivos de log excluídos: $(expr $NUM_LOG_FILES - $NUM_UPDATED_LOG_FILES)." >> "$LOG_FILE"
echo "Número de arquivos de log após a operação: $NUM_UPDATED_LOG_FILES." >> "$LOG_FILE"
echo "Tamanho total dos arquivos de log: $LOG_FILES_SIZE." >> "$LOG_FILE"


