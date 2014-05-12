###Functions
function New-IndexObject([string]$Server, [int]$Port, [string[]]$Indexes) {
    #Method Definitions
    $deleteMethod = {
        if ($this.Status -eq "Online") {
            Try {
                $response = Invoke-WebRequest -Method Delete -Uri ("http://" + $this.Server + ":" + $this.Port + "/" + $This.Index)

                if ($response.StatusCode -eq 200) {
                    Write-Host -ForegroundColor Green -NoNewline "[DELETED]"
                    $this.Status = "Deleted"
                } else {
                    Write-Warning ("Returned " + $response.StatusCode + " response")
                }
            }

            Catch {
                Write-Host -ForegroundColor Red -NoNewline "[ERROR]"
            }
        } else {
            Write-Host -ForegroundColor Yellow -NoNewline "[SKIPPED]"
        }
        
        Write-Host (" - " + $this.Server + "/" + $this.Index)
    }

    $optimizeMethod = {
        if ($this.Status -eq "Online") {
            Try {
                $response = Invoke-WebRequest -Method Post -Uri ("http://" + $this.Server + ":" + $this.Port + "/" + $this.Index + "/_optimize")

                if ($response.StatusCode -eq 200) {
                    $results = $($response.Content | ConvertFrom-Json)._shards

                    if ($results.failed -ne 0) {
                        Write-Host -ForegroundColor Red -NoNewline "[ERROR]"
                    } elseif ($results.successful -lt $results.total) {
                        Write-Host -ForegroundColor DarkYellow -NoNewline "[WARN]"
                    } else {
                        Write-Host -ForegroundColor Green -NoNewline "[OPTIMIZED]"
                    }
                } else {
                    Write-Host -ForegroundColor Red -NoNewline "[ERROR]"
                    $results = ("Returned " + $response.StatusCode + " response")
                }
            }

            Catch {
                Write-Host -ForegroundColor Red -NoNewline "[ERROR]"
            }
        } else {
            Write-Host -ForegroundColor Yellow -NoNewline "[SKIPPED]"
        }

        Write-Host (" - " + $this.Server + "/" + $this.Index + " ($results)")
    }

    $flushMethod = {
        if ($this.Status -eq "Online") {
            Try {
                $response = Invoke-WebRequest -Method Post -Uri ("http://" + $this.Server + ":" + $this.Port + "/" + $This.Index + "/_flush")

                if ($response.StatusCode -eq 200) {
                    Write-Host -ForegroundColor Green -NoNewline "[FLUSHED]"
                } else {
                    Write-Warning ("Returned " + $response.StatusCode + " response")
                }
            }

            Catch {
                Write-Host -ForegroundColor Red -NoNewline "[ERROR]"
            }
        } else {
            Write-Host -ForegroundColor Yellow -NoNewline "[SKIPPED]"
        }

        Write-Host (" - " + $this.Server + "/" + $this.Index)
    }

    $clearCacheMethod = {
        if ($this.Status -eq "Online") {
            Try {
                $response = Invoke-WebRequest -Method Post -Uri ("http://" + $this.Server + ":" + $this.Port + "/" + $This.Index + "/_cache/clear")

                if ($response.StatusCode -eq 200) {
                    Write-Host -ForegroundColor Green -NoNewline "[CACHE_CLEARED]"
                } else {
                    Write-Warning ("Returned " + $response.StatusCode + " response")
                }
            }

            Catch {
                Write-Host -ForegroundColor Red -NoNewline "[ERROR]"
            }
        } else {
            Write-Host -ForegroundColor Yellow -NoNewline "[SKIPPED]"
        }

        Write-Host (" - " + $this.Server + "/" + $this.Index)
    }

    $refreshMethod = {
        if ($this.Status -eq "Online") {
            Try {
                $response = Invoke-WebRequest -Method Post -Uri ("http://" + $this.Server + ":" + $this.Port + "/" + $This.Index + "/_refresh")

                if ($response.StatusCode -eq 200) {
                    Write-Host -ForegroundColor Green -NoNewline "[REFRESHED]"
                } else {
                    Write-Warning ("Returned " + $response.StatusCode + " response")
                }
            }

            Catch {
                Write-Host -ForegroundColor Red -NoNewline "[ERROR]"
            }
        } else {
            Write-Host -ForegroundColor Yellow -NoNewline "[SKIPPED]"
        }

        Write-Host (" - " + $this.Server + "/" + $this.Index)
    }

    $openMethod = {
        Try {
            $response = Invoke-WebRequest -Method Post -Uri ("http://" + $this.Server + ":" + $this.Port + "/" + $This.Index + "/_open")

            if ($response.StatusCode -eq 200) {
                Write-Host -ForegroundColor Green -NoNewline "[OPENED]"
                $this.Status = "Online"
            } else {
                Write-Warning ("Returned " + $response.StatusCode + " response")
            }
        }

        Catch {
            Write-Host -ForegroundColor Red -NoNewline "[ERROR]"
        }

        Write-Host (" - " + $this.Server + "/" + $this.Index)
    }

    $closeMethod = {
        if ($this.Status -eq "Online") {
            Try {
                $response = Invoke-WebRequest -Method Post -Uri ("http://" + $this.Server + ":" + $this.Port + "/" + $This.Index + "/_close")

                if ($response.StatusCode -eq 200) {
                    Write-Host -ForegroundColor Green -NoNewline "[CLOSED]"
                    $this.Status = "Offline"
                } else {
                    Write-Warning ("Returned " + $response.StatusCode + " response")
                }
            }

            Catch {
                Write-Host -ForegroundColor Red -NoNewline "[ERROR]"
            }
        } else {
            Write-Host -ForegroundColor Yellow -NoNewline "[SKIPPED]"
        }

        Write-Host (" - " + $this.Server + "/" + $this.Index)
    }

    #Object Construction
    foreach ($i in $Indexes) {
        $objIndex = New-Object -TypeName PSObject
        
        $objIndex | Add-Member -MemberType NoteProperty -Name Server -Value $Server
        $objIndex | Add-Member -MemberType NoteProperty -Name Port -Value $Port
        $objIndex | Add-Member -MemberType NoteProperty -Name Index -Value $i
        $objIndex | Add-Member -MemberType NoteProperty -Name Age -Value $(Get-EsIndexAge -Index $i)
        $objIndex | Add-Member -MemberType NoteProperty -Name Status -Value "Online"
        $objIndex | Add-Member -MemberType ScriptMethod -Name Delete -Value $deleteMethod
        $objIndex | Add-Member -MemberType ScriptMethod -Name Optimize -Value $optimizeMethod
        $objIndex | Add-Member -MemberType ScriptMethod -Name Flush -Value $flushMethod
        $objIndex | Add-Member -MemberType ScriptMethod -Name ClearCache -Value $clearCacheMethod
        $objIndex | Add-Member -MemberType ScriptMethod -Name Refresh -Value $refreshMethod
        $objIndex | Add-Member -MemberType ScriptMethod -Name OpenIndex -Value $openMethod
        $objIndex | Add-Member -MemberType ScriptMethod -Name CloseIndex -Value $closeMethod

        $objIndex
    }
}

