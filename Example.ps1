###Import Module(s)
Import-Module .\ES-Maintenance.psd1

###Application Variables
$esServers = "127.0.0.1"
$Indexes = $esServers | % { Get-EsIndexes -Server $_ -IndexPrefix "logstash" }

if ($Indexes -ne $null)
{
	###Runtime
	$IndexesToDelete = $($Indexes | Where-Object { $_.Age.TotalDays -gt 90 })
	if ($IndexesToDelete -ne $null)
	{
		$IndexesToDelete.Delete()
	}
	
	$IndexesToOptimize = $($Indexes | Where-Object { $_.Age.TotalDays -lt 3 })
	if ($IndexesToOptimize -ne $null)
	{
		$IndexesToOptimize.Optimize()
	}
}
else
{
	write-host "No index found" -foregroundcolor yellow
}