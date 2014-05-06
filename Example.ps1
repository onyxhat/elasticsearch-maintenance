###Import Module(s)
Import-Module .\ES-Maintenance.psd1

###Application Variables
$esServers = "logstash-test.onyxhat.com","logstash-dev.onyxhat.com","logstash-prod.onyxhat.com"
$Indexes = $esServers | % { Get-EsIndexes -Server $_ -IndexPrefix "logstash" }

###Runtime
$Indexes | % {
    if ($_.Age.TotalDays -gt 28) {
        $_.Delete()
    }

    if ($_.Age.TotalDays -lt 3) {
        $_.Optimize()
    }
}
