#!/bin/bash
# arthur.lopes@tivit.com
# versao 1.0 27/03/23
# script para compactar e descartar arquivos antigos de archive, dump, logs etc
# - apaga arquivos mais antigos que x dias (DAYS_TO_KEEP)
# - compacta com gzip os arquivos restantes menos os x mais recentes (DAYS_NO_GZIP)
# - nao executa se nenhum arquivo recente for encontrado para evitar que 
# todos os arquivos acabem sendo apagados em caso de falha na criação dos arquivos
# - não executa se o diretorio a ser tratado nao existir (TARGET_DIR)
# - informa no log numeros de arquivos tratados, restantes e tamanho do diretorio


# Numero de dias para manter os arquivos
DAYS_TO_KEEP=8

# Numero de dias sem gzip (zero conta como hoje - nao compacta o arquivo de hoje)
DAYS_NO_GZIP=0

# Numero de dias para considerar se ha arquivos gerados recentemente
DAYS_TO_CHECK=1

# Caminho completo do diretorio que sera tratado
# ATENCAO - aqui ocorre gzip e rm -f
TARGET_DIR=/home/lopes/testes/teste2

# Caminho completo para o arquivo de log deste script
LOG_FILE=/home/lopes/log/file.log

# Data atual em formato Unix timestamp
CURRENT_DATE=$(date +%s)

# Verificar se o diretorio a ser tratado existe
if [ ! -d "$TARGET_DIR" ]; then
    echo "Diretório para execucao nao encontrado."
    exit 1
fi

# Guardar condicoes iniciais
FILES_SIZE=$(du -sh "$TARGET_DIR")
TOTAL_FILES=$(ls "$TARGET_DIR"|wc -l)

# Obter a data limite para logs recentes
LIMIT_DATE=$(date -d "-$DAYS_TO_CHECK days" +%s)

# Verificar se há arquivos gerados recentemente
RECENT_LOGS=$(find "$TARGET_DIR" -type f -name "*.log" -newermt "@$LIMIT_DATE" | wc -l)
if [ "$RECENT_LOGS" -eq 0 ]; then
    echo "Não há arquivos gerados nos ultimos $DAYS_TO_CHECK dias. Encerrando." >> "$LOG_FILE"
    exit 0
fi

# Obter a lista de arquivos nao compactados no diretório sem contar os mais recentes (DAYS_NO_GZIP)
# - escolher o find mais apropriado pela extensao ou negativa da extensao
#LOG_FILES=$(find "$TARGET_DIR" -type f -name "*.log" -mtime +"$DAYS_TO_KEEP" ! -name "*.gz")
LOG_FILES_TO_GZIP=$(find "$TARGET_DIR" -type f -name "*.log" -mtime +"$DAYS_NO_GZIP")

# Verificar se ha arquivos de log para compactar e executar compactacao caso positivo
NUM_LOG_FILES_TO_GZIP=$(echo "$LOG_FILES_TO_GZIP" | wc -l)
if [ $NUM_LOG_FILES_TO_GZIP -eq 0 ]; then
    echo "Não há arquivos para gzipar."
else
# compactando
    echo "$LOG_FILES_TO_GZIP" | while read -r log_file; do
       if [ -f "$log_file" ]; then
           if gzip "$log_file"; then
#               echo "$(date) - Arquivo $log_file gzipado." >> "$LOG_FILE"
               echo "$(date) - Arquivo $log_file gzipado." > /dev/null
           else
               echo "$(date) - Falha ao compactar o arquivo $log_file." >> "$LOG_FILE"
           fi
       fi       
    done
    echo "$(date) - $NUM_LOG_FILES_TO_GZIP Arquivos compactados." >> "$LOG_FILE"
#    exit 0
fi

# Obter a lista de arquivos para excluir no diretorio
FILES_TO_DELETE=$(find "$TARGET_DIR" -type f -mtime +"$DAYS_TO_KEEP")

# Verificar se ha arquivos para excluir e executar caso positivo
NUM_FILES_TO_DELETE=$(echo "$FILES_TO_DELETE" | wc -l)
if [ $NUM_FILES_TO_DELETE -eq 0 ]; then
    echo "Nao ha arquivos antigos para excluir." >> "$LOG_FILE"
else
    echo "$FILES_TO_DELETE" | while read -r log_file; do
        if [ -f "$log_file" ]; then
            if rm -f "$log_file"; then
#                echo "$(date) - Arquivo $log_file apagado." >> "$LOG_FILE"
                echo "$(date) - Arquivo $log_file apagado." > /dev/null
            else
                echo "$(date) - Falha ao apagar o arquivo $log_file." >> "$LOG_FILE"
            fi
        fi        
    done
    echo "$(date) - $NUM_FILES_TO_DELETE Arquivos apagados." >> "$LOG_FILE"
#    exit 0
fi

# Verificar o tamanho total e quantidade dos arquivos restantes:
UPDATED_FILES_SIZE=$(du -sh "$TARGET_DIR")
UPDATED_TOTAL_FILES=$(ls "$TARGET_DIR"|wc -l)

# Registrar o resultado da operação no arquivo de log
echo "$(date) - Operação de exclusão/gzip de arquivos de log concluída." >> "$LOG_FILE"
echo "Número de arquivos antes da operação: $TOTAL_FILES." >> "$LOG_FILE"
#echo "Número de arquivos excluídos: $NUM_LOG_FILES_TO_DELETE." >> "$LOG_FILE"
echo "Número de arquivos excluídos: $(expr $TOTAL_FILES - $UPDATED_TOTAL_FILES)." >> "$LOG_FILE"
echo "Número de arquivos após a operação: $UPDATED_TOTAL_FILES." >> "$LOG_FILE"
echo "Tamanho total dos arquivos antes: $FILES_SIZE." >> "$LOG_FILE"
echo "Tamanho total dos arquivos atual: $UPDATED_FILES_SIZE." >> "$LOG_FILE"
echo "--------------------------------------------------------------" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
