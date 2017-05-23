## PowerShell connector

Has a dependency on [CData ADO.NET Provider for PowerShell](http://www.cdata.com/drivers/powershell/ado/)

In order to run the connector use the `GetData > Other > PowerShell` dialog or the command:

`= PowerShell.Execute("z:/path to/cmdlet.ps1")`

The CData ADO.NET provider requires that the schema of the output be mentioned as a parameter at the start of the cmdlet. For example:

```
param(
  [String]$Name='',
	[String]$Description='',
	[String]$InvariantName='',
	[String]$AssemblyQualifiedName='')

[System.Data.Common.DbProviderFactories]::GetFactoryClasses()

```