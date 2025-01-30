#!/bin/bash

# =================================================
# =            INSTALADOR UNIFICADO              =
# =  1) WUZAPI | 2) Evolution API | 3) CodeChat   =
# =   Cada projeto clonado em pasta do DB_NAME   =
# =     chmod +x install.sh && ./install.sh       =
# =================================================

# -------------- ESTILIZAÇÃO (CORES) --------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
WHITE='\033[1;37m'
NC='\033[0m' # Sem cor

# -------------- FUNÇÕES AUXILIARES --------------
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

get_input() {
    local prompt=$1
    local input=""
    while [[ -z "$input" ]]; do
        read -p "$(echo -e "${YELLOW}$prompt${NC}: ")" input
        if [[ -z "$input" ]]; then
            echo -e "${RED}Esse campo é obrigatório. Por favor, preencha.${NC}"
        fi
    done
    echo "$input"
}

show_header() {
    clear
    echo -e "${CYAN}==============================================${NC}"
    echo -e "${CYAN}              ${WHITE}WEBTECH INSTALADOR      ${CYAN}${NC}"
    echo -e "${CYAN}==============================================${NC}"
}

show_section() {
    clear
    show_header
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

install_basic_dependencies() {
    show_section "Atualizando sistema e instalando dependências"
    sudo apt update -y && sudo apt upgrade -y
    sudo apt install -y curl wget build-essential git
}

# -------------- FLUXO DE INSTALAÇÃO WUZAPI --------------
install_wuzapi() {
    show_section "Coletando Dados para Instalação do WUZAPI"
    local SERVER_IP=$(hostname -I | awk '{print $1}')
    local DB_USER DB_PASSWORD DB_NAME APP_PORT PM2_NAME WUZAPI_ADMIN_TOKEN
    local confirm="n"

    while [[ "$confirm" != "s" && "$confirm" != "S" && "$confirm" != "y" && "$confirm" != "Y" ]]; do
        DB_NAME=$(get_input "Nome do banco de dados (ex: wuzapidb)")
        DB_USER=$(get_input "Nome do usuário do banco (ex: wuzapi)")
        DB_PASSWORD=$(get_input "Senha do usuário do banco (ex: senha123)")
        APP_PORT=$(get_input "Porta para a aplicação (ex: 8080)")
        PM2_NAME=$(get_input "Nome do processo PM2 (ex: wuzapi)")
        WUZAPI_ADMIN_TOKEN=$(get_input "Token de administrador (ex: ABCD1234)")

        echo -e "\n${YELLOW}--- RESUMO DA CONFIGURAÇÃO (WUZAPI) ---${NC}"
        echo -e "${CYAN}Servidor (IP):${NC} $SERVER_IP"
        echo -e "${CYAN}DB_NAME:${NC} $DB_NAME"
        echo -e "${CYAN}DB_USER:${NC} $DB_USER"
        echo -e "${CYAN}DB_PASS:${NC} $DB_PASSWORD"
        echo -e "${CYAN}Porta App:${NC} $APP_PORT"
        echo -e "${CYAN}Nome PM2:${NC} $PM2_NAME"
        echo -e "${CYAN}Token Admin:${NC} $WUZAPI_ADMIN_TOKEN"
        echo -e "${YELLOW}URL de Acesso: http://$SERVER_IP:$APP_PORT${NC}\n"

        read -p "$(echo -e "${GREEN}Os dados estão corretos? (s/n)${NC}: ")" confirm
        confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    done

    # Instalar Node.js e npm
    show_section "Instalando Node.js e npm (WUZAPI)"
    if ! command_exists node; then
        sudo apt install -y nodejs npm
    else
        echo -e "${GREEN}Node.js já está instalado.${NC}"
    fi

    # Instalar PM2
    show_section "Instalando PM2 (WUZAPI)"
    if ! command_exists pm2; then
        sudo npm install -g pm2
    else
        echo -e "${GREEN}PM2 já está instalado.${NC}"
    fi

    # Instalar Go
    show_section "Instalando Go (WUZAPI)"
    if ! command_exists go; then
        local GO_VERSION="1.23.3"
        wget -q https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz
        rm go$GO_VERSION.linux-amd64.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
            echo 'export GOPATH=$HOME/go' >> ~/.bashrc
            echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
        fi
        source ~/.bashrc
    else
        echo -e "${GREEN}Go já está instalado.${NC}"
    fi

    # Instalar PostgreSQL
    show_section "Instalando PostgreSQL (WUZAPI)"
    if ! command_exists psql; then
        sudo apt install -y postgresql postgresql-contrib
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
    else
        echo -e "${GREEN}PostgreSQL já está instalado.${NC}"
    fi

    # Configura Banco
    show_section "Configurando Banco de Dados (WUZAPI)"
    sudo -u postgres psql <<EOF
DO
\$do\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN
      CREATE ROLE "$DB_USER" LOGIN PASSWORD '$DB_PASSWORD';
   END IF;
END
\$do\$;

CREATE DATABASE "$DB_NAME" OWNER "$DB_USER";
EOF

    sudo -u postgres psql <<EOF
ALTER SCHEMA public OWNER TO "$DB_USER";
GRANT CREATE, USAGE ON SCHEMA public TO "$DB_USER";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "$DB_USER";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "$DB_USER";
EOF

    # Clonar repositório na pasta com nome do DB
    show_section "Clonando Repositório (WUZAPI)"
    mkdir -p "$DB_NAME"
    cd "$DB_NAME"
    if [ ! -d "./wuzapi" ]; then
        git clone https://github.com/guilhermejansen/wuzapi.git
    else
        echo -e "${GREEN}Repositório wuzapi já clonado. Atualizando...${NC}"
        cd wuzapi
        git pull
        cd ..
    fi

    cd wuzapi || exit

    # Criar .env
    show_section "Criando arquivo .env (WUZAPI)"
    cat > .env <<EOL
WUZAPI_ADMIN_TOKEN=$WUZAPI_ADMIN_TOKEN
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
DB_HOST=localhost
DB_PORT=5432
PORT=$APP_PORT
EOL

    echo -e "${GREEN}Arquivo .env do WUZAPI criado:${NC}"
    cat .env

    # Compilar
    show_section "Compilando WUZAPI"
    go build .

    # PM2
    show_section "Iniciando PM2 (WUZAPI)"
    pm2 start "./wuzapi -port $APP_PORT" --name "$PM2_NAME"
    pm2 startup
    pm2 save

    show_section "Instalação Concluída (WUZAPI)!"
    echo -e "${GREEN}WUZAPI rodando na porta: ${CYAN}$APP_PORT${NC}, processo PM2: ${CYAN}$PM2_NAME${NC}.${NC}"
    echo -e "${GREEN}Token de Admin:${NC} $WUZAPI_ADMIN_TOKEN"
    echo -e "${GREEN}Acesse:${NC} http://$SERVER_IP:$APP_PORT"
    echo -e "${GREEN}Use:${NC} pm2 list${GREEN} para verificar.${NC}"
}

# -------------- FLUXO DE INSTALAÇÃO EVOLUTION API --------------
install_evolution() {
    show_section "Coletando Dados para Instalação da Evolution API"
    local SERVER_IP=$(hostname -I | awk '{print $1}')
    local EV_DB_NAME DB_USER DB_PASS EV_API_PORT EV_PM2_NAME
    local confirm="n"

    while [[ "$confirm" != "s" && "$confirm" != "S" && "$confirm" != "y" && "$confirm" != "Y" ]]; do
        EV_DB_NAME=$(get_input "Nome do banco de dados p/ Evolution (ex: evolution)")
        DB_USER=$(get_input "Usuário do BD (ex: evolution)")
        DB_PASS=$(get_input "Senha do BD (ex: senha123)")
        EV_API_PORT=$(get_input "Porta p/ Evolution API (ex: 3000)")
        EV_PM2_NAME=$(get_input "Nome do processo Evolution no PM2 (ex: evolution-api)")

        echo -e "\n${YELLOW}--- RESUMO DA CONFIGURAÇÃO (EVOLUTION) ---${NC}"
        echo -e "${CYAN}Servidor (IP):${NC} $SERVER_IP"
        echo -e "${CYAN}Banco de dados:${NC} $EV_DB_NAME"
        echo -e "${CYAN}Usuário BD:${NC} $DB_USER"
        echo -e "${CYAN}Senha BD:${NC} $DB_PASS"
        echo -e "${CYAN}Porta App (SERVER_PORT):${NC} $EV_API_PORT"
        echo -e "${CYAN}Nome PM2:${NC} $EV_PM2_NAME"
        echo -e "${YELLOW}URL de Acesso: http://$SERVER_IP:$EV_API_PORT${NC}\n"

        read -p "$(echo -e "${GREEN}Os dados estão corretos? (s/n)${NC}: ")" confirm
        confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    done

    # Instalar PostgreSQL e Redis
    show_section "Instalando PostgreSQL e Redis (Evolution API)"
    if ! command_exists psql; then
        sudo apt install -y postgresql postgresql-contrib
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
    else
        echo -e "${GREEN}PostgreSQL já está instalado.${NC}"
    fi

    if ! command_exists redis-server; then
        sudo apt install -y redis-server
        sudo systemctl start redis-server
        sudo systemctl enable redis-server
    else
        echo -e "${GREEN}Redis já está instalado.${NC}"
    fi

    # Banco
    show_section "Configurando Banco de Dados (Evolution API)"
    sudo -u postgres createdb "$EV_DB_NAME" 2>/dev/null || echo -e "${YELLOW}Banco '${EV_DB_NAME}' já existe ou erro.${NC}"

    sudo -u postgres psql <<EOF
DO
\$do\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN
       CREATE ROLE "$DB_USER" LOGIN PASSWORD '$DB_PASS';
    END IF;
END
\$do\$;

ALTER DATABASE "$EV_DB_NAME" OWNER TO "$DB_USER";
EOF

    sudo -u postgres psql <<EOF
ALTER SCHEMA public OWNER TO "$DB_USER";
GRANT CREATE, USAGE ON SCHEMA public TO "$DB_USER";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "$DB_USER";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "$DB_USER";
EOF

  # Instalar Node.js e npm
    show_section "Instalando Node.js e npm (Evolution API)"
    if ! command_exists node; then
        sudo apt install -y nodejs npm
    else
        echo -e "${GREEN}Node.js já está instalado.${NC}"
    fi

     # Instalar PM2
    show_section "Instalando PM2 (Evolution API)"
    if ! command_exists pm2; then
        sudo npm install -g pm2
    else
        echo -e "${GREEN}PM2 já está instalado.${NC}"
    fi

    # Clonar repositório na pasta do DB_NAME
    show_section "Clonando Evolution API (branch v2.0.0)"
    mkdir -p "$EV_DB_NAME"
    cd "$EV_DB_NAME"
    if [ ! -d "./evolution-api" ]; then
        git clone https://github.com/EvolutionAPI/evolution-api.git
    else
        echo -e "${GREEN}Repositório evolution-api já existe. Atualizando...${NC}"
        cd evolution-api
        git pull
        cd ..
    fi

    cd evolution-api || exit

    # Instalar dependências
    show_section "Instalando Dependências (Evolution API)"
    npm install

    # .env
    show_section "Criando/Atualizando .env (Evolution API)"
    local DB_URI="postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${EV_DB_NAME}?schema=public"
    if [ ! -f ".env" ]; then
        cp .env.example .env
    fi

    sed -i "s|^DATABASE_CONNECTION_URI=.*|DATABASE_CONNECTION_URI=${DB_URI}|" .env
    sed -i "s|^DATABASE_PROVIDER=.*|DATABASE_PROVIDER=postgresql|" .env
    sed -i "s|^DATABASE_ENABLED=.*|DATABASE_ENABLED=true|" .env

    if ! grep -q '^SERVER_PORT=' .env; then
        echo "SERVER_PORT=3000" >> .env
    fi
    sed -i "s|^SERVER_PORT=.*|SERVER_PORT=${EV_API_PORT}|" .env

    echo -e "${GREEN}Arquivo .env final (Evolution API):${NC}"
    grep -E 'SERVER_PORT|DATABASE_' .env

    # Migrations & build
    show_section "Rodando Migrations e Build (Evolution API)"
    npm run db:generate
    npm run db:deploy
    npm run build

    pm2 start "npm run start:prod" --name "$EV_PM2_NAME"
    pm2 startup
    pm2 save --force

    show_section "Instalação da Evolution API Concluída!"
    echo -e "${GREEN}Rodando na porta: ${CYAN}$EV_API_PORT${NC}, processo PM2: ${CYAN}$EV_PM2_NAME${NC}.${NC}"
    echo -e "${GREEN}Acesse:${NC} http://$SERVER_IP:$EV_API_PORT"
    echo -e "${GREEN}Use:${NC} pm2 list${GREEN} para verificar.${NC}"
}

# -------------- FLUXO DE INSTALAÇÃO CODECHAT-BR --------------
install_codechat() {
    show_section "Coletando Dados para Instalação do CodeChat-BR"
    local SERVER_IP=$(hostname -I | awk '{print $1}')
    local DB_NAME DB_USER DB_PASS SERVER_PORT PM2_NAME
    local confirm="n"

    while [[ "$confirm" != "s" && "$confirm" != "S" && "$confirm" != "y" && "$confirm" != "Y" ]]; do
        DB_NAME=$(get_input "Nome do banco de dados p/ CodeChat-BR (ex: codechatdb)")
        DB_USER=$(get_input "Usuário do BD (ex: codechat)")
        DB_PASS=$(get_input "Senha do BD (ex: senha123)")
        SERVER_PORT=$(get_input "Porta do servidor CodeChat-BR (ex: 8083)")
        PM2_NAME=$(get_input "Nome do processo no PM2 (ex: CodeChat_API_v1.3.0)")

        echo -e "\n${YELLOW}--- RESUMO DA CONFIGURAÇÃO (CODECHAT-BR) ---${NC}"
        echo -e "${CYAN}Servidor (IP):${NC} $SERVER_IP"
        echo -e "${CYAN}DB_NAME:${NC} $DB_NAME"
        echo -e "${CYAN}DB_USER:${NC} $DB_USER"
        echo -e "${CYAN}DB_PASS:${NC} $DB_PASS"
        echo -e "${CYAN}SERVER_PORT:${NC} $SERVER_PORT"
        echo -e "${CYAN}Nome PM2:${NC} $PM2_NAME"
        echo -e "${YELLOW}URL de Acesso: http://$SERVER_IP:$SERVER_PORT${NC}\n"

        read -p "$(echo -e "${GREEN}Os dados estão corretos? (s/n)${NC}: ")" confirm
        confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    done

    # Monta a URL
    local DATABASE_URL="postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}?schema=public"

    # Instalar Node.js e npm
    show_section "Instalando Node.js e npm (CodeCaht)"
    if ! command_exists node; then
        sudo apt install -y nodejs npm
    else
        echo -e "${GREEN}Node.js já está instalado.${NC}"
    fi

   # Instalar PM2
    show_section "Instalando PM2 (CodeChat-BR)"
    if ! command_exists pm2; then
        sudo npm install -g pm2
    else
        echo -e "${GREEN}PM2 já está instalado.${NC}"
    fi

    # Criar BD e Usuário
    show_section "Configurando Banco de Dados (CodeChat-BR)"
    sudo apt install -y postgresql postgresql-contrib > /dev/null 2>&1 || true
    sudo systemctl start postgresql
    sudo systemctl enable postgresql

    sudo -u postgres psql <<EOF
DO
\$do\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN
      CREATE ROLE "$DB_USER" LOGIN PASSWORD '$DB_PASS';
   END IF;
END
\$do\$;

CREATE DATABASE "$DB_NAME" OWNER "$DB_USER";

ALTER SCHEMA public OWNER TO "$DB_USER";
GRANT CREATE, USAGE ON SCHEMA public TO "$DB_USER";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "$DB_USER";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "$DB_USER";
EOF

    # Clonar repositório na pasta com nome do DB
    show_section "Clonando Repositório CodeChat-BR"
    mkdir -p "$DB_NAME"
    cd "$DB_NAME"
    if [ ! -d "./whatsapp-api" ]; then
        git clone https://github.com/code-chat-br/whatsapp-api.git
    else
        echo -e "${GREEN}Repositório code-chat-br/whatsapp-api já existe. Atualizando...${NC}"
        cd whatsapp-api
        git pull
        cd ..
    fi

    cd whatsapp-api || exit

    # Instalar dependências
    show_section "Instalando dependências (CodeChat-BR)"
    npm install --force

    # Copiar .env.dev -> .env
    show_section "Configurando arquivo .env (CodeChat-BR)"
    if [ ! -f ".env" ]; then
        cp .env.dev .env
    fi

    # Ajustar variáveis
    if ! grep -q '^DATABASE_PROVIDER=' .env; then
        echo "DATABASE_PROVIDER=postgresql" >> .env
    else
        sed -i "s|^DATABASE_PROVIDER=.*|DATABASE_PROVIDER=postgresql|" .env
    fi

    if ! grep -q '^DATABASE_URL=' .env; then
        echo "DATABASE_URL=$DATABASE_URL" >> .env
    else
        sed -i "s|^DATABASE_URL=.*|DATABASE_URL=$DATABASE_URL|" .env
    fi

    if ! grep -q '^SERVER_PORT=' .env; then
        echo "SERVER_PORT=8083" >> .env
    fi
    sed -i "s|^SERVER_PORT=.*|SERVER_PORT=$SERVER_PORT|" .env

    # Worker desabilitado
    if ! grep -q '^PROVIDER_ENABLED=' .env; then
        echo "PROVIDER_ENABLED=false" >> .env
    else
        sed -i "s|^PROVIDER_ENABLED=.*|PROVIDER_ENABLED=false|" .env
    fi

    echo -e "${GREEN}Arquivo .env final (CodeChat-BR):${NC}"
    grep -E 'DATABASE_PROVIDER|DATABASE_URL|SERVER_PORT|PROVIDER_ENABLED' .env

    # Prisma migrate deploy
    show_section "Rodando Migrations (Prisma) (CodeChat-BR)"
    npx prisma migrate deploy

    # PM2 start
    show_section "Iniciando CodeChat-BR com PM2"
    pm2 start "npm run start:prod" --name "$PM2_NAME"
    pm2 startup
    pm2 save

    show_section "Instalação CodeChat-BR Concluída!"
    echo -e "${GREEN}Rodando na porta: ${CYAN}$SERVER_PORT${NC}, processo PM2: ${CYAN}$PM2_NAME${NC}.${NC}"
    echo -e "${GREEN}Acesse:${NC} http://$SERVER_IP:$SERVER_PORT"
    echo -e "${GREEN}Use:${NC} pm2 list${GREEN} para verificar.${NC}"
}


# -------------- INÍCIO DO SCRIPT --------------
show_header

echo -e "${WHITE}Qual API você deseja instalar?${NC}"
echo "1) WUZAPI"
echo "2) Evolution API"
echo "3) CodeChat-BR"
echo -en "\nEscolha uma opção (1, 2 ou 3): "
read API_CHOICE

install_basic_dependencies

case "$API_CHOICE" in
    1)
        install_wuzapi
        ;;
    2)
        install_evolution
        ;;
    3)
        install_codechat
        ;;
    *)
        echo -e "${RED}Opção inválida! Encerrando...${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}Processo de instalação finalizado!${NC}"
