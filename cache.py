import math
import os

def write(text, where):
    if(where == "console"):
        print(text)
    else:
        t = open(where, 'a')
        t.write(text + "\n")
        t.close()

def hit(cache, addr, tagSize):
    for line in cache:
        if len(line) > 0 and line[0] == addr[:tagSize] and addr[tagSize:] in line[1:]:
            return True

    return False

def cacheSimulatorAssoc(arquivo, tamanhoTag, tamanhoPalavra, tamanhoCache, saida):
    if(saida != "console" and os.path.isfile(saida)):
        os.remove(saida)

    cache = []
    for t in range(0, tamanhoCache):
        cache.append([])
    
    bits = tamanhoTag + tamanhoPalavra
    index = 0
    hits = 0
    arq = open(arquivo, 'r')
    entradas = arq.readlines()

    write("{0:4s}".format("Hex") + " | " + ("{0:"+str(bits)+"s}").format("Byte") + " | " + ("{0:"+str(tamanhoTag)+"s}").format("Tag") + " | " + ("{0:"+str(tamanhoPalavra)+"s}").format("P") + " | Result", saida)
    for entrada in entradas:
        entrada = entrada.replace("\r\n","")
        entrada = ("{0:0"+str(bits)+"b}").format(int(entrada,16))
        line = str("{0:04x}".format(int(entrada, 2)) + " | " + entrada + " | " + entrada[:tamanhoTag] + " | " + entrada[tamanhoTag:tamanhoTag+tamanhoPalavra])
        #printCache(cache, tamanhoCache, tamanhoTag)
        if hit(cache, entrada, tamanhoTag):
            hits += 1
            write(line + " | " + "Hit", saida)
        else:
            write(line + " | " + "Miss", saida)
            cache[index] = []
            cache[index].append(entrada[:tamanhoTag])
            for i in range(0, int(math.pow(2, tamanhoPalavra))):
                cache[index].append(("{0:0"+str(tamanhoPalavra)+"b}").format(i))

            index += 1
            index = index % tamanhoCache

    write("\nEstado final da cache:", saida)
    printCache(cache, tamanhoCache, tamanhoTag, saida)
    write("\nEnderecos: " + str(len(entradas)), saida)
    write("Hits:      " + str(hits) + " (" + str(hits / float(len(entradas)) * 100) + "%)", saida)
    write("Misses:    " + str(len(entradas) - hits), saida)

def printCacheAssoc'(cache, tamanhoCache, tamanhoTag, saida):
    write(("{0:"+str(int(math.log(tamanhoCache,2)))+"s}").format("Line") + " | " + ("{0:"+str(tamanhoTag)+"s}").format("Tag") + " | Dados", saida)
    t = 0
    for line in cache:
        if len(line) > 1:
            write(("{0:0"+str(int(math.log(tamanhoCache,2)))+"b}").format(t) + " | " + str(line[0]) + " | " + str(line[1:5]), saida)
            t += 1


cacheSimulatorAssoc("addresses.txt", 14, 2, 16, "assoc1.txt")
cacheSimulatorAssoc("addresses.txt", 15, 1, 32, "assoc2.txt")