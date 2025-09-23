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