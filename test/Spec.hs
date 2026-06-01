module Main where

import LogAnalyzer
import Test.Hspec

main :: IO ()
main = hspec $ do
  describe "LogAnalyzer.parseLine" $ do
    it "Extrai todos os campos corretamente de uma linha de log válida." $ do
      let rawLine = "31.56.96.51 - - [22/Jan/2019:03:56:16 +0330] \"GET /image/60844 HTTP/1.1\" 200 5667"
      let expected =
            Just $
              LogEntry
                { ipAddress = "31.56.96.51",
                  method = "GET",
                  endpoint = "/image/60844",
                  statusCode = 200,
                  bytesSent = 5667,
                  hour = "03",
                  isMedia = True
                }
      parseLine rawLine `shouldBe` expected

    it "Retorna 'Nothing' para uma linha malformada." $ do
      let badLine = "31.56.96.51 - - [22/Jan/2019:03:56:16 +0330] \"GET"
      parseLine badLine `shouldBe` Nothing

  describe "LogAnalyzer.extractHour" $ do
    it "Extrai a hora correta de um bloco de timestamp." $ do
      extractHour "[22/Jan/2019:14:56:14" `shouldBe` "14"

    it "Retorna '00' como fallback se o delimitador não existir." $ do
      extractHour "FormatoInvalido" `shouldBe` "00"

  describe "LogAnalyzer.checkIfMedia" $ do
    it "Identifica rotas dinamicas de imagem como midia." $ do
      checkIfMedia "/image/1/productType/240x180" `shouldBe` True

    it "Identifica rotas de diretorios estaticos como midia." $ do
      checkIfMedia "/static/images/guarantees/support.png" `shouldBe` True

    it "Identifica extensoes especificas de arquivo como midia." $ do
      checkIfMedia "/assets/banner.webp" `shouldBe` True

    it "Retorna False para endpoints normais (HTML/JSON)." $ do
      checkIfMedia "/rapidGrails/jsonList?maxColumns=16" `shouldBe` False

  describe "LogAnalyzer.readSafeInt" $ do
    it "Converte uma string numérica para Int." $ do
      readSafeInt "404" `shouldBe` 404

    it "Retorna '0' para strings não numéricas." $ do
      readSafeInt "-" `shouldBe` 0