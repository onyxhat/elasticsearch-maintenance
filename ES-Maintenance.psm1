###Exposed Functions
function Get-EsIndexes() {
    [CmdletBinding()]
    Param (
        [ValidateSet("http","https")]
        [string]$Protocol = "http",
        [string]$Server = "localhost",
        [int]$Port = 9200,
        [string]$IndexPrefix = ".*"
    )

    Begin {
        $r = Invoke-WebRequest -Method Get -Uri "${Protocol}://${Server}:${Port}/_aliases?pretty=true" -UseBasicParsing
        
        $defaultProperties = @('Name','Age','IsOnline','HasData')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$defaultProperties)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
    }

    Process {
        if ($r.StatusCode -eq 200) {
            $indexes = $r.Content.Split(":`r`n") -replace " ","" -replace """","" | Where-Object { ($_ -match "^\w+") -and ($_ -ne "aliases") } | Select-String $IndexPrefix | Sort-Object

            [psobject[]]$IndexObj = foreach ($i in $indexes) {
                $o = New-Object -TypeName psobject
                $o | Add-Member -MemberType NoteProperty -Name Name -Value $i
                $o | Add-Member -MemberType NoteProperty -Name Server -Value $Server
                $o | Add-Member -MemberType NoteProperty -Name Port -Value $Port
                $o | Add-Member -MemberType NoteProperty -Name BaseUrl -Value "${Protocol}://${Server}:${Port}"
                $o | Add-Member -MemberType NoteProperty -Name Output -Value $null
                $o | Add-Member -MemberType NoteProperty -Name Error -Value $null
                $o | Add-Member -MemberType ScriptProperty -Name HasData -Value { ($this.Output -ne $null) -or ($this.Error -ne $null) }
                $o | Add-Member -MemberType ScriptProperty -Name Age -Value { Get-EsIndexAge }
                $o | Add-Member -MemberType ScriptProperty -Name IsOnline -Value { Get-EsIndexState }
                $o | Add-Member -MemberType ScriptMethod -Name SetOpen -Value { Set-EsIndexOpen }
                $o | Add-Member -MemberType ScriptMethod -Name SetClosed -Value { Set-EsIndexClosed }
                $o | Add-Member -MemberType ScriptMethod -Name Merge -Value { Invoke-EsMerge }
                $o | Add-Member -MemberType ScriptMethod -Name Shrink -Value { Invoke-EsShrink }
                $o | Add-Member -MemberType ScriptMethod -Name Flush -Value { Invoke-EsFlush }
                $o | Add-Member -MemberType ScriptMethod -Name Remove -Value { Remove-EsIndex }

                $o.PSObject.TypeNames.Insert(0,'ES.Indexes')
                $o | Add-Member MemberSet PSStandardMembers $PSStandardMembers

                $o

            }
        } else {
            Throw ("$Server returned response [$($r.StatusCode)]")
        }
    }

    End {
        return $IndexObj
    }
}

###Helper Functions
function Get-EsIndexState() {
    Try {
        Invoke-RestMethod -Method Get -Uri "$($this.BaseUrl)/$($this.Name)/_stats" | Out-Null
        return $true
    }

    Catch {
        return $false
    }
}

function Get-EsIndexAge() {
    Begin {
        [regex]$Pattern="^\w+[-\.](\d+)[-\.](\d+)[-\.](\d+)([-\.](\d+))*"
    }

    Process {
        if ($this.Name -match $Pattern) {
            switch($Matches.Count) {
                4 { $span = $(Get-Date).ToUniversalTime() - $(Get-Date ($Matches[2] + "/" + $Matches[3] + "/" + $Matches[1])) } #Daily Indexes
                6 { $span = $(Get-Date).ToUniversalTime() - $(Get-Date ($Matches[2] + "/" + $Matches[3] + "/" + $Matches[1] + " " + $Matches[5] + ":00:00")) } #Hourly Indexes
            }
        }
    }

    End {
        return $span
    }
}

function Remove-EsIndex() {
    Write-Host "$($this.Name) " -NoNewline

    if ($this.IsOnline) {
        Try {
            $this.Output = Invoke-RestMethod -Method Delete -Uri "$($this.BaseUrl)/$($this.Name)"
            Write-Host -ForegroundColor Green "[DELETED]"
        }

        Catch {
            $this.Error = $_.Exception.Message
            Write-Host -ForegroundColor Red "[ERROR]"
        }
    } else {
        Write-Host -ForegroundColor Yellow "[SKIPPED]"
    }
}

function Set-EsIndexOpen() {
    Write-Host "$($this.Name) " -NoNewline

    if (!$this.IsOnline) {
        Try {
            $this.Output = Invoke-RestMethod -Method Post -Uri "$($this.BaseUrl)/$($this.Name)/_open"
            Write-Host -ForegroundColor Green "[OPENED]"
        }

        Catch {
            $this.Error = $_.Exception.Message
            Write-Host -ForegroundColor Red "[ERROR]"
        }
    } else {
        Write-Host -ForegroundColor Yellow "[SKIPPED]"
    }
}

function Set-EsIndexClosed() {
    Write-Host "$($this.Name) " -NoNewline

    if ($this.IsOnline) {
        Try {
            $this.Output = Invoke-RestMethod -Method Post -Uri "$($this.BaseUrl)/$($this.Name)/_close"
            Write-Host -ForegroundColor Green "[CLOSED]"
        }

        Catch {
            $this.Error = $_.Exception.Message
            Write-Host -ForegroundColor Red "[ERROR]"
        }
    } else {
        Write-Host -ForegroundColor Yellow "[SKIPPED]"
    }
}

function Invoke-EsMerge() {
    Write-Host "$($this.Name) " -NoNewline

    if ($this.IsOnline) {
        Try {
            $this.Output = Invoke-RestMethod -Method Post -Uri "$($this.BaseUrl)/$($this.Name)/_forcemerge"
            Write-Host -ForegroundColor Green "[MERGED]"
        }

        Catch {
            $this.Error = $_.Exception.Message
            Write-Host -ForegroundColor Red "[ERROR]"
        }
    } else {
        Write-Host -ForegroundColor Yellow "[SKIPPED]"
    }
}

function Invoke-EsFlush() {
    Write-Host "$($this.Name) " -NoNewline

    if ($this.IsOnline) {
        Try {
            $this.Output = Invoke-RestMethod -Method Post -Uri "$($this.BaseUrl)/$($this.Name)/_flush"
            Write-Host -ForegroundColor Green "[FLUSHED]"
        }

        Catch {
            $this.Error = $_.Exception.Message
            Write-Host -ForegroundColor Red "[ERROR]"
        }
    } else {
        Write-Host -ForegroundColor Yellow "[SKIPPED]"
    }
}

function Invoke-EsShrink() {
    Write-Host "$($this.Name) " -NoNewline

    if ($this.IsOnline) {
        Try {
            Set-EsIndexReadOnly
            
            $this.Output = Invoke-RestMethod -Method Post -Uri "$($this.BaseUrl)/$($this.Name)/_shrink/$($this.Name)_shrunk"
            Write-Host -ForegroundColor Green "[SHRUNK]"
        }

        Catch {
            $this.Error = $_.Exception.Message
            Write-Host -ForegroundColor Red "[ERROR]"
        }
    } else {
        Write-Host -ForegroundColor Yellow "[SKIPPED]"
    }
}

function Set-EsIndexReadOnly() {
    if ($this.IsOnline) {
        $Settings = @{
            settings = @{
                "index.routing.allocation.require._name" = "$($this.Name)_shrunk"
                "index.blocks.write" = $true
            }
        }

        $this.Output = Invoke-RestMethod -Method Put -Uri "$($this.BaseUrl)/$($this.Name)/_shrink/$($this.Name)_shrunk" -Body $Settings -ContentType 'application/json'
    } else {
        Throw "Index [$($this.Name)] is offline"
    }
}
