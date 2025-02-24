﻿function Set-PrivateRegistry {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [System.Collections.IDictionary] $RegistryValue,
        [string] $Computer,
        [switch] $Remote,
        [switch] $Suppress
    )
    if ($RegistryValue.ComputerName) {
        if ($RegistryValue.ComputerName -ne $Computer) {
            return
        }
    }
    try {
        if ($Remote) {
            $BaseHive = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryValue.HiveKey, $Computer, 0 )
        } else {
            $BaseHive = [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryValue.HiveKey, 0 )
        }
        $PSConnection = $true
        $PSError = $null
    } catch {
        $PSConnection = $false
        $PSError = $($_.Exception.Message)
        if ($PSBoundParameters.ErrorAction -eq 'Stop') {
            if ($null -ne $BaseHive) {
                $BaseHive.Close()
                $BaseHive.Dispose()
            }
            throw
        } else {
            Write-Warning "Set-PSRegistry - Setting registry $($RegistryValue.HiveKey)\$($RegistryValue.SubKeyName) on $($RegistryValue.Key) to $($RegistryValue.Value) of $($RegistryValue.ValueKind) on $Computer have failed. Error: $($_.Exception.Message.Replace([System.Environment]::NewLine, " "))"
        }
    }
    if ($PSCmdlet.ShouldProcess($Computer, "Setting registry $($RegistryValue.HiveKey)\$($RegistryValue.SubKeyName) on $($RegistryValue.Key) to $($RegistryValue.Value) of $($RegistryValue.ValueKind)")) {
        if ($PSError) {
            if (-not $Suppress) {
                [PSCustomObject] @{
                    PSComputerName = $Computer
                    PSConnection   = $PSConnection
                    PSError        = $true
                    PSErrorMessage = $PSError
                    Path           = "$($RegistryValue.HiveKey)\$($RegistryValue.SubKeyName)"
                    Key            = $RegistryValue.Key
                    Value          = $RegistryValue.Value
                    Type           = $RegistryValue.ValueKind
                }
            }
        } else {
            try {
                #$BaseHive = [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryValue.HiveKey, 0 )
                $SubKey = $BaseHive.OpenSubKey($RegistryValue.SubKeyName, $true)
                if (-not $SubKey) {
                    $SubKeysSplit = $RegistryValue.SubKeyName.Split('\')
                    $SubKey = $BaseHive.OpenSubKey($SubKeysSplit[0], $true)
                    if (-not $SubKey) {
                        $SubKey = $BaseHive.CreateSubKey($SubKeysSplit[0])
                    }
                    $SubKey = $BaseHive.OpenSubKey($SubKeysSplit[0], $true)
                    foreach ($S in $SubKeysSplit | Select-Object -Skip 1) {
                        $SubKey = $SubKey.CreateSubKey($S)
                    }
                }
                if ($RegistryValue.ValueKind -eq [Microsoft.Win32.RegistryValueKind]::MultiString) {
                    $SubKey.SetValue($RegistryValue.Key, [string[]] $RegistryValue.Value, $RegistryValue.ValueKind)
                } elseif ($RegistryValue.ValueKind -in [Microsoft.Win32.RegistryValueKind]::None, [Microsoft.Win32.RegistryValueKind]::Binary) {
                    $SubKey.SetValue($RegistryValue.Key, [byte[]] $RegistryValue.Value, $RegistryValue.ValueKind)
                } else {
                    $SubKey.SetValue($RegistryValue.Key, $RegistryValue.Value, $RegistryValue.ValueKind)
                }
                if (-not $Suppress) {
                    [PSCustomObject] @{
                        PSComputerName = $Computer
                        PSConnection   = $PSConnection
                        PSError        = $false
                        PSErrorMessage = $null
                        Path           = "$($RegistryValue.HiveKey)\$($RegistryValue.SubKeyName)"
                        Key            = $RegistryValue.Key
                        Value          = $RegistryValue.Value
                        Type           = $RegistryValue.ValueKind
                    }
                }
            } catch {
                if ($PSBoundParameters.ErrorAction -eq 'Stop') {
                    if ($null -ne $SubKey) {
                        $SubKey.Close()
                        $SubKey.Dispose()
                    }
                    if ($null -ne $BaseHive) {
                        $BaseHive.Close()
                        $BaseHive.Dispose()
                    }
                    throw
                } else {
                    Write-Warning "Set-PSRegistry - Setting registry $($RegistryValue.HiveKey)\$($RegistryValue.SubKeyName) on $($RegistryValue.Key) to $($RegistryValue.Value) of $($RegistryValue.ValueKind) on $Computer have failed. Error: $($_.Exception.Message.Replace([System.Environment]::NewLine, " "))"
                }
                if (-not $Suppress) {
                    [PSCustomObject] @{
                        PSComputerName = $Computer
                        PSConnection   = $PSConnection
                        PSError        = $true
                        PSErrorMessage = $_.Exception.Message
                        Path           = "$($RegistryValue.HiveKey)\$($RegistryValue.SubKeyName)"
                        Key            = $RegistryValue.Key
                        Value          = $RegistryValue.Value
                        Type           = $RegistryValue.ValueKind
                    }
                }
            }
        }
    } else {
        if (-not $Suppress) {
            [PSCustomObject] @{
                PSComputerName = $Computer
                PSConnection   = $PSConnection
                PSError        = $true
                PSErrorMessage = if ($PSError) { $PSError } else { "WhatIf used - skipping registry setting" }
                Path           = "$($RegistryValue.HiveKey)\$($RegistryValue.SubKeyName)"
                Key            = $RegistryValue.Key
                Value          = $RegistryValue.Value
                Type           = $RegistryValue.ValueKind
            }
        }
    }
    if ($null -ne $SubKey) {
        $SubKey.Close()
        $SubKey.Dispose()
    }
    if ($null -ne $BaseHive) {
        $BaseHive.Close()
        $BaseHive.Dispose()
    }
}