
function New-Cache {
    param(
        [Parameter(Mandatory=$true)]$lineSize,
        [Parameter(Mandatory=$true)]$wordSize
    )
    $cache = @()
    for($i = 0; $i -lt [Math]::Pow(2,$lineSize); $i++) {
        $cache += 1 | Select-Object @{n="line"; e={$i}},
                                    @{n="v";    e={0}},
                                    @{n="tag";  e={0}},
                                    @{n="data"; e={@()}}

        for($j = 0; $j -lt [Math]::Pow(2,$wordSize); $j++) {
            $cache[$i].data += @($null)
        }
    }
    return $cache;
}

function ConvertFrom-Binary([int[]] $n) {
    $d = New-Object int[] $n.Count
    for($i = 0; $i -lt $n.Count; $i++) {
        $d[$i] = [Convert]::ToInt32($n[$i],2)
    }
    return $d
}


function ConvertTo-Binary([int] $n, $addressSize = 16) {
    return "{0:d$addressSize}" -f [Convert]::ToInt32(([Convert]::ToString($n, 2)))
}

function ConvertTo-Hex([int] $n, $size = 4) {
    return "{0:x$size}" -f $n
}

function Invoke-CacheSimulator {
    param(
        [Parameter(Mandatory, Position=0)][int[]]$data,
        [Parameter(Mandatory, Position=1)]$tagSize,
        [Parameter(Mandatory, Position=2)]$lineSize,
        [Parameter(Mandatory, Position=3)]$wordSize
    )

    $result = @()
    $addressSize = $tagSize + $lineSize + $wordSize

    $cache = New-Cache -lineSize $lineSize -wordSize $wordSize;
    for($i = 0; $i -lt $data.Count; $i++) {
        $objResultLine = 1 | Select-Object @{n="Byte";  e={}},
                                           @{n="Tag";   e={}},
                                           @{n="Line";  e={}},
                                           @{n="Word";  e={}},
                                           @{n="Cache"; e={}},
                                           @{n="Hit";   e={}}

        $tag = $data[$i] -shr ($addressSize-$tagSize)
        $line = ($data[$i] -band [Math]::Pow(2,$addressSize-$tagSize)-1) -shr $wordSize
        $word = $data[$i] -band [Math]::Pow(2,$wordSize)-1

        $objResultLine.Byte = $data[$i]
        $objResultLine.Tag = $tag
        $objResultLine.Line = $line
        $objResultLine.Word = $word

        $cac = New-Cache -lineSize $lineSize -wordSize $wordSize
        for($n = 0; $n -lt $cache.Count; $n++) {
            $cac[$n].v = $cache[$n].v
            $cac[$n].tag = $cache[$n].tag
            for($o = 0; $o -lt $cache[$n].data.Count; $o++) {
                $cac[$n].data[$o] = $cache[$n].data[$o]
            }
        }
        $objResultLine.Cache = $cac

        if($cache[$line].v -and $cache[$line].tag -eq $tag -and $cache[$line].data -contains $data[$i]) {
            $objResultLine.Hit = "Hit"
        } else {
            if($cache[$line].v -eq 0) {
                $cache[$line].v = 1
            }
            $cache[$line].tag = $tag;
            $b = $data[$i] -band (-bnot ([Math]::Pow(2,$wordSize)-1))
            for($j = 0; $j -lt $cache[$line].data.Count; $j++) {
                $cache[$line].data[$j] = $b + $j
            }
            $objResultLine.Hit = "Miss"
        }

        $result += $objResultLine
    }
    return $result
}

