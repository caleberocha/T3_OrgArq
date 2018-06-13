import math
import os

def write(text, where):
	if(where == "console"):
		print(text)
	else:
		t = open(where, 'a')
		t.write(text + "\n")
		t.close()

def bitLen(number):
	n = 0
	while(number != 0):
		number = number >> 1
		n += 1
	return n

def hitDirect(cacheLine, addr, addrSize, wordSize, tagSize):
	if len(cacheLine) < 1:
		return False

	if cacheLine[0] != addr >> addrSize - tagSize:
		return False

	return True
	#return addr & ~(wordSize-1) in cacheLine[1:]

def hitAssoc(cache, addr, addrSize, wordSize, tagSize):
	for line in cache:
		if len(line) > 0 and line[0] == addr >> addrSize - tagSize:# and addr & ((1 << tagSize) - 1 << addrSize - tagSize) in line[1:]:
			return True

	return False

def cacheSimulatorDirect(file, addressSize, lineSize, wordSize, out):
	if(out != "console" and os.path.isfile(out)):
		os.remove(out)

	cache = [None] * (1 << (lineSize))
	for i in range(0, len(cache)):
		cache[i] = [None] * ((1 << wordSize) + 1)

	wordBitLen = bitLen(wordSize) - 1

	tagSize = addressSize - lineSize - wordSize - wordBitLen
	hits = 0
	arq = open(file, 'r')
	addresses = arq.readlines()

	write("{0:4s}".format("Addr") + " | " + ("{0:"+str(addressSize)+"s}").format("Byte") + " | " + ("{0:"+str(tagSize)+"s}").format("Tag") + " | " + ("{0:"+str(lineSize)+"s}").format("Line") + " | " + ("{0:"+str(wordSize)+"s}").format("Wd") + " | Result", out)
	for address in addresses:
		address = address.replace("\r","").replace("\n","")
		address = int(address,16)

		tag  = address >> lineSize + wordSize + wordBitLen
		line = address >> wordSize + wordBitLen & ((1 << lineSize) - 1)
		word = address >> wordBitLen & ((1 << wordSize) - 1)

		lineContent = str("{0:04x}".format(address) + " | " + ("{0:0"+str(addressSize)+"b}").format(address) + " | " + ("{0:0"+str(tagSize)+"b}").format(tag) + " | " + ("{0:0"+str(lineSize)+"b}").format(line)) + " | " + ("{0:0"+str(wordSize)+"b}").format(word)
		if hitDirect(cache[line], address, addressSize, wordSize, tagSize):
			hits += 1
			write(lineContent + " | " + "Hit", out)
		else:
			write(lineContent + " | " + "Miss", out)
			cache[line][0] = tag
			for i in range(1, len(cache[line])):
				cache[line][i] = (address >> wordBitLen+wordSize << wordSize) + (i-1) << wordBitLen

		printCacheDirect(cache, lineSize, tagSize, out)

	write("\nEstado final da cache:", out)
	printCacheDirect(cache, lineSize, tagSize, out)
	write("\nEnderecos: " + str(len(addresses)), out)
	write("Hits:      " + str(hits) + " (" + str(hits / float(len(addresses)) * 100) + "%)", out)
	write("Misses:    " + str(len(addresses) - hits), out)

def cacheSimulatorAssoc(file, addressSize, wordSize, cacheSize, out):
	if(out != "console" and os.path.isfile(out)):
		os.remove(out)

	cache = [None] * cacheSize
	for i in range(0, len(cache)):
		cache[i] = [None] * ((1 << wordSize) + 1)

	wordBitLen = bitLen(wordSize) - 1
	tagSize = addressSize - wordSize - wordBitLen
	index = 0
	hits = 0
	arq = open(file, 'r')
	addresses = arq.readlines()

	write("{0:4s}".format("Addr") + " | " + ("{0:"+str(addressSize)+"s}").format("Byte") + " | " + ("{0:"+str(tagSize)+"s}").format("Tag") + " | " + ("{0:"+str(wordSize)+"s}").format("Wd") + " | Result", out)
	for address in addresses:
		address = address.replace("\r","").replace("\n","")
		address = int(address,16)

		tag  = address >> wordSize + wordBitLen
		word = address >> wordBitLen & ((1 << wordSize) - 1)

		lineContent = str("{0:04x}".format(address) + " | " + ("{0:0"+str(addressSize)+"b}").format(address) + " | " + ("{0:0"+str(tagSize)+"b}").format(tag) + " | " + ("{0:0"+str(wordSize)+"b}").format(word))
		if hitAssoc(cache, address, addressSize, wordSize, tagSize):
			hits += 1
			write(lineContent + " | " + "Hit", out)
		else:
			write(lineContent + " | " + "Miss", out)
			cache[index][0] = tag
			for i in range(1, len(cache[index])):
				cache[index][i] = (address >> wordBitLen+wordSize << wordSize) + (i-1) << wordBitLen

			index += 1
			index = index % cacheSize

		#printCacheAssoc(cache, lineSize, tagSize, out)

	write("\nEstado final da cache:", out)
	printCacheAssoc(cache, tagSize, out)
	write("\nEnderecos: " + str(len(addresses)), out)
	write("Hits:      " + str(hits) + " (" + str(hits / float(len(addresses)) * 100) + "%)", out)
	write("Misses:    " + str(len(addresses) - hits), out)


def printCacheDirect(cache, lineSize, tagSize, out):
	l = str(lineSize)
	write(("{0:"+l+"s}").format("Line") + " | " + ("{0:"+str(tagSize)+"s}").format("Tag") + " | Dados", out)
	for i in range(0, len(cache)):
		if len(cache[i]) > 1 and cache[i][0] != None:
			write(("{0:0"+l+"b}").format(i) + " | " + ("{0:0"+str(tagSize)+"b}").format(cache[i][0]) + " | " + str(", ".join('{0:04x}'.format(k) for k in cache[i][1:])), out)
	#write("", out)

def printCacheAssoc(cache, tagSize, out):
	l = str(bitLen(len(cache)))
	write(("{0:"+l+"s}").format("Line") + " | " + ("{0:"+str(tagSize)+"s}").format("Tag") + " | Dados", out)
	for i in range(0, len(cache)):
		if len(cache[i]) > 1 and cache[i][0] != None:
			write(("{0:0"+l+"b}").format(i) + " | " + ("{0:0"+str(tagSize)+"b}").format(cache[i][0]) + " | " + str(", ".join('{0:04x}'.format(k) for k in cache[i][1:])), out)
	#write("", out)



cacheSimulatorDirect("addresses.txt", 16, 4, 2, "direto1.txt")
cacheSimulatorDirect("addresses.txt", 16, 5, 1, "direto2.txt")
cacheSimulatorAssoc("addresses.txt", 16, 2, 16, "assoc1.txt")
cacheSimulatorAssoc("addresses.txt", 16, 1, 32, "assoc2.txt")