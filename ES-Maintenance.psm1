###Exposed Functions
function Get-EsIndexes() {
    [CmdletBinding()]
    Param (
        [ValidateSet("http","https")]
        [string]$Protocol = "http",
        [string]$Server = "localhost",
        [int]$Port = 9200,
        [string]$IndexPrefix = "*"
    )

    Begin {
        $indexes = Invoke-RestMethod -Method Get -Uri "${Protocol}://${Server}:${Port}/_aliases?pretty=true" | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ? { $_ -like $IndexPrefix }
        $clusterNodes = Get-EsClusterNodes
        
        $defaultProperties = @('IndexName','Age','IsOnline','HasData')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$defaultProperties)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
    }

    Process {
        [psobject[]]$IndexObj = foreach ($i in $indexes) {
            $o = New-Object -TypeName psobject
            $o | Add-Member -MemberType NoteProperty -Name IndexName -Value $i
            $o | Add-Member -MemberType NoteProperty -Name Server -Value $Server
            $o | Add-Member -MemberType NoteProperty -Name Port -Value $Port
            $o | Add-Member -MemberType NoteProperty -Name BaseUrl -Value "${Protocol}://${Server}:${Port}"
            $o | Add-Member -MemberType NoteProperty -Name Output -Value $null
            $o | Add-Member -MemberType NoteProperty -Name Error -Value $null
            $o | Add-Member -MemberType NoteProperty -Name ClusterNodes -Value $clusterNodes
            $o | Add-Member -MemberType ScriptProperty -Name HasData -Value { ($this.Output -ne $null) -or ($this.Error -ne $null) }
            $o | Add-Member -MemberType ScriptProperty -Name Age -Value { Get-EsIndexAge }
            $o | Add-Member -MemberType ScriptProperty -Name IsOnline -Value { Get-EsIndexState }
            $o | Add-Member -MemberType ScriptMethod -Name SetOpen -Value { Set-EsIndexOpen }
            $o | Add-Member -MemberType ScriptMethod -Name SetClosed -Value { Set-EsIndexClosed }
            $o | Add-Member -MemberType ScriptMethod -Name Merge -Value { Invoke-EsMerge }
            $o | Add-Member -MemberType ScriptMethod -Name Shrink -Value { Invoke-EsShrink }
            $o | Add-Member -MemberType ScriptMethod -Name Flush -Value { Invoke-EsFlush }
            $o | Add-Member -MemberType ScriptMethod -Name ClearCache -Value { Invoke-EsClearCache }
            $o | Add-Member -MemberType ScriptMethod -Name Remove -Value { Remove-EsIndex }

            $o.PSObject.TypeNames.Insert(0,'ES.Indexes')
            $o | Add-Member MemberSet PSStandardMembers $PSStandardMembers

            $o

        }
    }

    End {
        return $IndexObj
    }
}

###Helper Functions
function Get-EsIndexState() {
    Try {
        Invoke-RestMethod -Method Get -Uri "$($this.BaseUrl)/$($this.IndexName)/_stats" | Out-Null
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
        if ($this.IndexName -match $Pattern) {
            switch($Matches.Count) {
                4 { $span = $(Get-Date) - $(Get-Date ("$($Matches[2])/$($Matches[3])/$($Matches[1])")) } #Daily Indexes
                6 { $span = $(Get-Date) - $(Get-Date ("$($Matches[2])/$($Matches[3])/$($Matches[1]) $($Matches[5]):00:00")) } #Hourly Indexes
            }
        }
    }

    End {
        return $span
    }
}

function Remove-EsIndex() {
    Write-Host "$($this.IndexName) " -NoNewline

    if ($this.IsOnline) {
        Try {
            $this.Output = Invoke-RestMethod -Method Delete -Uri "$($this.BaseUrl)/$($this.IndexName)"
            Write-Host -ForegroundColor Green "[DELETED]"
        }

        Catch {
            $this.Error = "[$($MyInvocation.MyCommand)]: $($_.Exception.Message)"
            Write-Host -ForegroundColor Red "[ERROR]"
        }
    } else {
        Write-Host -ForegroundColor Yellow "[SKIPPED]"
    }
}

function Set-EsIndexOpen() {
    Write-Host "$($this.IndexName) " -NoNewline

    if (!$this.IsOnline) {
        Try {
            $this.Output = Invoke-RestMethod -Method Post -Uri "$($this.BaseUrl)/$($this.IndexName)/_open"
            Write-Host -ForegroundColor Green "[OPENED]"
        }

        Catch {
            $this.Error = "[$($MyInvocation.MyCommand)]: $($_.Exception.Message)"
            Write-Host -ForegroundColor Red "[ERROR]"
        }
    } else {
        Write-Host -ForegroundColor Yellow "[SKIPPED]"
    }
}