function Invoke-CacheSimulatorAssoc {
    param(
        [Parameter(Mandatory, Position=0)][int[]]$data,
        [Parameter(Mandatory, Position=1)]$tagSize,
        [Parameter(Mandatory, Position=2)]$wordSize,
        [Parameter(Mandatory, Position=3)]$cacheSize
    )

    $result = @()
    $addressSize = $tagSize + $wordSize
    $assocMem = New-Object int[] $cacheSize
    $cache = New-Cache ([Math]::Log($cacheSize, 2)) $wordSize
    $currentLine = 0

    for($i = 0; $i -lt $data.Count; $i++) {
        $objResultLine = 1 | Select-Object @{n="Byte"; e={}},
                                           @{n="Tag"; e={}},
                                           @{n="Word"; e={}},
                                           @{n="Cache"; e={}},
                                           @{n="Hit"; e={}}

        $tag = $data[$i] -shr ($addressSize-$tagSize)
        $word = $data[$i] -band [Math]::Pow(2,$wordSize)-1

        $objResultLine.Byte = $data[$i]
        $objResultLine.Tag = $tag
        $objResultLine.Word = $word

        $cac = New-Cache ([Math]::Log($cacheSize, 2)) $wordSize
        for($n = 0; $n -lt $cache.Count; $n++) {
            $cac[$n].v = $cache[$n].v
            $cac[$n].tag = $cache[$n].tag
            for($o = 0; $o -lt $cache[$n].data.Count; $o++) {
                $cac[$n].data[$o] = $cache[$n].data[$o]
            }
        }
        $objResultLine.Cache = $cac

        $tagFound = $false
        for($j = 0; $j -lt $assocMem.Count; $j++) {
            if($assocMem[$j] -eq $tag) {
                if($cache[$j].data -contains $word) {
                    $objResultLine.Hit = "Hit"
                } else {
                    $objResultLine.Hit = "Miss"
                    for($k = 0; $k -lt $cache[$j].data.Count; $k++) {
                        $cache[$j].data[$k] = $k
                    }
                }
                $tagFound = $true
                continue
            }
        }
        if(!$tagFound) {
            $objResultLine.Hit = "Miss"
            $assocMem[$currentLine] = $tag
            for($k = 0; $k -lt $cache[$j].data.Count; $k++) {
                $cacheSize[$j].data[$k] = $k
            }
            $currentLine = ($currentLine+1) % $assocMem.Count
        }
        for($j = 0; $j -lt $objResultLine.Cache.Count; $j++) {
            $objResultLine.Cache[$j].tag = $assocMem[$j]
        }

        $result += $objResultLine
    }

    return $result
}

function printCache {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory, Position=3, ValueFromPipeline)]$cache,
        [Parameter(Mandatory, Position=0)]$tagSize,
        [Parameter(Mandatory, Position=1)]$lineSize,
        [Parameter(Mandatory, Position=2)]$wordSize
    )

    BEGIN {
        $output = @()
        $hitsCount = 0
        $linesCount = 0

        $states = @()

        $addressSize = $tagSize + $lineSize + $wordSize
        $hexSize = [Math]::Ceiling($addressSize / 4)
    }

    PROCESS {
        $linesCount++
        if($cache.Hit -eq "Hit") {
            $hitsCount++
        }

        $states += $cache | Select-Object @{n="Hex"; e={ConvertTo-Hex $_.Byte $hexSize}}, Byte, Tag, Line, Word, Hit
    }
    
    END {
        $output += ($states | Select-Object @{n="Hex";  e={ConvertTo-Hex $_.Byte $hexSize}},
                                            @{n="Byte"; e={ConvertTo-Binary $_.Byte $addressSize}},
                                            @{n="Tag";  e={ConvertTo-Binary $_.Tag $tagSize}},
                                            @{n="Line"; e={ConvertTo-Binary $_.Line $lineSize}},
                                            @{n="Word"; e={ConvertTo-Binary $_.Word $wordSize}},
                                            Hit
        ) | Format-Table -AutoSize
        $output += "Estado final da cache:"
        $output += ($cache.Cache | Select-Object @{n="Line"; e={ConvertTo-Binary $_.line $lineSize}},
                                                 v,
                                                 @{n="Tag"; e={ConvertTo-Binary $_.Tag $tagSize}},
                                                 @{n="Data"; e={($_.data | % {ConvertTo-Binary $_ $addressSize}) -join " "}}
        )| Format-Table -AutoSize
        $output += "Endereços:          $linesCount"
        $output += "Hits:               $hitsCount"
        $output += "Misses:             $($linesCount - $hitsCount)"
        $output += "Frequência de Hits: $($hitsCount / $linesCount * 100)%"
        return $output
    }
}

