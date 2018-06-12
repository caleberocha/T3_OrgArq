import math
import os

def write(text, where):
	if(where == "console"):
		print(text)
	else:
		t = open(where, 'a')
		t.write(text + "\n")
		t.close()

def hitDirect(cacheLine, addr, tagSize):
	if len(cacheLine) < 1:
		return False

	if cacheLine[0] != addr[:tagSize]:
		return False

	return addr in cacheLine[1:]

def hitAssoc(cache, addr, tagSize):
	for line in cache:
		if len(line) > 0 and line[0] == addr[:tagSize] and addr[tagSize:] in line[1:]:
			return True

	return False

def cacheSimulatorDirect(file, tagSize, lineSize, wordSize, out):
	if(out != "console" and os.path.isfile(out)):
		os.remove(out)

	cache = []
	for t in range(0, int(math.pow(2, lineSize))):
		d = []
		for u in range(0, int(math.pow(2, wordSize)) + 1):
			d.append(None)
		cache.append(d)

	bits = tagSize + lineSize + wordSize
	hits = 0
	arq = open(file, 'r')
	addresses = arq.readlines()

	write("{0:4s}".format("Hex") + " | " + ("{0:"+str(bits)+"s}").format("Byte") + " | " + ("{0:"+str(tagSize)+"s}").format("Tag") + " | " + ("{0:"+str(lineSize)+"s}").format("Line") + " | " + ("{0:"+str(wordSize)+"s}").format("P") + " | Result", out)
	for address in addresses:
		address = address.replace("\r\n","")
		address = ("{0:0"+str(bits)+"b}").format(int(address,16))
		sTag = address[:tagSize]
		sLine = address[tagSize:tagSize+lineSize]
		sWord = address[tagSize+lineSize:]
		iLine = int(sLine,2)
		line = str("{0:04x}".format(int(address, 2)) + " | " + address + " | " + sTag + " | " + sLine + " | " + sWord)
		if hitDirect(cache[iLine], address, tagSize):
			hits += 1
			write(line + " | " + "Hit", out)
		else:
			write(line + " | " + "Miss", out)
			cache[iLine][0] = sTag
			n = int(address,2) & ~int(math.pow(2,wordSize)-1)
			for j in range(0, int(math.pow(2,wordSize))):
				cache[iLine][j+1] = str(("{0:0"+str(bits)+"b}").format(n+j))

	write("\nEstado final da cache:", out)
	printCacheDirect(cache, lineSize, tagSize, out)
	write("\nEnderecos: " + str(len(addresses)), out)
	write("Hits:      " + str(hits) + " (" + str(hits / float(len(addresses)) * 100) + "%)", out)
	write("Misses:    " + str(len(addresses) - hits), out)    


def cacheSimulatorAssoc(file, tagSize, wordSize, cacheSize, out):
	if(out != "console" and os.path.isfile(out)):
		os.remove(out)

	cache = []
	for t in range(0, cacheSize):
		cache.append([])
	
	bits = tagSize + wordSize
	index = 0
	hits = 0
	arq = open(file, 'r')
	addresses = arq.readlines()

	write("{0:4s}".format("Hex") + " | " + ("{0:"+str(bits)+"s}").format("Byte") + " | " + ("{0:"+str(tagSize)+"s}").format("Tag") + " | " + ("{0:"+str(wordSize)+"s}").format("P") + " | Result", out)
	for address in addresses:
		address = address.replace("\r\n","")
		address = ("{0:0"+str(bits)+"b}").format(int(address,16))
		line = str("{0:04x}".format(int(address, 2)) + " | " + address + " | " + address[:tagSize] + " | " + address[tagSize:tagSize+wordSize])
		#printCacheAssoc(cache, cacheSize, tagSize)
		if hitAssoc(cache, address, tagSize):
			hits += 1
			write(line + " | " + "Hit", out)
		else:
			write(line + " | " + "Miss", out)
			cache[index] = []
			cache[index].append(address[:tagSize])
			for i in range(0, int(math.pow(2, wordSize))):
				cache[index].append(("{0:0"+str(wordSize)+"b}").format(i))

			index += 1
			index = index % cacheSize

	write("\nEstado final da cache:", out)
	printCacheAssoc(cache, cacheSize, tagSize, out)
	write("\nEnderecos: " + str(len(addresses)), out)
	write("Hits:      " + str(hits) + " (" + str(hits / float(len(addresses)) * 100) + "%)", out)
	write("Misses:    " + str(len(addresses) - hits), out)

def printCacheDirect(cache, lineSize, tagSize, out):
	write(("{0:"+str(lineSize)+"s}").format("Line") + " | " + ("{0:"+str(tagSize)+"s}").format("Tag") + " | Dados", out)
	t = 0
	for line in cache:
		if len(line) > 1:
			write(("{0:0"+str(lineSize)+"b}").format(t) + " | " + str(line[0]) + " | " + str(line[1:5]), out)
			t += 1

def printCacheAssoc(cache, cacheSize, tagSize, out):
	write(("{0:"+str(int(math.log(cacheSize,2)))+"s}").format("Line") + " | " + ("{0:"+str(tagSize)+"s}").format("Tag") + " | Dados", out)
	t = 0
	for line in cache:
		if len(line) > 1:
			write(("{0:0"+str(int(math.log(cacheSize,2)))+"b}").format(t) + " | " + str(line[0]) + " | " + str(line[1:5]), out)
			t += 1


cacheSimulatorDirect("addresses.txt", 10, 4, 2, "direto1.txt")
cacheSimulatorDirect("addresses.txt", 10, 5, 1, "direto2.txt")
cacheSimulatorAssoc("addresses.txt", 14, 2, 16, "assoc1.txt")
cacheSimulatorAssoc("addresses.txt", 15, 1, 32, "assoc2.txt")