# 📊 LogAnalyzer

> Sistema de filtragem e análise de logs de acesso web utilizando o paradigma funcional em Haskell.

![Haskell](https://img.shields.io/badge/Haskell-5D4F85?style=for-the-badge&logo=haskell&logoColor=white)
![Cabal](https://img.shields.io/badge/Cabal-3.14-blue?style=for-the-badge)
![License](https://img.shields.io/badge/License-BSD--3--Clause-green?style=for-the-badge)

---

## 📝 Sumário

- [Sobre o Projeto](#-sobre-o-projeto)
- [Funcionalidades](#-funcionalidades)
- [Arquitetura e Conceitos Funcionais](#-arquitetura-e-conceitos-funcionais)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Pré-requisitos e Instalação do Haskell](#-pré-requisitos-e-instalação-do-haskell)
- [Dataset](#-dataset)
- [Como Compilar e Executar](#-como-compilar-e-executar)
- [Testes](#-testes)
- [Exemplo de Saída](#-exemplo-de-saída)
- [Tecnologias Utilizadas](#-tecnologias-utilizadas)
- [Licença](#-licença)
- [Autor](#-autor)

---

## 💡 Sobre o Projeto

O **LogAnalyzer** é uma aplicação de linha de comando desenvolvida em **Haskell** que processa e analisa arquivos de log de servidores web. O projeto demonstra na prática os princípios do **paradigma funcional** — imutabilidade, funções puras, composição de funções e avaliação estrita — aplicados a um problema real de engenharia de dados.

A aplicação lê um dataset de logs de acesso, realiza o _parsing_ de cada linha em uma estrutura de dados imutável (`LogEntry`), e produz um conjunto abrangente de métricas agregadas (`LogMetrics`) que permitem identificar padrões de tráfego, erros, consumo de banda e acessos suspeitos.

---

## 🚀 Funcionalidades

O LogAnalyzer calcula **8 métricas** a partir do arquivo de log:

| #  | Métrica                              | Descrição                                                                 |
|----|--------------------------------------|---------------------------------------------------------------------------|
| 1  | **Top 10 IPs com Erros**             | IPs que mais geraram respostas com status HTTP ≥ 400                      |
| 2  | **Top 10 Endpoints Mais Acessados**  | Rotas/URLs com maior volume de requisições                                |
| 3  | **Consumo Total de Banda**           | Soma de todos os bytes trafegados, convertida para MB                     |
| 4  | **Distribuição de Métodos HTTP**     | Contagem de requisições por método (GET, POST, PUT, DELETE, etc.)         |
| 5  | **Top 10 Endpoints 404**             | Rotas que mais retornaram _Not Found_ (erro 404)                          |
| 6  | **Timeline de Acessos por Hora**     | Volume de requisições agrupadas por hora do dia (00h–23h)                 |
| 7  | **Consumo de Banda – Mídia**        | Bytes consumidos apenas por requisições de arquivos de mídia (imagens)    |
| 8  | **Consumo de Banda – HTML/Outros** | Bytes consumidos por requisições que não são de mídia                     |

---

## 🧠 Arquitetura e Conceitos Funcionais

O projeto é estruturado para destacar os principais conceitos do paradigma funcional:

### Imutabilidade e Tipos Algébricos

Os dados são representados por _records_ imutáveis. Uma vez criado, um `LogEntry` nunca é modificado — todas as transformações geram novos valores.

```haskell
data LogEntry = LogEntry
  { ipAddress :: B.ByteString,
    method :: B.ByteString,
    endpoint :: B.ByteString,
    statusCode :: Int,
    bytesSent :: Int,
    hour :: B.ByteString,
    isMedia :: Bool
  }
  deriving (Show, Eq)
```

### Map (Transformação)

A função `parseLine` atua como uma operação de **map**, transformando cada linha de texto bruto em um dado estruturado (`Maybe LogEntry`). O uso de `Maybe` garante tratamento seguro de linhas malformadas, sem exceções.

### Reduce (Agregação)

Funções como `countOcurrences` e `totalBytes` utilizam **`foldl'`** (fold estrito à esquerda) para agregar dados, evitando _space leaks_ que são comuns em Haskell com avaliação _lazy_.

### Pipeline de Composição

A função central `analyzeTraffic` compõe todas as etapas em um **pipeline funcional**:

```
Texto bruto → parseLine (Map) → filter (Filtragem) → countOcurrences / totalBytes (Reduce) → LogMetrics
```

### Funções Puras

Toda a lógica de análise é implementada com funções puras (sem efeitos colaterais). O único código com IO está concentrado no módulo `Main`, que lê o arquivo e imprime os resultados.

---

## 📂 Estrutura do Projeto

```
LogAnalyzer/
├── app/
│   └── Main.hs                       # Ponto de entrada (IO): leitura do arquivo e exibição dos resultados
├── src/
│   └── LogAnalyzer.hs                # Módulo principal: parsing, filtragem e métricas (funções puras)
├── test/
│   └── Spec.hs                       # Testes unitários com HSpec
├── data/                             # Diretório onde os datasets devem ser armazenados
├── scripts/
│   └── amostra_aleatoria_dataset.py  # Script Python para gerar amostras aleatórias do dataset
├── LogAnalyzer.cabal                 # Manifesto do projeto (dependências, configurações de build)
├── CHANGELOG.md                      # Histórico de versões
├── LICENSE                           # Licença BSD-3-Clause
└── .gitignore                        # Arquivos ignorados pelo Git
```

---

## ⚙️ Pré-requisitos e Instalação do Haskell

### 1. Instalar o GHCup (Gerenciador de Toolchain do Haskell)

O **GHCup** é a forma recomendada de instalar o compilador GHC, o build system Cabal e demais ferramentas do ecossistema Haskell.

#### 🪟 Windows

Abra o **PowerShell** como Administrador e execute:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Command -ScriptBlock ([ScriptBlock]::Create((Invoke-WebRequest https://www.haskell.org/ghcup/sh/bootstrap-haskell.ps1 -UseBasicParsing))) -ArgumentList $true
```

O instalador irá guiá-lo interativamente. Aceite as opções padrão para instalar:
- **GHC** (compilador Haskell)
- **Cabal** (gerenciador de pacotes e build)
- **HLS** (Haskell Language Server — opcional, para suporte em IDEs)

#### 🐧 Linux / macOS

Abra o terminal e execute:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
```

Siga as instruções no terminal e aceite as opções padrão.

### 2. Verificar a Instalação

Após a instalação, feche e reabra o terminal e verifique:

```bash
ghc --version      # Deve retornar a versão do GHC (ex: 9.6.x ou superior)
cabal --version    # Deve retornar a versão do Cabal (ex: 3.10.x ou superior)
```

### 3. Atualizar o Índice de Pacotes

Antes de compilar qualquer projeto, atualize o índice do Hackage:

```bash
cabal update
```

---

## 📦 Dataset

Este projeto utiliza um dataset de logs de acesso web, disponível publicamente no Kaggle.

### 🔗 Link do Dataset

> **📌 Dataset:** [Web Server Access Logs](https://www.kaggle.com/datasets/eliasdabbas/web-server-access-logs/data)

### Como preparar os dados

1. Baixe o arquivo de log do Kaggle e extraia-o.
2. Mova o arquivo de log para dentro da pasta `data/`:
   ```bash
   mv caminho/para/access.log data/access.log
   ```
3. **(Opcional)** Para gerar amostras menores do dataset e testar mais rapidamente, utilize o script Python incluído:
   ```bash
   python scripts/amostra_aleatoria_dataset.py
   ```
   > **Nota:** O script utiliza o algoritmo de **Reservoir Sampling** para selecionar `k` linhas aleatórias de forma uniforme, sem carregar o arquivo inteiro na memória. Por padrão, `k = 100.000`. Edite a variável `k` no script para alterar o tamanho da amostra.

### Formato esperado

Cada linha do log deve seguir o padrão:

```
31.56.96.51 - - [22/Jan/2019:03:56:16 +0330] "GET /image/60844 HTTP/1.1" 200 5667
```

| Campo         | Exemplo                              | Descrição                        |
|---------------|--------------------------------------|----------------------------------|
| IP            | `31.56.96.51`                        | Endereço IP do cliente           |
| Identidade    | `-`                                  | Campo de identidade (não usado)  |
| Usuário       | `-`                                  | Usuário autenticado (não usado)  |
| Timestamp     | `[22/Jan/2019:03:56:16 +0330]`       | Data e hora da requisição        |
| Requisição    | `"GET /image/60844 HTTP/1.1"`        | Método, rota e protocolo HTTP    |
| Status        | `200`                                | Código de status HTTP            |
| Bytes         | `5667`                               | Tamanho da resposta em bytes     |

---

## 🔨 Como Compilar e Executar

### Compilar o Projeto

Na raiz do projeto, execute:

```bash
cabal build
```

O Cabal irá resolver e baixar automaticamente todas as dependências (`containers`, `time`, `bytestring`) e compilar o executável.

### Executar o Projeto

```bash
cabal run
```

> **Nota:** Por padrão, o programa procura o arquivo de log em `data/dataset_100k_access.log`. Certifique-se de que o dataset está nesse caminho antes de executar. Para alterar o caminho, edite a constante `logFilePath` em `app/Main.hs`.

### Compilar e Executar em Um Só Comando

```bash
cabal run
```

O `cabal run` já recompila automaticamente caso haja alterações no código.

---

## 🧪 Testes

O projeto inclui testes unitários escritos com o framework **HSpec**. Os testes cobrem:

- ✅ Parsing correto de linhas de log válidas (`parseLine`)
- ✅ Tratamento de linhas malformadas (retorno `Nothing`)
- ✅ Extração da hora do timestamp (`extractHour`)
- ✅ Fallback para hora padrão em formatos inválidos
- ✅ Classificação de URLs de mídia vs. não-mídia (`checkIfMedia`)
- ✅ Conversão segura de bytestrings numéricas (`readSafeInt`)

### Executar os Testes

```bash
cabal test
```

Saída esperada:

```
Running 1 test suites...
Test suite LogAnalyzer-test: RUNNING...

LogAnalyzer.parseLine
  Extrai todos os campos corretamente de uma linha de log válida. [v]
  Retorna 'Nothing' para uma linha malformada. [v]
LogAnalyzer.extractHour
  Extrai a hora correta de um bloco de timestamp. [v]
  Retorna '00' como fallback se o delimitador não existir. [v]
LogAnalyzer.checkIfMedia
  Identifica rotas dinamicas de imagem como midia. [v]
  Identifica rotas de diretorios estaticos como midia. [v]
  Identifica extensoes especificas de arquivo como midia. [v]
  Retorna False para endpoints normais (HTML/JSON). [v]
LogAnalyzer.readSafeInt
  Converte uma string numérica para Int. [v]
  Retorna '0' para strings não numéricas. [v]

Finished in 0.0047 seconds
10 examples, 0 failures
Test suite LogAnalyzer-test: PASS
```

---

## 📋 Exemplo de Saída

Ao executar o programa com o dataset de 500 mil linhas, a saída será semelhante a:

```
Iniciando análise de logs...

=== Distribuição de Métodos HTTP ===
GET - 491462 requisição(ões)
POST - 6779 requisição(ões)
HEAD - 1683 requisição(ões)
OPTIONS - 73 requisição(ões)
" - 1 requisição(ões)
\x03\x00\x00/*\xE0\x00\x00\x00\x00\x00Cookie: - 1 requisição(ões)
\x10\x7F\x91Q\xE3\x8E\x5C\xE7\xF4>\xB3&{o\xB9F/~P\xD3B?\x91\xA9\xD2\x86\xF7fB\xB4FE\xF9\xE4U\x1B`\x1F\x16\xB4)" - 1 requisição(ões)

=== Timeline: Volume de Acessos por Hora ===
00h - 16877 requisição(ões)
01h - 10940 requisição(ões)
02h - 6211 requisição(ões)
03h - 3795 requisição(ões)
04h - 3672 requisição(ões)
05h - 3392 requisição(ões)
06h - 4538 requisição(ões)
07h - 8849 requisição(ões)
08h - 18455 requisição(ões)
09h - 27321 requisição(ões)
10h - 32299 requisição(ões)
11h - 35433 requisição(ões)
12h - 35013 requisição(ões)
13h - 34701 requisição(ões)
14h - 33390 requisição(ões)
15h - 31419 requisição(ões)
16h - 27730 requisição(ões)
17h - 26456 requisição(ões)
18h - 26946 requisição(ões)
19h - 27292 requisição(ões)
20h - 23126 requisição(ões)
21h - 19933 requisição(ões)
22h - 22151 requisição(ões)
23h - 20061 requisição(ões)

=== Top 10 Endpoints Não Encontrados (Erro 404) ===
/apple-touch-icon-precomposed.png - 869 vez(es)
/apple-touch-icon.png - 796 vez(es)
/apple-touch-icon-120x120.png - 621 vez(es)
/apple-touch-icon-120x120-precomposed.png - 606 vez(es)
/product/themes/default-rtl/style.css - 47 vez(es)
/product/falsedefault-rtl/style.css - 41 vez(es)
/apple-touch-icon-152x152-precomposed.png - 39 vez(es)
/m/alexaGooleAnalitic - 38 vez(es)
/apple-touch-icon-152x152.png - 28 vez(es)
/static/plugins/ckeditor-3.6.2.2/js/ckeditor/contents.min.css - 16 vez(es)

=== Top 10 IPs geradores de Erros ===
66.249.66.194 - 533 erro(s)
104.222.32.91 - 530 erro(s)
151.239.241.163 - 83 erro(s)
91.99.47.57 - 72 erro(s)
5.78.190.233 - 48 erro(s)
91.99.30.32 - 41 erro(s)
5.117.116.238 - 40 erro(s)
37.9.113.152 - 38 erro(s)
2.191.96.86 - 31 erro(s)
95.82.39.94 - 26 erro(s)

=== Top 10 Endpoints Mais Acessados ===
/settings/logo - 17050 acesso(s)
/static/css/font/wyekan/font.woff - 13606 acesso(s)
/static/images/guarantees/bestPrice.png - 6716 acesso(s)
/static/images/guarantees/fastDelivery.png - 6106 acesso(s)
/static/images/guarantees/warranty.png - 5909 acesso(s)
/static/images/guarantees/goodShopping.png - 5528 acesso(s)
/site/alexaGooleAnalitic - 5197 acesso(s)
/favicon.ico - 5006 acesso(s)
/static/images/guarantees/support.png - 4690 acesso(s)
/static/images/amp/telegram.png - 4440 acesso(s)

=== Perfil de Consumo de Banda ===
Total Trafegado : 5936.15 MB
Consumo de Mídia: 3195.77 MB
Consumo de HTML : 2740.38 MB

Processamento concluído em: 4.380143s
```

> **Nota:** Os valores acima são ilustrativos. Os resultados reais dependem do conteúdo do dataset utilizado.

---

## 🛠️ Tecnologias Utilizadas

| Tecnologia                | Descrição                                             |
|---------------------------|-------------------------------------------------------|
| **Haskell (GHC)**         | Linguagem de programação funcional pura e compilada    |
| **Cabal**                 | Sistema de build e gerenciamento de dependências       |
| **Data.Map.Strict**       | Estrutura de dicionário com avaliação estrita          |
| **Data.ByteString.Char8** | Processamento eficiente de strings em bytes (`bytestring`) |
| **Data.Time**             | Medição de tempo de execução                          |
| **Text.Printf**           | Formatação de saída numérica                          |
| **HSpec**                 | Framework de testes unitários em estilo BDD            |
| **Python 3** _(opcional)_ | Script auxiliar para amostragem do dataset             |

---

## 📄 Licença

Este projeto está licenciado sob a licença **BSD-3-Clause**. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👤 Autor

**Vitor Hugo Rodovalho**

---