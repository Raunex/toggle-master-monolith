# 12-Factor App no ToggleMaster

Leitura do código desta fase (`app.py`, `Dockerfile`, `entrypoint.sh`, `docker-compose.yaml`, `requirements.txt`) contra os [12 fatores](https://12factor.net/). A coluna **Situação** diz o que o repositório já faz. A coluna **Ajuste para produção** diz o que falta para um ambiente mais robusto.

| # | Fator | Situação | Ajuste para produção |
|---|---|---|---|
| 1 | Codebase | Um repositório acompanha o monolito. O deploy local e o da EC2 nascem do mesmo código. | Manter um único repositório enquanto a aplicação for um processo só. |
| 2 | Dependencies | `requirements.txt` fixa Flask, Werkzeug, psycopg2-binary e gunicorn. A imagem Docker instala essa lista. | Na EC2, instalar sempre dentro do `venv` a partir desse arquivo, sem pacote solto no sistema. |
| 3 | Config | Host, nome, usuário e senha do banco vêm de variável de ambiente. O Compose local e a EC2 usam os mesmos nomes. | A porta `5000` está fixa no `app.py`, no `Dockerfile` e no `entrypoint.sh`. `DB_PORT` é exigida pelo entrypoint e ignorada pelo `psycopg2`, que usa 5432. Levar porta da API e porta do banco para o ambiente. |
| 4 | Backing services | O Postgres é um recurso anexado. Trocar o host de `db` (Compose) para o endpoint do RDS não muda código. | Tratar o RDS como recurso substituível: endpoint, banco e usuário só no ambiente da EC2. |
| 5 | Build, release, run | A imagem Docker separa build (`pip install`) de execução (`gunicorn`). | O guia da EC2 instala dependências na máquina no momento do deploy. Isso mistura build e run. O caminho alinhado ao fator é publicar a imagem já construída e só injetar config na subida. |
| 6 | Processes | O estado das flags fica na tabela `flags`. O processo da API não guarda flag em memória. | Manter a API sem estado local para poder trocar a instância sem perder dado. |
| 7 | Port binding | O Gunicorn escuta em `0.0.0.0:5000` e exporta HTTP. O serviço é acessível pelo IP da EC2 sem um servidor web externo. | Documentar a porta no security group (`sg-ec2` libera 5000). |
| 8 | Concurrency | O comando de subida não define workers. O processo atende no modelo padrão de um worker. | Escalar por processo (mais workers ou mais EC2) atrás de um balanceador, quando o MVP passar da validação. |
| 9 | Disposability | O entrypoint espera o banco antes de servir, o que evita subir a API cedo demais. | O Gunicorn em foreground morre com a sessão SSH. Um unit `systemd` (ou o container com política de restart) sobe de novo sozinho e encerra com SIGTERM. |
| 10 | Dev/prod parity | Os dois lados usam Python 3, Flask, Gunicorn e Postgres, e a mesma lista de variáveis `DB_*`. | Local sobe API e Postgres no Compose. A entrega sobe Python direto na EC2 e RDS gerenciado. Aproximar os dois usando a mesma imagem nos dois ambientes. |
| 11 | Logs | Mensagens do entrypoint e do Flask saem em stdout/stderr. | Tratar essa saída como stream: journald na EC2 ou o driver de log do container. |
| 12 | Admin processes | `flask init-db` cria a tabela `flags` (`CREATE TABLE IF NOT EXISTS`) como comando separado, chamado pelo entrypoint quando o banco fica pronto. | Rodar a migração como tarefa única, antes de abrir o processo para tráfego. |

## O que a fase já aproveita

Config do banco fora do código, Postgres como backing service, dependências declaradas e HTTP na porta do próprio processo. Isso é o suficiente para o deploy da EC2 falar com o RDS sem alterar `app.py`.

## O que a documentação de produção precisa assumir

Porta e demais parâmetros só por ambiente, artefato construído uma vez e executado depois, processo que sobrevive ao logout e log só em stdout. O diagrama em [arquitetura.md](arquitetura.md) já separa computação e banco. Os quatro pontos acima são o passo seguinte dentro dessa mesma arquitetura.
