# Instalador Unificado de APIs

Este repositório contém um **script unificado** (`install.sh`) que permite instalar **3 diferentes APIs**:

1. **WUZAPI**  
2. **Evolution API**  
3. **CodeChat-BR**  

Cada instalação é feita dentro de uma **pasta com o nome do banco de dados** para manter tudo organizado de forma independente.

---

## Como Usar

### 1. Obter o script `install.sh`

Você pode clonar este repositório

```bash
git clone https://github.com/rafaWPP/instalador-api.git
```
```bash
cd instalador-api
```
Ou simplesmente baixar o script:

```bash
wget https://raw.githubusercontent.com/rafaWPP/instalador-api/main/install.sh
```
2. Conceder permissão de execução (caso ainda não tenha feito)
```bash
chmod +x install.sh
```
3. Executar o instalador
```bash
./install.sh
```
Passo a Passo da Instalação
Escolha a API que deseja instalar (WUZAPI, Evolution API ou CodeChat-BR).
O script perguntará as informações necessárias (nome do banco, usuário, senha, porta etc.).
Você verá um resumo dos dados digitados e confirmará.
O instalador fará todo o trabalho de download/clonagem do repositório, instalação de dependências e configuração.
Ao final, mostrará o nome do processo no PM2 e a porta em que a API estará rodando.
Estrutura de Pastas
Cada API é instalada em uma pasta com o nome do banco que você digitou.
Por exemplo, se você criar o banco wuzapidb para instalar a WUZAPI, o script criará uma pasta:

wuzapidb/
  └── wuzapi/
      └── (arquivos do projeto)
      
O mesmo vale para evolution ou codechatdb, etc.


Contribuindo
Sinta-se à vontade para abrir pull requests ou issues se tiver melhorias ou encontrar problemas.

Licença
MIT - Fique à vontade para usar, modificar e distribuir este instalador.
