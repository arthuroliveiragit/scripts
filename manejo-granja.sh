# script para manejo dos arquivos para o ftp
# 17/04/2023 arthur.lopes@tivit.com
#
# - define origens e destinos
# - verifica se os diretorios existem
# - compara os diretorios e copia os arquivos mais recentes para o destino
# - apaga os arquivos mais antigos no destino
# - gera log com as estatisticas



#!/bin/bash

# Definicao de variaveis de origem e destino
origem=("/root/GIT/granjalog/logs1" "/root/GIT/granjalog/logs2" "/root/GIT/granjalog/logs3")
destino=("/root/GIT/granjalog/destino1" "/root/GIT/granjalog/destino2" "/root/GIT/granjalog/destino3")


# Criacao do log de registro desse script
dir_log=/var/log
data=$(date +"%Y-%m-%d__%H:%M")
log_file=$dir_log/copy_log.log
echo "------------------------------------" >> $log_file
echo $data >> $log_file

# Acertar o for para o numero correto de diretorios
for i in {0..2}
do

        # Contadores zerados
        num_copiados=0
        num_excluidos=0
            dir_origem=`echo ${origem[i]}`
            dir_destino=`echo ${destino[i]}`
        # Verifica se os diretorios existem
        if [ ! -d $dir_origem ]; then
            echo "Diretorio de origem $dir_origem para execucao nao encontrado." >> $log_file
            exit 1
        fi
        if [ ! -d $dir_destino ]; then
            echo "Diretório de destino $dir_destino para execucao nao encontrado."  >> $log_file
            exit 1
        fi

        # Comparacao dos diretorios e copia dos arquivos
        for arquivo in $(find $dir_origem -type f -mtime -4)
        do
            nome_arquivo=$(basename $arquivo)
            arquivo_destino=$dir_destino/$nome_arquivo

            if [ ! -f $arquivo_destino ]
            then
                cp $arquivo $arquivo_destino
                echo "Arquivo $nome_arquivo copiado para $dir_destino." >> $log_file
                ((num_copiados++))
            fi
        done

        # Exclusao dos arquivos mais antigos do diretório de destino
        for arquivo in $(find $dir_destino -type f -mtime +4)
        do
            nome_arquivo=$(basename $arquivo)
            rm $arquivo
            echo "Arquivo $nome_arquivo apagado de $dir_destino." >> $log_file
            ((num_excluidos++))
        done


        # Estatisticas de copia e exclusao
        echo "Arquivos copiados: $num_copiados." >> $log_file
        echo "Arquivos excluidos: $num_excluidos." >> $log_file
        echo "---------------------" >> $log_file

done

#espaco_origem=$(df -h  /home/comptxt_commerce |grep G |awk '{print $3}')
#espaco_destino=$(df -h  /home |grep G |awk '{print $3}')
espaco_origem=$(df -h  /home |grep G |awk '{print $3}')
espaco_destino=$(df -h  /home |grep G |awk '{print $3}')
echo "Espaco livre no home do ftp: $espaco_destino" >> $log_file
echo "Espaco livre no comptxt: $espaco_origem" >> $log_file