function printCacheAssoc {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=3, ValueFromPipeline)]$cache,
        [Parameter(Mandatory, Position=0)]$tagSize,
        [Parameter(Mandatory, Position=1)]$wordSize,
        [Parameter(Mandatory, Position=2)]$cacheSize
    )

    BEGIN {
        $output = @()
        $hitsCount = 0
        $linesCount = 0

        $states = @()

        $addressSize = $tagSize + $lineSize + $wordSize
        $hexSize = [Math]::Ceiling($addressSize / 4)
    }

    PROCESS {
        $linesCount++
        if($cache.Hit -eq "Hit") {
            $hitsCount++
        }

        $states += $cache | Select-Object @{n="Hex"; e={ConvertTo-Hex $_.Byte $hexSize}}, Byte, Tag, Word, Hit
    }

    END {
        $output += ($states | Select-Object @{n="Hex";  e={ConvertTo-Hex $_.Byte $hexSize}},
                                            @{n="Byte"; e={ConvertTo-Binary $_.Byte $addressSize}},
                                            @{n="Tag";  e={ConvertTo-Binary $_.Tag $tagSize}},
                                            @{n="Word"; e={ConvertTo-Binary $_.Word $wordSize}},
                                            Hit
        ) | Format-Table -AutoSize
        $output += "Estado final da cache:"
        $output += ($cache.Cache | Select-Object @{n="Line"; e={ConvertTo-Binary $_.line ([Math]::Log($cacheSize, 2))}},
                                                 @{n="Assoc"; e={ConvertTo-Binary $_.tag $tagSize}},
                                                 @{n="Data"; e={($_.data | % {ConvertTo-Binary $_ $wordSize}) -join " "}}
        )| Format-Table -AutoSize
        $output += "Endereços:          $linesCount"
        $output += "Hits:               $hitsCount"
        $output += "Misses:             $($linesCount - $hitsCount)"
        $output += "Frequência de Hits: $($hitsCount / $linesCount * 100)%"
        return $output
    }
}

function printCacheAll {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory, Position=3, ValueFromPipeline)]$cache,
        [Parameter(Mandatory, Position=0)]$tagSize,
        [Parameter(Mandatory, Position=1)]$lineSize,
        [Parameter(Mandatory, Position=2)]$wordSize
    )

    BEGIN {
        $output = @()
        $hitsCount = 0
        $linesCount = 0

        $addressSize = $tagSize + $lineSize + $wordSize
        $hexSize = [Math]::Ceiling($addressSize / 4)
        $fHexSize = [Math]::Max($hexSize, 3)
        $fTagSize = [Math]::Max($tagSize, 3)
        $fLineSize = [Math]::Max($lineSize, 4)
        $fWordSize = [Math]::Max($wordSize, 4)

        $format = "{0,-$fHexSize} | {1,-$addressSize} | {2,-$fTagSize} | {3,-$fLineSize} | {4,-$fWordSize} | {5,-4} | {6,-$fLineSize} | {7,-1} | {8,-$fTagSize} | {9,-$($addressSize * [Math]::Pow(2,$wordSize) + ([Math]::Pow(2,$wordSize))-1)}"
        $output += $($format -f "Hex", "Byte", "Tag", "Line", "Word", "Hit", "Line", "V", "Tag", "Data")
        $output += $($format -f "---", "----", "---", "----", "----", "---", "----", "-", "---", "----")
        $output += $($format -f "","","","","","","","","","")
    }

    PROCESS {
        $linesCount++
        if($cache.Hit -eq "Hit") {
            $hitsCount++
        }

        for($i = 0; $i -lt $cache.Cache.Count; $i++) {
            if($i -eq 0) {
                $output += $($format -f (ConvertTo-Hex $cache.Byte $hexSize), (ConvertTo-Binary $cache.Byte $addressSize), (ConvertTo-Binary $cache.Tag $tagSize), (ConvertTo-Binary $cache.Line $lineSize), (ConvertTo-Binary $cache.Word $wordSize), $cache.Hit,
                (ConvertTo-Binary $cache.Cache[$i].line $lineSize), [Convert]::ToString($cache.Cache[$i].v), (ConvertTo-Binary $cache.Cache[$i].Tag $tagSize), $(($cache.Cache[$i].data | % {ConvertTo-Binary $_ $addressSize}) -join " "))
            } else {
                $output += $($format -f "", "", "", "", "", "",
                (ConvertTo-Binary $cache.Cache[$i].line $lineSize), [Convert]::ToString($cache.Cache[$i].v), (ConvertTo-Binary $cache.Cache[$i].Tag $tagSize), $(($cache.Cache[$i].data | % {ConvertTo-Binary $_ $addressSize}) -join " "))
            }
        }
        $output += $($format -f "","","","","","","","","","")
    }
    
    END {
        $output += "`nFrequência de Hits: $($hitsCount / $linesCount * 100)%"
        return $output
    }
}

