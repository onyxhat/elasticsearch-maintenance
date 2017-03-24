elasticsearch-maintenance
=========================
PowerShell module for common maintenance tasks in ElasticSearch.


###Supported APIs
* [Delete](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-delete-index.html)
* [Shrink](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-shrink-index.html)
* [Flush](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-flush.html)
* [Merge](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-forcemerge.html)
* [Clear Cache](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-clearcache.html)
* [Open/Close](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-open-close.html)
* __[More to Come](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices.html)__


###Requirements
* [PowerShell v4.0+](http://www.microsoft.com/en-us/download/details.aspx?id=40855)


###Getting Started
PowerShell modules can be loaded by either copying the PSM1 and PSD1 files into your $env:PSModulePath or by directly referencing the PSD1 module manifest when calling [Import-Module](http://technet.microsoft.com/en-us/library/hh849725.aspx). Once imported the command Get-EsIndexes becomes available for use in the shell instance. The command returns a PowerShell object containing __NoteProperties__ of returned indicies and __ScriptMethods__ that can be called against them.


###Command Syntax
The command makes HTTP calls to the ElasticSearch server at the Server and Port you specify. By default ALL indexes present will be returned. The prefix will vary based on your use and needs, but in our case ElasticSearch is used to catalog LogStash data - so indexes look like "logstash-${YEAR}-${MONTH}-${DAY}.${HOUR}" (i.e. the IndexPrefix is "logstash").

```powershell
Get-EsIndexes -Protocol <[http|https] [Default=http]> -Server <ES FQDN or IP Address [Default=localhost]> -Port <ES Port [Default=9200]> -IndexPrefix <ES Index Prefix [Default=.*]>
```


###Object Definitions
|Name        |MemberType   |Definition|
|:----        |:----------   |:----------|
|Equals      |Method       |bool Equals(System.Object obj)|
|GetHashCode |Method       |int GetHashCode()|
|GetType     |Method       |type GetType()|
|ToString    |Method       |string ToString()|
|Age         |NoteProperty |System.TimeSpan|
|Index       |NoteProperty |System.String|
|Port        |NoteProperty |System.Int32|
|Server      |NoteProperty |System.String|
|Status      |NoteProperty |System.String|
|ClearCache  |ScriptMethod |System.Object ClearCache()|
|CloseIndex  |ScriptMethod |System.Object CloseIndex()|
|Delete      |ScriptMethod |System.Object Delete()|
|Flush       |ScriptMethod |System.Object Flush()|
|OpenIndex   |ScriptMethod |System.Object OpenIndex()|
|Optimize    |ScriptMethod |System.Object Optimize()|
|Refresh     |ScriptMethod |System.Object Refresh()|
