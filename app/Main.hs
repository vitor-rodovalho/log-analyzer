module Main where

import qualified Data.ByteString.Char8 as B
import Data.Time.Clock (diffUTCTime, getCurrentTime)
import LogAnalyzer
import Text.Printf (printf)

-- | Constante que define o caminho do dataset
logFilePath :: String
logFilePath = "data/dataset_100k_access.log"

main :: IO ()
main = do
  putStrLn "Iniciando análise de logs..."
  start <- getCurrentTime

  fileContent <- B.readFile logFilePath
  let metrics = analyzeTraffic fileContent

  putStrLn "\n=== Distribuição de Métodos HTTP ==="
  mapM_ (\(m, count) -> putStrLn $ B.unpack m ++ " - " ++ show count ++ " requisição(ões)") (methodDist metrics)

  putStrLn "\n=== Timeline: Volume de Acessos por Hora ==="
  mapM_ (\(h, count) -> putStrLn $ B.unpack h ++ "h - " ++ show count ++ " requisição(ões)") (reqPerHour metrics)

  putStrLn "\n=== Top 10 Endpoints Não Encontrados (Erro 404) ==="
  mapM_ (\(ep, count) -> putStrLn $ B.unpack ep ++ " - " ++ show count ++ " vez(es)") (top404s metrics)

  putStrLn "\n=== Top 10 IPs geradores de Erros ==="
  mapM_ (\(ip, count) -> putStrLn $ B.unpack ip ++ " - " ++ show count ++ " erro(s)") (topErrorIps metrics)

  putStrLn "\n=== Top 10 Endpoints Mais Acessados ==="
  mapM_ (\(ep, count) -> putStrLn $ B.unpack ep ++ " - " ++ show count ++ " acesso(s)") (topEndpoints metrics)

  putStrLn "\n=== Perfil de Consumo de Banda ==="
  printf "Total Trafegado : %.2f MB\n" (totalMb metrics)
  printf "Consumo de Mídia: %.2f MB\n" (mediaMb metrics)
  printf "Consumo de HTML : %.2f MB\n" (htmlMb metrics)

  end <- getCurrentTime
  putStrLn $ "\nProcessamento concluído em: " ++ show (diffUTCTime end start)