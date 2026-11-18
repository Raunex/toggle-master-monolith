#!/bin/sh
set -eu

# O que este script faz:
# 1. Checa as variáveis de ambiente para o banco de dados.
# 2. Entra em um loop que tenta se conectar ao banco de dados.
# 3. Só sai do loop quando o banco de dados está pronto para aceitar conexões.
# 4. Executa o comando de inicialização do banco de dados.
# 5. Inicia o servidor Gunicorn.

# Verifique se as variáveis de ambiente do banco de dados estão definidas
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_NAME" ]; then
  echo "Erro: As variáveis de ambiente do banco de dados (DB_HOST, DB_PORT, DB_NAME) devem ser definidas."
  exit 1
fi

echo "Aguardando o banco de dados em ${DB_HOST}:${DB_PORT}..."

# Aguarda o banco de dados ficar disponível (loop e timeout em wait_for_db.py).
# Se o banco não subir dentro de DB_WAIT_TIMEOUT, o script falha e o `set -e`
# encerra o container.
python wait_for_db.py

echo "Banco de dados disponível!"

# Executa o comando de inicialização/migração do banco de dados (se existir)
if command -v flask >/dev/null 2>&1; then
  echo "Executando a inicialização do banco de dados..."
  flask init-db || true
fi

# Inicia a aplicação principal (Gunicorn)
echo "Iniciando o servidor Gunicorn..."
exec gunicorn --bind 0.0.0.0:5000 app:app