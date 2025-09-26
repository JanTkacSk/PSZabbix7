# PSZabbix7 Module – Example Usage

---

## New-ZXTokenSession

**Start new session and save the URL/token pair (prompt for password and url, token is encrypted)**
```powershell
New-ZXTokenSession -Save
```

**Start new session and save the URL/token pair (prompt for password, token is encrypted)**
```powershell
New-ZXTokenSession -Url https://YourZabbixAPIURL -Save
```

**Start new session using saved URL/token pairs**
```powershell
New-ZXTokenSession -Load
```
_Select the number and press enter when prompted._

**Start new session by entering the exact URL**
```powershell
New-ZXTokenSession -Url https://zabbix-prod.local/api_jsonrpc.php -Load
```

---

## Get-ZXHost

**Search for a single host by exact name**
```powershell
Get-ZXHost -Name zx_test_host_1,zx_test_host_2
```

**Search for hosts by name pattern**
```powershell
Get-ZXHost -NameSearch zx_test
```

**Fetch hosts and interfaces**
```powershell
Get-ZXHost -NameSearch test -IncludeInterfaces -Output host | Select-Object hostid,host,@{n="IPs";e={$_.interfaces.ip}}
```

**Fetch host items (basic properties)**
```powershell
Get-ZXHost -NameSearch vm-win -IncludeItems
```

**Fetch host items (specific properties)**
```powershell
Get-ZXHost -NameSearch vm-win -IncludeItems -ItemProperties name,type -Output host
```

**Fetch host triggers**
```powershell
Get-ZXHost -Name test -IncludeTriggers -TriggerProperties description | Select-Object -ExpandProperty triggers
```

---

## Get-ZXMaintenance

**Get maintenance mode information**
```powershell
$HostID = Get-ZXHost -Name vm-win-test-1.test.local -Output hostid
Get-ZXMaintenance -HostId $HostID.hostid
```

---

## New-ZXTagFilter

**Create a list of tags and use it to find hosts**
```powershell
$TagFilter = New-ZXTagFilter
$TagFilter.AddTag("#tag_1","exists").AddTag("#tag_2","notexists")
Get-ZXHost -Tag $TagFilter.Tags -WhatIf
```

---

## Get-ZXTrigger

**Get all triggers on a single host**
```powershell
$ZXHost = Get-ZXHost -Name Test-Host -Output host,id
Get-ZXTrigger -HostID $ZXHost.hostid -Output extend | Format-Table
```

**Get triggers on a single host (specific properties)**
```powershell
Get-ZXTrigger -HostID $ZXHost.hostid -Output description,value,expression
```

---

## Get-ZXAction

**Get action name from alert**
```powershell
$Alert = Get-ZXAlert -EventID 0123456789
Get-ZXAction -ActionID $alert.actionid -Output name
```

---

## Common Parameters

**Select specific properties**
```powershell
Get-ZXHost -NameSearch test -IncludeTriggers -IncludeInterfaces -InterfaceProperties ip -Output name,status
```

**Show JSON request without making the API call**
```powershell
Get-ZXHost -NameSearch test -Output name,status -WhatIf
```

**Show only the count of results**
```powershell
Get-ZXHost -Status Disabled -CountOutput
```

**Limit the number of returned results**
```powershell
Get-ZXHost -NameSearch test -Limit 5 -ShowJsonRequest
```