function Get-EsIndexAge([Parameter(Mandatory=$true)][string]$Index, [regex]$Pattern="^\w+[-\.](\d+)[-\.](\d+)[-\.](\d+)([-\.](\d+))*") {
    if ($Index -match $Pattern) {
        switch($Matches.Count) {
            4 { $span = $(Get-Date).ToUniversalTime() - $(Get-Date ($Matches[2] + "/" + $Matches[3] + "/" + $Matches[1])) } #Daily Indexes
            6 { $span = $(Get-Date).ToUniversalTime() - $(Get-Date ($Matches[2] + "/" + $Matches[3] + "/" + $Matches[1] + " " + $Matches[5] + ":00:00")) } #Hourly Indexes
        }

        return $span
    }
}

function Get-EsIndexes([string]$Server="localhost", [int]$Port=9200, [string]$IndexPrefix=".*") {
    Try {
        $response = Invoke-WebRequest -Method Get -Uri ("http://" + $Server + ":" + $Port + "/_aliases?pretty=true")

        if ($response.StatusCode -eq 200) {
            $indexes = $response.Content.Split(":`r`n") -replace " ","" -replace """","" | Where-Object { ($_ -match "^\w+") -and ($_ -ne "aliases") } | Select-String $IndexPrefix | Sort-Object
        } else {
            Write-Warning ("Returned " + $response.StatusCode + " response")
        }
    }

    Catch {
        Throw ("Error retrieving indexes: " + $Error[0])
    }

    New-IndexObject -Server $Server -Port $Port -Indexes $indexes
}
