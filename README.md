# Instalador Unificado de APIs

Este repositório contém um **script unificado** (`install.sh`) que permite instalar **3 diferentes APIs**:

1. **WUZAPI**  
2. **Evolution API**  
3. **CodeChat-BR**  

Cada instalação é feita dentro de uma **pasta com o nome do banco de dados** para manter tudo organizado de forma independente.

---

## Como Usar

### 1. Obter o script `install.sh`

Você pode clonar este repositório ou apenas baixar o script diretamente.  
Para clonar:

```bash
git clone https://github.com/rafaWPP/instalador-api.git
cd instalador-api
Ou simplesmente baixar o script:

bash
Copiar
Editar
wget https://raw.githubusercontent.com/rafaWPP/instalador-api/main/install.sh
chmod +x install.sh
2. Conceder permissão de execução (caso ainda não tenha feito)
bash
Copiar
Editar
chmod +x install.sh
3. Executar o instalador
bash
Copiar
Editar
./install.sh
Passo a Passo da Instalação
Escolha a API que deseja instalar (WUZAPI, Evolution API ou CodeChat-BR).
O script perguntará as informações necessárias (nome do banco, usuário, senha, porta etc.).
Você verá um resumo dos dados digitados e confirmará.
O instalador fará todo o trabalho de download/clonagem do repositório, instalação de dependências e configuração.
Ao final, mostrará o nome do processo no PM2 e a porta em que a API estará rodando.
Estrutura de Pastas
Cada API é instalada em uma pasta com o nome do banco que você digitou.
Por exemplo, se você criar o banco wuzapidb para instalar a WUZAPI, o script criará uma pasta:

arduino
Copiar
Editar
wuzapidb/
  └── wuzapi/
      └── (arquivos do projeto)
O mesmo vale para evolution ou codechatdb, etc.

Exemplos de Execução
Instalar WUZAPI
bash
Copiar
Editar
./install.sh
scss
Copiar
Editar
Qual API você deseja instalar?
1) WUZAPI
2) Evolution API
3) CodeChat-BR

Escolha uma opção (1, 2 ou 3): 1
Em seguida, preencha:
Nome do banco (ex: wuzapidb)
Usuário (ex: wuzapi)
Senha (ex: senha123)
Porta (ex: 8080)
Nome do processo no PM2 (ex: wuzapi)
Token de administrador (ex: ABCD1234)
Instalar Evolution API
bash
Copiar
Editar
./install.sh
scss
Copiar
Editar
Qual API você deseja instalar?
1) WUZAPI
2) Evolution API
3) CodeChat-BR

Escolha uma opção (1, 2 ou 3): 2
Preencha:
Nome do banco (ex: evolution)
Usuário BD (ex: evolution)
Senha BD (ex: senha123)
Porta (ex: 3000)
Nome PM2 (ex: evolution-api)
Instalar CodeChat-BR
bash
Copiar
Editar
./install.sh
scss
Copiar
Editar
Qual API você deseja instalar?
1) WUZAPI
2) Evolution API
3) CodeChat-BR

Escolha uma opção (1, 2 ou 3): 3
Preencha:
Nome do banco (ex: codechatdb)
Usuário BD (ex: codechat)
Senha BD (ex: senha123)
Porta (ex: 8083)
Nome PM2 (ex: CodeChat_API_v1.3.0)
Observações Importantes
Requisitos:

Ubuntu/Debian (ou outro compatível).
Acesso sudo.
Internet (para baixar dependências e clonar os repositórios).
PM2:

O script instala e configura o PM2 para iniciar no boot (pm2 startup + pm2 save).
Você pode verificar os processos rodando com pm2 list.
Banco de Dados:

O PostgreSQL é instalado e configurado se não estiver presente.
Cada API cria seu próprio banco (com o nome que você informou).
O schema public é transferido para o usuário e recebe permissões para evitar erros de permissão.
Segurança:

O script cria usuário do banco com a senha que você digitar.
Se já existir, ele não recria (apenas confirma se existe ou não).
Se precisar trocar a senha, você pode fazê-lo manualmente no PostgreSQL.
Contribuindo
Sinta-se à vontade para abrir pull requests ou issues se tiver melhorias ou encontrar problemas.

Licença
MIT - Fique à vontade para usar, modificar e distribuir este instalador.