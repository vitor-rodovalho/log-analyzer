module LogAnalyzer where

import qualified Data.ByteString.Char8 as B
import Data.List (foldl', sortBy)
import qualified Data.Map.Strict as Map
import Data.Ord (Down (..), comparing)

-- CONSTANTES E REGRAS DE NEGÓCIO

-- | Extensões de arquivo consideradas como mídia pesada.
mediaExtensions :: [B.ByteString]
mediaExtensions = map B.pack [".png", ".jpg", ".jpeg", ".gif", ".webp"]

-- | Diretórios (prefixos) que indicam conteúdo de mídia.
mediaDirectories :: [B.ByteString]
mediaDirectories = map B.pack ["/image/", "/static/images/"]

-- | Status HTTP que determinam o início da faixa de erro (Client/Server Errors).
httpErrorThreshold :: Int
httpErrorThreshold = 400

-- | Status HTTP específico para página não encontrada (Not Found).
httpNotFound :: Int
httpNotFound = 404

-- | Hora padrão (fallback) caso o log esteja corrompido ou sem delimitador.
fallbackHour :: B.ByteString
fallbackHour = B.pack "00"

-- | Tipo de dado imutável que representa uma única linha de log processada.
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

-- | Estrutura agregadora (Record) para empacotar e retornar todos os resultados
-- numéricos do processamento de uma só vez, sem efeitos colaterais.
data LogMetrics = LogMetrics
  { topErrorIps :: [(B.ByteString, Int)],
    topEndpoints :: [(B.ByteString, Int)],
    totalMb :: Double,
    methodDist :: [(B.ByteString, Int)],
    top404s :: [(B.ByteString, Int)],
    reqPerHour :: [(B.ByteString, Int)],
    mediaMb :: Double,
    htmlMb :: Double
  }
  deriving (Show)

-- | [MAP] Transforma uma bytestring bruta em um dado estruturado.
-- Retorna um tipo 'Maybe' para lidar com segurança caso alguma linha do log esteja corrompida ou incompleta.
parseLine :: B.ByteString -> Maybe LogEntry
parseLine line =
  let parts = B.words line
   in if length parts >= 10
        then
          Just $
            LogEntry
              { ipAddress = head parts,
                method = B.drop 1 (parts !! 5),
                endpoint = parts !! 6,
                statusCode = readSafeInt (parts !! 8),
                bytesSent = readSafeInt (parts !! 9),
                -- Extrai a hora separando a string "[22/Jan/2019:03:56:14" por ":"
                hour = extractHour (parts !! 3),
                -- Define como mídia se a URL começar com /image/
                isMedia = checkIfMedia (parts !! 6)
              }
        else Nothing

-- | [FUNÇÃO AUXILIAR] Garante a extração da hora (posição 1 após o split do timestamp).
-- Retorna um fallback ("00") caso o formato da data não contenha o delimitador ":".
extractHour :: B.ByteString -> B.ByteString
extractHour timeStr =
  let tokens = B.split ':' timeStr
   in if length tokens >= 2 then tokens !! 1 else fallbackHour

-- | [FUNÇÃO AUXILIAR] Valida se a URL requisitada é um arquivo de mídia pesada.
-- Combina verificações de diretórios dinâmicos com extensões de arquivos estáticos.
checkIfMedia :: B.ByteString -> Bool
checkIfMedia url =
  let hasMediaExtension = any (`B.isSuffixOf` url) mediaExtensions
      hasMediaDirectory = any (`B.isPrefixOf` url) mediaDirectories
   in hasMediaExtension || hasMediaDirectory

-- | [FUNÇÃO AUXILIAR] Converte ByteString para Int de forma pura.
-- Evita a quebra (Exception) do parser caso a coluna de bytes venha vazia ("-") no dataset.
readSafeInt :: B.ByteString -> Int
readSafeInt s = case B.readInt s of
  Just (val, _) -> val
  Nothing -> 0

-- | [REDUCE] Cria um dicionário de frequência (Chave-Valor) a partir de uma lista genérica.
-- Utiliza avaliação estrita (foldl') para evitar estouro de memória (Space Leak).
countOcurrences :: [B.ByteString] -> [(B.ByteString, Int)]
countOcurrences items =
  let freqMap = foldl' (\acc item -> Map.insertWith (+) item 1 acc) Map.empty items
   in Map.toList freqMap

-- | [REDUCE] Soma iterativamente o campo de bytes de uma lista de logs filtrados.
-- Também utiliza avaliação estrita.
totalBytes :: [LogEntry] -> Int
totalBytes = foldl' (\acc entry -> acc + bytesSent entry) 0

-- | [PIPELINE CENTRAL] Recebe o arquivo inteiro em texto e engatilha todas as métricas.
analyzeTraffic :: B.ByteString -> LogMetrics
analyzeTraffic fileContent =
  let allLines = B.lines fileContent

      -- Mapeia e filtra linhas válidas silenciosamente descartando os 'Nothing'
      parsedLogs =
        foldr
          ( \line acc -> case parseLine line of
              Just entry -> entry : acc
              Nothing -> acc
          )
          []
          allLines

      -- Métrica 1: Top IPs com erro
      errorLogs = filter (\entry -> statusCode entry >= httpErrorThreshold) parsedLogs
      topErrors = take 10 $ sortBy (comparing (Down . snd)) (countOcurrences $ map ipAddress errorLogs)

      -- Métrica 2: Top Endpoints acessados
      topEps = take 10 $ sortBy (comparing (Down . snd)) (countOcurrences $ map endpoint parsedLogs)

      -- Métrica 3: Consumo de Banda (Total)
      mb = fromIntegral (totalBytes parsedLogs) / (1024 * 1024) :: Double

      -- Métrica 4: Distribuição de Métodos HTTP (GET, POST, etc.)
      methods = sortBy (comparing (Down . snd)) (countOcurrences $ map method parsedLogs)

      -- Métrica 5: Top Endpoints 404 (Páginas não encontradas)
      notFounds = filter (\entry -> statusCode entry == httpNotFound) parsedLogs
      top404 = take 10 $ sortBy (comparing (Down . snd)) (countOcurrences $ map endpoint notFounds)

      -- Métrica 6: Agrupadas por hora cronológica (Timeline)
      timeline = sortBy (comparing fst) (countOcurrences $ map hour parsedLogs)

      -- Métrica 7: Filtra apenas as requisições de mídia e converte os bytes para MB
      mediaB = totalBytes (filter isMedia parsedLogs)
      mediaM = fromIntegral mediaB / (1024 * 1024) :: Double

      -- Métrica 8: Filtra o que NÃO é mídia e converte os bytes para MB
      htmlB = totalBytes $ filter (not . isMedia) parsedLogs
      htmlM = fromIntegral htmlB / (1024 * 1024) :: Double
   in LogMetrics topErrors topEps mb methods top404 timeline mediaM htmlM