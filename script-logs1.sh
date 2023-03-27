#!/bin/bash

# Numero de dias para manter os arquivos
DAYS_TO_KEEP=8

# Numero de dias sem gzip (zero conta como 1)
DAYS_NO_GZIP=0

# Numero de dias para considerar se ha logs gerados recentemente
DAYS_TO_CHECK=1

# Definir o caminho completo para o diretório de logs
LOG_DIR=/home/lopes/testes/teste2

# Definir o caminho completo para o arquivo de log deste script
LOG_FILE=/home/lopes/log/file.log

# Obter a data atual em formato Unix timestamp
CURRENT_DATE=$(date +%s)

# Verificar se o diretório de logs existe
if [ ! -d "$LOG_DIR" ]; then
    echo "Diretório de logs não encontrado."
    exit 1
fi

# Verificar condicoes iniciais
LOG_FILES_SIZE=$(du -sh "$LOG_DIR")
TOTAL_FILES=$(ls "$LOG_DIR"|wc -l)

# Obter a data limite para logs recentes
LIMIT_DATE=$(date -d "-$DAYS_TO_CHECK days" +%s)

# Verificar se há logs gerados recentemente
RECENT_LOGS=$(find "$LOG_DIR" -type f -name "*.log" -newermt "@$LIMIT_DATE" | wc -l)
if [ "$RECENT_LOGS" -eq 0 ]; then
    echo "Não há arquivos gerados nos ultimos $DAYS_TO_CHECK dias. Encerrando." >> "$LOG_FILE"
    exit 0
fi

# Obter a lista de arquivos de log no diretório com mais de X dias e não gzipados
#LOG_FILES=$(find "$LOG_DIR" -type f -name "*.log" -mtime +"$DAYS_TO_KEEP" ! -name "*.gz")
LOG_FILES_TO_GZIP=$(find "$LOG_DIR" -type f -name "*.log" -mtime +"$DAYS_NO_GZIP")

# Verificar se há arquivos de log suficientes para gzipar
NUM_LOG_FILES=$(echo "$LOG_FILES_TO_GZIP" | wc -l)
if [ $NUM_LOG_FILES -eq 0 ]; then
    echo "Não há arquivos para gzipar."
else
# gzipando
    echo "$LOG_FILES_TO_GZIP" | while read -r log_file; do
       if [ -f "$log_file" ]; then
           if gzip "$log_file"; then
               echo "$(date) - Arquivo $log_file gzipado." >> "$LOG_FILE"
           else
               echo "$(date) - Falha ao gzipar o arquivo $log_file." >> "$LOG_FILE"
           fi
       fi
    done
#    exit 0
fi

# Obter a lista de arquivos de log ipara excluir no diretório
LOG_FILES_TO_DELETE=$(find "$LOG_DIR" -type f -mtime +"$DAYS_TO_KEEP")

# Verificar se há arquivos de log suficientes para excluir
NUM_LOG_FILES_TO_DELETE=$(echo "$LOG_FILES_TO_DELETE" | wc -l)
if [ $NUM_LOG_FILES_TO_DELETE -eq 0 ]; then
    echo "Nao ha arquivos antigos para excluir." >> "$LOG_FILE"
else
    echo "$LOG_FILES_TO_DELETE" | while read -r log_file; do
        if [ -f "$log_file" ]; then
            if rm -f "$log_file"; then
                echo "$(date) - Arquivo $log_file apagado." >> "$LOG_FILE"
            else
                echo "$(date) - Falha ao apagar o arquivo $log_file." >> "$LOG_FILE"
            fi
        fi
    done

#    exit 0
fi

# Obter a lista atualizada de arquivos de log no diretório
#UPDATED_LOG_FILES=$(find "$LOG_DIR" -type f -name "*.log" -mtime +"$DAYS_TO_KEEP" ! -name "*.gz")
UPDATED_LOG_FILES=$(ls)

# Contar o número de arquivos de log atualizados
NUM_UPDATED_LOG_FILES=$(echo "$UPDATED_LOG_FILES" | wc -l)

# Verificar o tamanho total dos arquivos de log restantes:
UPDATED_LOG_FILES_SIZE=$(du -sh "$LOG_DIR")
UPDATED_TOTAL_FILES=$(ls "$LOG_DIR"|wc -l)

# Registrar o resultado da operação no arquivo de log
echo "$(date) - Operação de exclusão/gzip de arquivos de log concluída." >> "$LOG_FILE"
echo "Número de arquivos antes da operação: $TOTAL_FILES." >> "$LOG_FILE"
#echo "Número de arquivos excluídos: $NUM_LOG_FILES_TO_DELETE." >> "$LOG_FILE"
echo "Número de arquivos excluídos: $(expr $TOTAL_FILES - $UPDATED_TOTAL_FILES)." >> "$LOG_FILE"
echo "Número de arquivos após a operação: $UPDATED_TOTAL_FILES." >> "$LOG_FILE"
echo "Tamanho total dos arquivos antes: $LOG_FILES_SIZE." >> "$LOG_FILE"
echo "Tamanho total dos arquivos atual: $UPDATED_LOG_FILES_SIZE." >> "$LOG_FILE"
echo "--------------------------------------------------------------" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