function Set-EsIndexClosed() {
    Write-Host "$($this.IndexName) " -NoNewline

    if ($this.IsOnline) {
        Try {
            $this.Output = Invoke-RestMethod -Method Post -Uri "$($this.BaseUrl)/$($this.IndexName)/_close"
            Write-Host -ForegroundColor Green "[CLOSED]"
        }

        Catch {
            $this.Error = "[$($MyInvocation.MyCommand)]: $($_.Exception.Message)"
            Write-Host -ForegroundColor Red "[ERROR]"
        }
    } else {
        Write-Host -ForegroundColor Yellow "[SKIPPED]"
    }
}

function Invoke-EsMerge() {
    Write-Host "$($this.IndexName) " -NoNewline

    if ($this.IsOnline) {
        Try {
            $this.Output = Invoke-RestMethod -Method Post -Uri "$($this.BaseUrl)/$($this.IndexName)/_forcemerge"
            Write-Host -ForegroundColor Green "[MERGED]"
        }

        Catch {
            $this.Error = "[$($MyInvocation.MyCommand)]: $($_.Exception.Message)"
            Write-Host -ForegroundColor Red "[ERROR]"
        }
    } else {
        Write-Host -ForegroundColor Yellow "[SKIPPED]"
    }
}

function Invoke-EsFlush() {
    Write-Host "$($this.IndexName) " -NoNewline

    if ($this.IsOnline) {
        Try {
            $this.Output = Invoke-RestMethod -Method Post -Uri "$($this.BaseUrl)/$($this.IndexName)/_flush"
            Write-Host -ForegroundColor Green "[FLUSHED]"
        }

        Catch {
            $this.Error = "[$($MyInvocation.MyCommand)]: $($_.Exception.Message)"
            Write-Host -ForegroundColor Red "[ERROR]"
        }
    } else {
        Write-Host -ForegroundColor Yellow "[SKIPPED]"
    }
}

function Invoke-EsClearCache() {
    Write-Host "$($this.IndexName) " -NoNewline

    if ($this.IsOnline) {
        Try {
            $this.Output = Invoke-RestMethod -Method Post -Uri "$($this.BaseUrl)/$($this.IndexName)/_cache/clear"
            Write-Host -ForegroundColor Green "[CACHE CLEARED]"
        }

        Catch {
            $this.Error = "[$($MyInvocation.MyCommand)]: $($_.Exception.Message)"
            Write-Host -ForegroundColor Red "[ERROR]"
        }
    } else {
        Write-Host -ForegroundColor Yellow "[SKIPPED]"
    }
}

function Invoke-EsShrink() {
    Write-Host "$($this.IndexName) " -NoNewline

    if ($this.IsOnline) {
        Try {
            Set-EsIndexReadOnly
            
            $this.Output = Invoke-RestMethod -Method Post -Uri "$($this.BaseUrl)/$($this.IndexName)/_shrink/$($this.IndexName)_shrunk"
            Write-Host -ForegroundColor Green "[SHRUNK]"
        }

        Catch {
            $this.Error = "[$($MyInvocation.MyCommand)]: $($_.Exception.Message)"
            Write-Host -ForegroundColor Red "[ERROR]"
        }
    } else {
        Write-Host -ForegroundColor Yellow "[SKIPPED]"
    }
}

function Get-EsIndexSettings() {
    if ($this.IsOnline) {
        $this.Output = Invoke-RestMethod -Method Get -Uri "$($this.BaseUrl)/$($this.IndexName)/_settings"
    } else {
        Throw "Index [$($this.IndexName)] is offline"
    }
}

function Set-EsIndexReadOnly() {
    if ($this.IsOnline) {
        $ShrinkNode = $this.ClusterNodes | ? { $_.data -eq $true } | Get-Random | Select-Object -ExpandProperty name

        $Settings = @{
            settings = @{
                "index.routing.allocation.require._name" = "$ShrinkNode"
                "index.blocks.write" = $true
            }
        }

        $this.Output = Invoke-RestMethod -Method Put -Uri "$($this.BaseUrl)/$($this.IndexName)/_settings" -Body $Settings -ContentType 'application/json'
    } else {
        Throw "Index [$($this.IndexName)] is offline"
    }
}

function Get-EsClusterNodes() {
    Begin {
        $r = Invoke-RestMethod -Method Get -Uri "${Protocol}://${Server}:${Port}/_nodes"
        $nodeId = $r.nodes | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    }

    Process {
        foreach ($n in $nodeId) {
            $r.nodes.$n.settings.node
        }
    }
}
