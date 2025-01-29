function New-ZXProblemTagList {

    $Tags = [System.Collections.ArrayList]::new()

    $object = [PSCustomObject]@{
        Tags = $Tags
    }

    $object | Add-Member -MemberType ScriptMethod -Name AddTag -Value {
        param (
            [string]$TagName,
            [ValidateSet("0","2","Contains","Equals")]
            [string]$Operator,
            [string]$Value
        )
        switch ($operator){
            Equals {$Operator = "0"}
            Contains {$Operator = "2" }
        }
        $newObject = [PSCustomObject]@{ tag = $TagName; operator = $Operator; value = $Value }
        $this.Tags.Add($newObject) | Out-Null
        return $this
    }
    return $object
    
}

