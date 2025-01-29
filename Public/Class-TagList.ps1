<# 
class ZXTagList {
    [System.Collections.ArrayList]$Tags

    ZXTagList() {
        $this.Tags = [System.Collections.ArrayList]::new()
    }

    [void] AddTag([string]$name, [string]$value) {
        $newObject = [PSCustomObject]@{ Name = $name; Value = $value }
        $this.Tags.Add($newObject) | Out-Null
    }

    [void] Display() {
        $this.Tags
    }
}
#>

class ZXTagList {
    [System.Collections.ArrayList]$Tags

    ZXTagList() {
        $this.Tags = [System.Collections.ArrayList]::new()
    }

    [ZXTagList]AddTag([string]$name, [string]$value) {
        $newObject = [PSCustomObject]@{ name = $name; value = $value }
        $this.Tags.Add($newObject) | Out-Null
        return $this
    }

    [void] Display() {
        $this.Tags
    }
}