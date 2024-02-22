function Invoke-GzipCompressionTest {
#.SYNOPSIS
# Attempt Gzip compression through PowerShell
# ARBITRARY VERSION NUMBER:  1.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# Script to automate the process of returning the Base64 string of a Gzip
# compressed binary, specifically to reduce the size of 'Invoke-<Tool.ps1'
# wrappers.  By default, the binary is compressed and decompressed with
# informational output to validate that no bytes were lost due to
# unforeseen errors.
# 
# Parameters:
#   -Binary      -->  Target binary to compress.
#   -ReturnB64   -->  Return the Base64 encoded Gzip compressed stream.
#   -Help        -->  Return Get-Help information
#
# Usage:
#   Invoke-GzipCompressionTest -Binary "C:\Windows\Temp\Rubeus.exe"
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory


    Param (
        [string]$Binary,
        [switch]$ReturnB64,
        [switch]$Help
    )


    if ($Help)     { return (Get-Help Invoke-GzipCompressionTest) }
    if (!$Binary)  { return '[-] Must input target binary.' }

    $BinaryPath = (Get-Item -Path $Binary).FullName 2>$NULL
    if (!$BinaryPath) { return '[-] Unable to determine absolute filepath to binary.' }



    # Begin Compression
    $FileStream = [IO.MemoryStream]::new([IO.File]::ReadAllBytes($BinaryPath))
    $CompressedStream = [IO.MemoryStream]::new()
    $Gzip = [IO.Compression.GzipStream]::new($CompressedStream, [IO.Compression.CompressionMode]::Compress)
    $FileStream.CopyTo($Gzip)
    $Gzip.Close()
    $Base64 = [Convert]::ToBase64String($CompressedStream.ToArray())


    # Continue Compression Test
    if (!$ReturnB64) {
        Write-Host "[+] Gzip Compression" -ForegroundColor Yellow
        Write-Host " o  Original Byte Stream     : $($FileStream.Length) bytes"
        Write-Host " o  Gzip Compressed Stream   : $(($CompressedStream.ToArray()).Length) bytes"
        Write-Host " o  Base64 Compressed Stream : $($Base64.Length) chars"


        # Begin Decompression
        $Bytes = [IO.MemoryStream]::new([Convert]::FromBase64String($Base64))
        $Gzip = [IO.Compression.GzipStream]::new($Bytes, [IO.Compression.CompressionMode]::Decompress)
        $DecompressedStream = [IO.MemoryStream]::new()
        $Gzip.CopyTo($DecompressedStream)


        Write-Host "[+] Gzip Decompression" -ForegroundColor Yellow
        Write-Host " o  Base64 Compressed Stream : $($Base64.Length) chars"
        Write-Host " o  Gzip Compressed Stream   : $(($Bytes.ToArray()).Length) bytes"
        Write-Host " o  Decompressed Byte Stream : $($DecompressedStream.Length) bytes"


        if ($FileStream.Length -eq $DecompressedStream.Length) {
            Write-Host "`n[!] Compression test succeeded!" -ForegroundColor Green
            Write-Host " o  Use the '-ReturnB64' parameter to return the Base64 string.`n"
        }
        else { Write-Host "`n[!] Compression test failed!`n" -ForegroundColor Red }

        return
    }


    # Return Base64 Encoded Compressed Stream
    if ($ReturnB64) { return $Base64 }
}