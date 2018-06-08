
function New-Cache {
    param(
        [Parameter(Mandatory=$true)]$lineSize,
        [Parameter(Mandatory=$true)]$wordSize
    )
    $cache = @()
    for($i = 0; $i -lt [Math]::Pow(2,$lineSize); $i++) {
        $cache += 1 | Select-Object @{n="v"; e={0}},
                                    @{n="tag"; e={0}},
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

function Invoke-CacheSimulator {
    param(
        [Parameter(Mandatory, Position=0)][int[]] $data,
        [Parameter(Mandatory, Position=1)]$tagSize,
        [Parameter(Mandatory, Position=2)]$lineSize,
        [Parameter(Mandatory, Position=3)]$wordSize
    )

    $result = @()
    $addressSize = $tagSize + $lineSize + $wordSize

    $cache = New-Cache -lineSize $lineSize -wordSize $wordSize;
    for($i = 0; $i -lt $data.Count; $i++) {
        $objResultLine = 1 | Select-Object @{n="Byte"; e={}},
                                           @{n="Tag"; e={}},
                                           @{n="Line"; e={}},
                                           @{n="Word"; e={}},
                                           @{n="Cache"; e={}},
                                           @{n="Hit"; e={}}

        $tag = $data[$i] -shr ($addressSize-$tagSize);
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

        $addressSize = $tagSize + $lineSize + $wordSize
        $fTagSize = [Math]::Max($tagSize, 3)
        $fLineSize = [Math]::Max($lineSize, 4)
        $fWordSize = [Math]::Max($wordSize, 4)

        $format = "{0,-$addressSize} | {1,-$fTagSize} | {2,-$fLineSize} | {3,-$fWordSize} | {4,-4} | {5,-$fLineSize} | {6,-1} | {7,-$fTagSize} | {8,-$($addressSize * [Math]::Pow(2,$wordSize) + ([Math]::Pow(2,$wordSize))-1)}"
        $output += $($format -f "Byte", "Tag", "Line", "Word", "Hit", "Line", "V", "Tag", "Data")
        $output += $($format -f "----", "---", "----", "----", "---", "----", "-", "---", "----")
        $output += $($format -f "","","","","","","","","")
    }

    PROCESS {
        foreach($line in $cache) {
            $linesCount++
            if($line.Hit -eq "Hit") {
                $hitsCount++
            }

            for($i = 0; $i -lt $line.Cache.Count; $i++) {
                if($i -eq 0) {
                    $output += $($format -f (ConvertTo-Binary $line.Byte $addressSize), (ConvertTo-Binary $line.Tag $tagSize), (ConvertTo-Binary $line.Line $lineSize), (ConvertTo-Binary $line.Word $wordSize), $line.Hit,
                    (ConvertTo-Binary $i $lineSize), [Convert]::ToString($line.Cache[$i].v), (ConvertTo-Binary $line.Cache[$i].Tag $tagSize), $(($line.Cache[$i].data | % {ConvertTo-Binary $_ $addressSize}) -join " "))
                } else {
                    $output += $($format -f "", "", "", "", "",
                    (ConvertTo-Binary $i $lineSize), [Convert]::ToString($line.Cache[$i].v), (ConvertTo-Binary $line.Cache[$i].Tag $tagSize), $(($line.Cache[$i].data | % {ConvertTo-Binary $_ $addressSize}) -join " "))
                }
            }
            $output += $($format -f "","","","","","","","","")
        }
    }
    
    END {
        $output += "`nFrequência de Hits: $($hitsCount / $linesCount * 100)%"
        return $output
    }
}

#$d = ConvertFrom-Binary @(100000, 011000, 011001, 111100, 001111, 111111, 000000, 000101, 011010, 100011)
#$t = 2
#$l = 2
#$w = 2

#$d = 0x0000, 0x0002, 0x0004, 0x0006, 0x0008, 0x0048, 0x004a, 0x004c, 0x00c6, 0x004e, 0x0050
$d = Get-Content addresses.txt
#Invoke-CacheSimulator $d 10 4 2
Invoke-CacheSimulator $d 10 4 2 | printCache 10 4 2 | Out-File associativo1.txt
Invoke-CacheSimulator $d 10 5 1 | printCache 10 5 1 | Out-File associativo2.txt