function printCacheAllAssoc {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory, Position=3, ValueFromPipeline)]$cache,
        [Parameter(Mandatory, Position=0)]$tagSize,
        [Parameter(Mandatory, Position=1)]$wordSize,
        [Parameter(Mandatory, Position=2)]$cacheSize
    )

    BEGIN {
        $output = @()
        $hitsCount = 0
        $linesCount = 0

        $addressSize = $tagSize + $wordSize
        $lineSize = [Math]::Log($cacheSize, 2)
        $hexSize = [Math]::Ceiling($addressSize / 4)
        $fHexSize = [Math]::Max($hexSize, 3)
        $fTagSize = [Math]::Max($tagSize, 5)
        $fLineSize = [Math]::Max($lineSize, 4)
        $fWordSize = [Math]::Max($wordSize, 4)

        $format = "{0,-$fHexSize} | {1,-$addressSize} | {2,-$fTagSize} | {3,-$fLineSize} | {4,-$fWordSize} | {5,-4} | {6,-$fLineSize} | {7,-1} | {8,-$fTagSize} | {9,-$($addressSize * [Math]::Pow(2,$wordSize) + ([Math]::Pow(2,$wordSize))-1)}"
        $output += $($format -f "Hex", "Byte", "Tag", "Line", "Word", "Hit", "Line", "V", "Assoc", "Data")
        $output += $($format -f "---", "----", "---", "----", "----", "---", "----", "-", "-----", "----")
        $output += $($format -f "","","","","","","","","","")
    }

    PROCESS {
        $linesCount++
        if($cache.Hit -eq "Hit") {
            $hitsCount++
        }

        for($i = 0; $i -lt $cache.Cache.Count; $i++) {
            if($i -eq 0) {
                $output += $($format -f (ConvertTo-Hex $cache.Byte $hexSize), (ConvertTo-Binary $cache.Byte $addressSize), (ConvertTo-Binary $cache.Tag $tagSize), (ConvertTo-Binary $cache.Line $lineSize), (ConvertTo-Binary $cache.Word $wordSize), $cache.Hit,
                (ConvertTo-Binary $cache.Cache[$i].line $lineSize), [Convert]::ToString($cache.Cache[$i].v), (ConvertTo-Binary $cache.Cache[$i].Tag $tagSize), $(($cache.Cache[$i].data | % {ConvertTo-Binary $_ $wordSize}) -join " "))
            } else {
                $output += $($format -f "", "", "", "", "", "",
                (ConvertTo-Binary $cache.Cache[$i].line $lineSize), [Convert]::ToString($cache.Cache[$i].v), (ConvertTo-Binary $cache.Cache[$i].Tag $tagSize), $(($cache.Cache[$i].data | % {ConvertTo-Binary $_ $wordSize}) -join " "))
            }
        }
        $output += $($format -f "","","","","","","","","","")
    }
    
    END {
        $output += "`nEndereços:          $linesCount"
        $output += "Hits:               $hitsCount"
        $output += "Misses:             $($linesCount - $hitsCount)"
        $output += "Frequência de Hits: $($hitsCount / $linesCount * 100)%"
        return $output
    }
}

#$d = ConvertFrom-Binary @(100000, 011000, 011001, 111100, 001111, 111111, 000000, 000101, 011010, 100011)
#$t = 2
#$l = 2
#$w = 2

#$d = 0x0000, 0x0002, 0x0004, 0x0006, 0x0008, 0x0048, 0x004a, 0x004c, 0x00c6, 0x004e, 0x0050
$d = Get-Content addresses.txt
Write-Host direto1
Invoke-CacheSimulator $d 10 4 2 | printCache 10 4 2 | Out-File direto1.txt

Write-Host direto2
Invoke-CacheSimulator $d 10 5 1 | printCache 10 5 1 | Out-File direto2.txt

Write-Host assoc1
Invoke-CacheSimulatorAssoc $d 14 2 16 | printCacheAssoc 14 2 16 | Out-File assoc1.txt

Write-Host assoc2
Invoke-CacheSimulatorAssoc $d 15 1 32 | printCacheAssoc 15 1 32 | Out-File assoc2.txt