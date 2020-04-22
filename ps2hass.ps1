Clear-Host

function WriteMsg([string] $msg, [string] $color) {
    if (-not ([string]::IsNullOrEmpty($logfile))) {
        $msg | out-file $logfile -append
    }
    # Write-Output $msg
    if ([string]::IsNullOrEmpty($color)) {
        Write-Host $msg
    }
    else {
        Write-Host $msg -foregroundcolor $color
    }
}

function Initialize-HassData() {
    $Global:HassHeader = @{ "Authorization" = "Bearer $Global:AccessToken"; "Content-Type" = "application/json"}
}

function Invoke-Service($Service, $Data) {
    WriteMsg([String]::Format("Executing '{0}' service via REST", $Service))
    $url = [String]::Format("{0}/api/services/{1}", $Global:HassBaseUrl, $Service.replace(".", "/"))
    WriteMsg([String]::Format("  Url: {0}", $url))

    $body = $Data | ConvertTo-Json
    if ($Data) {
        WriteMsg "  Data:"
        $Data.Keys | ForEach-Object { WriteMsg([String]::Format("    {0}: {1}", $_, $Data[$_])) }
    }

    $resp = Invoke-RestMethod -Method POST -Uri $url -Headers $Global:HassHeader -Body $body
    WriteMsg "  Service invoked"
    WriteMsg ""
    # return $resp
}

function Get-Entity($EntityId) {
    WriteMsg([String]::Format("Getting entity '{0}' via REST", $EntityId))
    $url = [String]::Format("{0}/api/states/{1}", $Global:HassBaseUrl, $EntityId)
    WriteMsg([String]::Format("  Url: {0}", $url))
    $resp = Invoke-RestMethod -Method GET -Uri $url -Headers $Global:HassHeader #-Body $body
    WriteMsg([String]::Format("  Entity {0}:", $EntityId))
    WriteMsg([String]::Format("  {0}", $resp))
    WriteMsg ""
    return $resp
}

function Set-Entity-State($EntityId, $NewState) {
    $entity = Get-Entity $EntityId
    WriteMsg([String]::Format("Setting state for entity '{0}' via REST", $EntityId))
    $url = [String]::Format("{0}/api/states/{1}", $Global:HassBaseUrl, $EntityId)
    WriteMsg([String]::Format("  Url: {0}", $url))
    $data = @{ "state" = $NewState; "attributes" = $entity.attributes}
    $body = $data | ConvertTo-Json
    if ($data) {
        WriteMsg "  Data:"
        $data.Keys | ForEach-Object { WriteMsg([String]::Format("    {0}: {1}", $_, $data[$_])) }
    }
    $resp = Invoke-RestMethod -Method POST -Uri $url -Headers $Global:HassHeader -Body $body
    WriteMsg "  State set"
    WriteMsg ""
    # return $resp
}

function Set-Entity-Attribute($EntityId, $Attribute, $NewValue) {
    $entity = Get-Entity $EntityId
    WriteMsg([String]::Format("Setting attribute '{0}' for entity '{1}' via REST", $Attribute, $EntityId))
    $url = [String]::Format("{0}/api/states/{1}", $Global:HassBaseUrl, $EntityId)
    WriteMsg([String]::Format("  Url: {0}", $url))
    $entity.attributes.$Attribute = $NewValue
    $data = @{ "state" = $entity.state; "attributes" = $entity.attributes}
    $body = $data | ConvertTo-Json
    if ($data) {
        WriteMsg "  Data:"
        $data.Keys | ForEach-Object { WriteMsg([String]::Format("    {0}: {1}", $_, $data[$_])) }
    }
    $resp = Invoke-RestMethod -Method POST -Uri $url -Headers $Global:HassHeader -Body $body
    WriteMsg "  Attribute set"
    WriteMsg ""
    # return $resp
}


#--- INVOKE SAMPLE METHODS ---

# Uncomment row below to enable logging to file
# $logfile = Join-Path $PSScriptRoot ([String]::Format("ps2hass_{0:yyyyMMdd_HHmmss}.txt", [DateTime]::Now))

$HassBaseUrl = "http://hassio:8123"
$AccessToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJmNzFhZTgzYzlkMTQ0YmE5YTNmZGU2NTk4OTMzYTdjNyIsImlhdCI6MTU0NzE4MDU3MCwiZXhwIjoxODYyNTQwNTcwfQ.f4RH8wu8ucTZjMpAQ7DWv7J8ZXAQFE8y1PlSEIe2_iA" #Fake token
Initialize-HassData

# Show a message via persistent notification
Invoke-Service -Service "persistent_notification.create" -Data @{ "title" = "This is the title"; "message" = "Hello world !"; "notification_id" = "9975" }

# Reboot the Hass device
# Invoke-Service -Service "hassio.host_reboot"

# Restart Home Assistant
# Invoke-Service -Service "homeassistant.restart"

# Reload scripts
# Invoke-Service -Service "script.reload"

# Reload automations
# Invoke-Service -Service "automation.reload"

# Read an entity
# $entity = Get-Entity "sensor.time"
# $entity

# Set an entity state
# Set-Entity-State "sensor.time" "12.01"

# Set an entity attribute
# Set-Entity-Attribute "sensor.time" "icon" "mdi:home"

# Toggle switch
# Invoke-Service -Service "switch.toggle" -Data @{ "entity_id" = "switch.smartplug_1" }
