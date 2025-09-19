function Get-ZXService {
    param(
        [string]$Name,
        [string]$NameSearch,
        [array]$ServiceID,
        [array]$ParentID,
        [switch]$DeepParentID,
        [array]$ChildID,
        [string]$EvalType,
        [array]$Tag,
        [array]$ProblemTag,
        [switch]$WithoutProblemTags,
        [array]$SLAID,
        [switch]$IncludeChildren,
        [switch]$IncludeParents,
        [switch]$IncludeTags,
        [switch]$IncludeProblemEvents,
        [switch]$IncludeProblemTags,
        [switch]$IncludeStatusRules,
        [switch]$IncludeStatusTimeline,
        [array]$ChildrenProperties,
        [array]$ParentProperties,
        [array]$ProblemEventProperties,
        [array]$StatusRuleProperties,
        [array]$StatusTimelineProperties,
        [switch]$ExcludeSearch,
        [array]$Status,
        [switch]$Editable,
        [switch]$ShowJsonRequest,
        [switch]$WhatIf,
        [array]$Output
    )
    #Validate parameters

    if (!$Output){
        $Output = @("name","description","status")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    if ($IncludeChildren){
        If (!$ChildrenProperties){
            $ChildrenProperties = @("name")
        }
        elseif($ChildrenProperties -contains "extend"){
            [string]$ChildrenProperties = "extend"
        }    
    }
    if ($IncludeParents){
        If (!$ParentProperties){
            $ParentProperties = @("name","status")
        }
        elseif($ParentProperties -contains "extend"){
            Write-Host -ForegroundColor Yellow "Extend will not work for here"
        }    
    }
    if ($IncludeProblemEvents){
        If (!$ProblemEventProperties){
            $ProblemEventProperties = @("name","severity","eventid")
        }
        elseif($ProblemEventProperties -contains "extend"){
            Write-Host -ForegroundColor Yellow "Extend will not work for here"
        }    
    }
    if ($IncludeStatusRules){
        If (!$StatusRuleProperties){
            $StatusRuleProperties = @("extend")
        }
        elseif($StatusRuleProperties -contains "extend"){
            [string]$StatusRuleProperties = "extend"
        }    
    }
    if ($IncludeStatusTimeline){
        If (!$StatusTimelineProperties){
            $StatusTimelineProperties = @("extend")
        }
        elseif($StatusTimelineProperties -contains "extend"){
            [string]$StatusTimelineProperties = "extend"
        }    
    }

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "service.get";
        "params" = [PSCustomObject]@{
        }; 
        #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken)));
        "id" = 1;
    }

    #Output content
    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output

    # Example of the argument for $Tag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "value" = ""; "operator" = "2"})
    # Example of the argument for $Tag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "operator" = "5"})
    # Possible operator values:  0 - (default) Contains; 1 - Equals; 2 - Not like; 3 - Not equal; 4 - Exists; 5 - Not exists.
    if($Tag){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "tags" -Value $Tag
    }
    if($ServiceID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "serviceids" -Value $ServiceID
    }

    # Example of the argument for $ProblemTag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "value" = ""; "operator" = "2"})
    # Example of the argument for $ProblemTag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "operator" = "5"})
    # Possible operator values:  0 - (default) Contains; 1 - Equals; 2 - Not like; 3 - Not equal; 4 - Exists; 5 - Not exists.
    if($ProblemTag){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "problemTags" -Value $ProblemTag
    }
      
    if($Name){
        AddFilter -PropertyName name -PropertyValue $Name
    }
    if($Status){
        AddFilter -PropertyName status -PropertyValue @($Status)
    }
    if($NameSearch){
        AddSearch -PropertyName name -PropertyValue $NameSearch
    }
    if($ExcludeSearch){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "excludeSearch" -Value "true"
    }
    if($Editable){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "editable" -Value $True
    }
    if($IncludeChildren){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectChildren" -Value $ChildrenProperties
    }
    if($IncludeParents){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectParents" -Value $ParentProperties
    }
    if($IncludeTags){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTags" -Value "extend"
    }
    if($IncludeProblemTags){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectProblemTags" -Value "extend"
    }
    if($IncludeProblemEvents){
        $PSObj.params| Add-Member -MemberType NoteProperty -Name "selectProblemEvents" -Value @($ProblemEventProperties)
    }
    if($IncludeStatusRules){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectStatusRules" -Value $StatusRuleProperties
    }
    if($IncludeChildren){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectStatusTimeline" -Value $StatusTimelineProperties
    }
    if($DeepParentID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "deep_parentids" -Value $true
    }
    if($ParentID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "parentids" -Value $ParentID
    }



        #Convert the ps object to json. It is crucial to use a correct value for the -Depth
        $Json = $PSObj | ConvertTo-Json -Depth 6

            #Make the final API call
        if(!$WhatIf){
            $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        }


        #Show JSON Request if -ShowJsonRequest switch is used
        If ($ShowJsonRequest -or $WhatIf){
            Write-Host -ForegroundColor Yellow "JSON REQUEST"
            $PSObjShow = $PSObj | ConvertTo-Json -Depth 6 | ConvertFrom-Json -Depth 6
            $PSObjShow.auth = "*****"
            $JsonShow = $PSObjShow | ConvertTo-Json -Depth 6
            Write-Host -ForegroundColor Cyan $JsonShow
        }

        #This will be returned by the function

        if($null -ne $Request.error){
            $Request.error
            return
        }
        elseif($CountOutput){
            $Request.result
            return
        }   
        else {
            $Request.result
            return
        }

}