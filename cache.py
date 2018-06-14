# coding: latin-1
import math
import os

def write(text, where):
	if(where == "console"):
		print(text)
	else:
		t = open(where, 'a')
		t.write(text + "\n")
		t.close()

def bitSizeOf(number):
	n = 0
	while(number != 0):
		number = number >> 1
		n += 1
	return n

def hit(cache, line, address, addressSize, wordSize, tagSize):
	lineRange = [0, len(cache)]
	if line > -1:
		lineRange = [line, line+1]

	for i in range(lineRange[0], lineRange[1]):
		if len(cache[i]) > 0 and cache[i][0] == address >> addressSize - tagSize:
			return True
	return False

def printCache(cache, lineSize, tagSize, out):
	l = str(lineSize)
	if lineSize == -1:
		l = str(bitSizeOf(len(cache)))

	write(("{0:"+l+"s}").format("Line") + " | " + ("{0:"+str(tagSize)+"s}").format("Tag") + " | Dados", out)
	for i in range(0, len(cache)):
		if len(cache[i]) > 1 and cache[i][0] != None:
			write(("{0:0"+l+"b}").format(i) + " | " + ("{0:0"+str(tagSize)+"b}").format(cache[i][0]) + " | " + str(", ".join('{0:04x}'.format(k) for k in cache[i][1:])), out)
	#write("", out)

def cacheSimulator(mappingType, file, addressSize, lineSize, wordSize, cacheSize, out):
	if out != "console" and os.path.isfile(out):
		os.remove(out)

	if mappingType != "d" and mappingType != "a":
		raise("Tipo de mapeamento inválido! Os tipos suportados são d (direto) e a (associativo)")

	isDirectMapping = mappingType == "d"

	if isDirectMapping:
		if lineSize == 0:
			raise("Tamanho de linha inválido")
		cache = [None] * (1 << (lineSize))
	else:
		if cacheSize == 0:
			raise("Tamanho de cache inválido")
		cache = [None] * cacheSize
	for i in range(0, len(cache)):
		cache[i] = [None] * ((1 << wordSize) + 1)

	sizeofWord = addressSize / 8 - 1

	if isDirectMapping:
		tagSize = addressSize - lineSize - wordSize - sizeofWord
	else:
		tagSize = addressSize - wordSize - sizeofWord

	lineIndex = 0
	hits = 0
	arq = open(file, 'r')
	addresses = arq.readlines()

	if isDirectMapping:
		write("{0:4s}".format("Addr") + " | " + ("{0:"+str(addressSize)+"s}").format("Byte") + " | " + ("{0:"+str(tagSize)+"s}").format("Tag") + " | " + ("{0:"+str(lineSize)+"s}").format("Line") + " | " + ("{0:"+str(wordSize)+"s}").format("Wd") + " | Result", out)
	else:
		write("{0:4s}".format("Addr") + " | " + ("{0:"+str(addressSize)+"s}").format("Byte") + " | " + ("{0:"+str(tagSize)+"s}").format("Tag") + " | " + ("{0:"+str(wordSize)+"s}").format("Wd") + " | Result", out)

	for address in addresses:
		address = address.replace("\r","").replace("\n","")
		address = int(address,16)

		word = address >> sizeofWord & ((1 << wordSize) - 1)
		if isDirectMapping:
			tag = address >> lineSize + wordSize + sizeofWord
			lineIndex = address >> wordSize + sizeofWord & ((1 << lineSize) - 1)
			lineContent = str("{0:04x}".format(address) + " | " + ("{0:0"+str(addressSize)+"b}").format(address) + " | " + ("{0:0"+str(tagSize)+"b}").format(tag) + " | " + ("{0:0"+str(lineSize)+"b}").format(lineIndex)) + " | " + ("{0:0"+str(wordSize)+"b}").format(word)
			lineIndexForHit = lineIndex
		else:
			tag = address >> wordSize + sizeofWord
			lineContent = str("{0:04x}".format(address) + " | " + ("{0:0"+str(addressSize)+"b}").format(address) + " | " + ("{0:0"+str(tagSize)+"b}").format(tag) + " | " + ("{0:0"+str(wordSize)+"b}").format(word))
			lineIndexForHit = -1
		
		if hit(cache, lineIndexForHit, address, addressSize, wordSize, tagSize):
			hits += 1
			write(lineContent + " | " + "Hit", out)
		else:
			write(lineContent + " | " + "Miss", out)
			cache[lineIndex][0] = tag
			for i in range(1, len(cache[lineIndex])):
				cache[lineIndex][i] = (address >> sizeofWord+wordSize << wordSize) + (i-1) << sizeofWord

		if isDirectMapping == False:
			lineIndex += 1
			lineIndex = lineIndex % cacheSize
			lineSize = -1

		#printCache(cache, lineSize, tagSize, out)

	write("\nEstado final da cache:", out)
	printCache(cache, lineSize, tagSize, out)
	write("\nEnderecos: " + str(len(addresses)), out)
	write("Hits:      " + str(hits) + " (" + str(hits / float(len(addresses)) * 100) + "%)", out)
	write("Misses:    " + str(len(addresses) - hits), out)


cacheSimulator("d", "addresses.txt", 16, 4, 2, 0, "direto1.txt")
cacheSimulator("d", "addresses.txt", 16, 5, 1, 0, "direto2.txt")
cacheSimulator("a", "addresses.txt", 16, 0, 2, 16, "assoc1.txt")
cacheSimulator("a", "addresses.txt", 16, 0, 1, 32, "assoc2.txt")