import random
import time
from pathlib import Path

# Tamanho da amostra desejada
k = 500000
amostra = []

print(f"Varrendo o arquivo para selecionar {k} linhas aleatórias...")
start = time.time()

with Path("data/access.log").open(encoding="utf-8", errors="ignore") as f_in:
    for i, linha in enumerate(f_in):
        # Preenche o "reservatório" com as primeiras k linhas
        if i < k:
            amostra.append(linha)
        # Para o restante do arquivo, substitui as linhas com probabilidade decrescente
        else:
            j = random.randint(0, i)
            if j < k:
                amostra[j] = linha

# Salva a amostra final no disco
with Path("data/dataset_500k_access.log").open("w", encoding="utf-8") as f_out:
    f_out.writelines(amostra)

end = time.time()
print(f"Amostra gerada com sucesso em {end - start:.2f} segundos!")
