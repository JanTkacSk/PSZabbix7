function New-ZXProblemTagList {

    $Tags = [System.Collections.ArrayList]::new()

    $object = [PSCustomObject]@{
        Tags = $Tags
    }

    $object | Add-Member -MemberType ScriptMethod -Name AddTag -Value {
        param (
            [string]$Name,
            [ValidateSet("0","1","2","3","4","5","Contains","Equals","NotLike","NotEqual","Exists","NotExists")]
            [string]$Operator,
            [string]$Value
        )
        switch ($operator){
            Contains {$operator = "0"}
            Equals {$operator = "1"}
            NotLike {$operator = "2" }
            NotEqual {$operator = "3" }
            Exists {$operator = "4" }
            NotExists {$operator = "5" }
        }
        $newObject = [PSCustomObject]@{ name = $Name; operator = $Operator; value = $Value }
        $this.Tags.Add($newObject) | Out-Null
        return $this
    }
    return $object
    
}

