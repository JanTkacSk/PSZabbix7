function New-ZXTagList {
    $Tags = [System.Collections.ArrayList]::new()

    $object = [PSCustomObject]@{
        Tags = $Tags
    }

    $object | Add-Member -MemberType ScriptMethod -Name AddTag -Value {
        param (
            [string]$TagName,
            [string]$TagValue
        )
        $newObject = [PSCustomObject]@{ tag = $TagName; value = $TagValue }
        $this.Tags.Add($newObject) | Out-Null
        return $this
    }
    return $object
}

