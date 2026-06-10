<#
.SYNOPSIS
    Microsoft 365 Copilot interaction-history analytics: app-only Graph export
    plus a self-contained HTML dashboard builder.

.DESCRIPTION
    This module exposes two main functions:

      Export-CopilotInteractions  - app-only (client-credentials) export of
                                    tenant Copilot interaction history to
                                    per-user JSON files.
      Build-CopilotReport         - aggregate those JSON files into a single,
                                    self-contained HTML dashboard.

    The calling Entra app registration must hold the following Microsoft Graph
    APPLICATION permissions (with admin consent):
        AiEnterpriseInteraction.Read.All
        User.Read.All
        Organization.Read.All

    Authentication supports either a client secret or a certificate.

    Requires PowerShell 7+.
#>

Set-StrictMode -Version Latest

$script:GraphBase     = 'https://graph.microsoft.com/v1.0'
$script:DefaultSkuId  = '639dec6b-bb19-468b-871c-c5c441c4b0cb'   # Microsoft 365 Copilot
$script:TokenScope    = 'https://graph.microsoft.com/.default'

# appClass -> friendly surface label
$script:AppLabels = @{
    'IPM.SkypeTeams.Message.Copilot.BizChat'     = 'M365 Copilot Chat'
    'IPM.SkypeTeams.Message.Copilot.SharePoint'  = 'SharePoint'
    'IPM.SkypeTeams.Message.Copilot.Outlook'     = 'Outlook'
    'IPM.SkypeTeams.Message.Copilot.PrivateChat' = 'Teams'
    'IPM.SkypeTeams.Message.Copilot.Word'        = 'Word'
    'IPM.SkypeTeams.Message.Copilot.Excel'       = 'Excel'
    'IPM.SkypeTeams.Message.Copilot.PowerPoint'  = 'PowerPoint'
    'IPM.SkypeTeams.Message.Copilot.OneNote'     = 'OneNote'
    'IPM.SkypeTeams.Message.Copilot.VivaEngage'  = 'Viva Engage'
    'IPM.SkypeTeams.Message.Copilot.WebChat'     = 'Copilot Chat (Free)'
    'IPM.SkypeTeams.Message.Copilot.Loop'        = 'Loop'
}

$script:ErrPattern = [regex]::new(
    "i.?m sorry|i apologi[sz]e|unable to|couldn.?t find|can.?t find|cannot find|" +
    "don.?t have access|i was unable|no results|i wasn.?t able|i (?:did|didn.?t)" +
    " (?:not )?find|encountered an error|something went wrong|i can.?t help|" +
    "i.?m not able",
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

$script:FeaturePatterns = @(
    @{ Name = 'Summarize / Recap';     Re = [regex]::new('summar|recap|key points|highlights|tldr|tl;dr|catch me up|what did i miss', 'IgnoreCase') }
    @{ Name = 'Draft / Compose';       Re = [regex]::new('draft|write|compose|create.*(?:email|message|doc|report|memo|letter|post)', 'IgnoreCase') }
    @{ Name = 'Search / Find';         Re = [regex]::new('search|find|look up|what (?:is|are|was)|who (?:is|are)|where (?:is|are)|show me', 'IgnoreCase') }
    @{ Name = 'Analyze / Compare';     Re = [regex]::new('analy[sz]|compare|difference|trend|insight|breakdown|assess', 'IgnoreCase') }
    @{ Name = 'Explain / Teach';       Re = [regex]::new('explain|how (?:do|does|to|can)|what does.*mean|teach|help me understand', 'IgnoreCase') }
    @{ Name = 'Edit / Rewrite';        Re = [regex]::new('edit|rewrite|rephrase|shorten|improve|revise|make.*(?:shorter|longer|formal|casual)', 'IgnoreCase') }
    @{ Name = 'Generate / Brainstorm'; Re = [regex]::new('generate|brainstorm|ideas?|suggest|list.*(?:options|ways|ideas)', 'IgnoreCase') }
    @{ Name = 'Data / Tables';         Re = [regex]::new('table|spreadsheet|data|chart|graph|pivot|formula|csv|excel', 'IgnoreCase') }
    @{ Name = 'Meeting / Calendar';    Re = [regex]::new('meeting|schedule|calendar|agenda|invite|book|reschedule', 'IgnoreCase') }
)

$script:Palette = @('#0f6cbd', '#107c10', '#e3751c', '#c4314b', '#5c2d91', '#038387', '#bf0077')

# ---------------------------------------------------------------------------
# Authentication
# ---------------------------------------------------------------------------

function ConvertTo-Base64Url {
    param([byte[]]$Bytes)
    [Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function New-ClientAssertion {
    param(
        [Parameter(Mandatory)][System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientId
    )
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $aud = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $x5t = ConvertTo-Base64Url -Bytes $Certificate.GetCertHash()   # SHA1 thumbprint

    $header  = [ordered]@{ alg = 'RS256'; typ = 'JWT'; x5t = $x5t } | ConvertTo-Json -Compress
    $payload = [ordered]@{
        aud = $aud; iss = $ClientId; sub = $ClientId
        jti = [guid]::NewGuid().ToString(); nbf = $now; exp = $now + 600; iat = $now
    } | ConvertTo-Json -Compress

    $h = ConvertTo-Base64Url -Bytes ([Text.Encoding]::UTF8.GetBytes($header))
    $p = ConvertTo-Base64Url -Bytes ([Text.Encoding]::UTF8.GetBytes($payload))
    $unsigned = "$h.$p"

    $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)
    if (-not $rsa) { throw 'The supplied certificate has no accessible RSA private key.' }
    $sig = $rsa.SignData(
        [Text.Encoding]::UTF8.GetBytes($unsigned),
        [Security.Cryptography.HashAlgorithmName]::SHA256,
        [Security.Cryptography.RSASignaturePadding]::Pkcs1)

    "$unsigned." + (ConvertTo-Base64Url -Bytes $sig)
}

function New-GraphContext {
    <#
    .SYNOPSIS
        Build an app-only Graph auth context (client secret or certificate).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientId,
        [string]$ClientSecret,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )
    if (-not $ClientSecret -and -not $Certificate) {
        throw 'Provide either -ClientSecret or -Certificate.'
    }
    [pscustomobject]@{
        TenantId     = $TenantId
        ClientId     = $ClientId
        ClientSecret = $ClientSecret
        Certificate  = $Certificate
        Token        = $null
        Expires      = [datetime]::MinValue
    }
}

function Get-GraphToken {
    param([Parameter(Mandatory)][pscustomobject]$Context)

    if ($Context.Token -and [datetime]::UtcNow -lt $Context.Expires.AddMinutes(-5)) {
        return $Context.Token
    }

    $uri  = "https://login.microsoftonline.com/$($Context.TenantId)/oauth2/v2.0/token"
    $body = @{
        client_id  = $Context.ClientId
        scope      = $script:TokenScope
        grant_type = 'client_credentials'
    }
    if ($Context.Certificate) {
        $body['client_assertion_type'] = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        $body['client_assertion']      = New-ClientAssertion -Certificate $Context.Certificate -TenantId $Context.TenantId -ClientId $Context.ClientId
    }
    else {
        $body['client_secret'] = $Context.ClientSecret
    }

    try {
        $resp = Invoke-RestMethod -Method Post -Uri $uri -Body $body -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop
    }
    catch {
        throw "Token request failed: $($_.Exception.Message)"
    }
    $Context.Token   = $resp.access_token
    $Context.Expires = [datetime]::UtcNow.AddSeconds([int]$resp.expires_in)
    $Context.Token
}

function Invoke-GraphGet {
    param(
        [Parameter(Mandatory)][pscustomobject]$Context,
        [Parameter(Mandatory)][string]$Uri,
        [int]$MaxAttempts = 5
    )
    for ($attempt = 1; ; $attempt++) {
        $token = Get-GraphToken -Context $Context
        try {
            return Invoke-RestMethod -Method Get -Uri $Uri -Headers @{ Authorization = "Bearer $token" } -ErrorAction Stop
        }
        catch {
            $status = 0
            $retryAfter = $null
            $resp = $_.Exception.Response
            if ($resp) {
                try { $status = [int]$resp.StatusCode } catch { $status = 0 }
                try { $retryAfter = $resp.Headers.RetryAfter.Delta.TotalSeconds } catch { }
            }
            if (($status -eq 429 -or $status -ge 500) -and $attempt -lt $MaxAttempts) {
                $wait = if ($retryAfter) { [double]$retryAfter } else { [Math]::Pow(2, $attempt) }
                Write-Verbose "Graph $status on attempt $attempt; retrying in $wait s."
                Start-Sleep -Seconds ([Math]::Min($wait, 60))
                continue
            }
            throw
        }
    }
}

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

function Get-SafeName {
    param([string]$Upn)
    [regex]::Replace($Upn, '[^a-zA-Z0-9._@-]', '_')
}

function Export-CopilotInteractions {
    <#
    .SYNOPSIS
        Export per-user Copilot interaction history to JSON files in -OutDir.
    .DESCRIPTION
        Enumerates enabled users licensed for the given Copilot SKU, then pulls
        each user's enterprise interaction history. One <safe-upn>.json file is
        written per user, plus _users.json and _summary.json. Existing per-user
        files are treated as a cache and skipped.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Context,
        [Parameter(Mandatory)][string]$OutDir,
        [int]$SinceDays = 7,
        [string]$SkuId = $script:DefaultSkuId,
        [int]$MaxUsers = 0
    )

    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

    Write-Host "Enumerating users licensed for SKU $SkuId ..." -ForegroundColor Cyan
    $filter = [uri]::EscapeDataString("assignedLicenses/any(x:x/skuId eq $SkuId)")
    $url = "$($script:GraphBase)/users?`$select=id,userPrincipalName,displayName,accountEnabled,assignedLicenses&`$filter=$filter&`$top=999"

    $users = [System.Collections.Generic.List[object]]::new()
    while ($url) {
        $page = Invoke-GraphGet -Context $Context -Uri $url
        foreach ($u in $page.value) {
            if ($u.accountEnabled -eq $false) { continue }
            $users.Add($u)
        }
        $url = $page.'@odata.nextLink'
    }
    if ($users.Count -eq 0) {
        throw "No enabled users have SKU $SkuId assigned. Verify the SKU id with /v1.0/subscribedSkus."
    }
    if ($MaxUsers -gt 0 -and $users.Count -gt $MaxUsers) {
        $users = [System.Collections.Generic.List[object]]($users | Select-Object -First $MaxUsers)
    }
    Write-Host "Found $($users.Count) licensed user(s)." -ForegroundColor Green
    $users | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $OutDir '_users.json') -Encoding utf8

    $cutoff = $null
    if ($SinceDays -gt 0) { $cutoff = [datetime]::UtcNow.AddDays(-$SinceDays) }

    $summary = [System.Collections.Generic.List[object]]::new()
    $idx = 0
    foreach ($u in $users) {
        $idx++
        $upn = if ($u.userPrincipalName) { $u.userPrincipalName } else { $u.id }
        $fpath = Join-Path $OutDir ((Get-SafeName -Upn $upn) + '.json')

        if (Test-Path $fpath) {
            $existing = $null
            try { $existing = Get-Content $fpath -Raw | ConvertFrom-Json } catch { }
            $cnt = if ($existing) { $existing.count } else { 0 }
            $summary.Add([pscustomobject]@{ upn = $upn; id = $u.id; count = $cnt; status = 'cached' })
            Write-Host ("[{0}/{1}] {2} (cached)" -f $idx, $users.Count, $upn)
            continue
        }

        $encoded = [uri]::EscapeDataString($u.id)
        $next = "$($script:GraphBase)/copilot/users/$encoded/interactionHistory/getAllEnterpriseInteractions"
        $collected = [System.Collections.Generic.List[object]]::new()
        $status = 'ok'
        try {
            while ($next) {
                $page = Invoke-GraphGet -Context $Context -Uri $next
                foreach ($item in $page.value) {
                    $when = $null
                    if ($item.createdDateTime) {
                        try {
                            $when = [datetime]::Parse($item.createdDateTime, [Globalization.CultureInfo]::InvariantCulture,
                                [Globalization.DateTimeStyles]::AdjustToUniversal -bor [Globalization.DateTimeStyles]::AssumeUniversal)
                        } catch { $when = $null }
                    }
                    if ($cutoff -and $when -and $when -lt $cutoff) { continue }
                    $collected.Add($item)
                }
                $next = $page.'@odata.nextLink'
            }
        }
        catch {
            $status = "error: $($_.Exception.Message)"
            Write-Warning "  $upn -> $status"
        }

        $payload = [ordered]@{
            user           = $upn
            userId         = $u.id
            displayName    = $u.displayName
            retrievedAtUtc = [datetime]::UtcNow.ToString('o')
            count          = $collected.Count
            status         = $status
            interactions   = $collected
        }
        $payload | ConvertTo-Json -Depth 25 | Set-Content -Path $fpath -Encoding utf8
        $summary.Add([pscustomobject]@{ upn = $upn; id = $u.id; count = $collected.Count; status = $status })
        Write-Host ("[{0}/{1}] {2} -> {3} interaction(s)" -f $idx, $users.Count, $upn, $collected.Count)
    }

    $summary | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $OutDir '_summary.json') -Encoding utf8
    [pscustomobject]@{ OutDir = $OutDir; Users = $users.Count; Files = $summary.Count }
}

# ---------------------------------------------------------------------------
# Report helpers
# ---------------------------------------------------------------------------

function ConvertTo-HtmlText {
    param([object]$Value)
    if ($null -eq $Value) { return '' }
    $s = [string]$Value
    $s = $s.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;').Replace("'", '&#39;')
    $s
}

function ConvertTo-JsonArray {
    param($Items)
    $arr = @($Items)
    if ($arr.Count -eq 0) { return '[]' }
    '[' + (($arr | ForEach-Object { ConvertTo-Json -Compress -InputObject $_ }) -join ',') + ']'
}

function Add-TextNodes {
    param($Node, [System.Collections.Generic.List[string]]$Acc)
    if ($null -eq $Node -or $Node -is [string] -or $Node -is [ValueType]) { return }
    if ($Node -is [System.Management.Automation.PSCustomObject]) {
        foreach ($p in $Node.PSObject.Properties) {
            if ($p.Name -eq 'text' -and $p.Value -is [string]) { $Acc.Add($p.Value) }
            Add-TextNodes -Node $p.Value -Acc $Acc
        }
    }
    elseif ($Node -is [System.Collections.IEnumerable]) {
        foreach ($v in $Node) { Add-TextNodes -Node $v -Acc $Acc }
    }
}

function Get-InteractionText {
    param($Interaction)
    $txt = ''
    if ($Interaction.PSObject.Properties['body'] -and $Interaction.body -and $Interaction.body.PSObject.Properties['content']) {
        $txt = [string]$Interaction.body.content
    }
    $txt = [regex]::Replace($txt, '<[^>]+>', ' ')
    if ($Interaction.PSObject.Properties['attachments'] -and $Interaction.attachments) {
        foreach ($a in $Interaction.attachments) {
            if (-not ($a.PSObject.Properties['content'])) { continue }
            $c = $a.content
            if ($c -is [string]) {
                try {
                    $ac = $c | ConvertFrom-Json -ErrorAction Stop
                    $acc = [System.Collections.Generic.List[string]]::new()
                    Add-TextNodes -Node $ac -Acc $acc
                    $txt += ' ' + ($acc -join ' ')
                } catch { $txt += ' ' + $c }
            }
        }
    }
    ([regex]::Replace($txt, '\s+', ' ')).Trim()
}

function Get-SurfaceLabel {
    param($Interaction)
    if ($Interaction.PSObject.Properties['links'] -and $Interaction.links) {
        foreach ($ln in $Interaction.links) {
            $u = ''
            if ($ln -is [System.Management.Automation.PSCustomObject] -and $ln.PSObject.Properties['linkUrl']) { $u = [string]$ln.linkUrl }
            if ($u -like '*https://teams.microsoft.com*') { return 'Teams' }
        }
    }
    $ac = [string]$Interaction.appClass
    if ($script:AppLabels.ContainsKey($ac)) { return $script:AppLabels[$ac] }
    if ([string]::IsNullOrEmpty($ac)) { return 'Unknown' }
    $ac -replace 'IPM\.SkypeTeams\.Message\.Copilot\.', ''
}

function ConvertTo-UtcDate {
    param([string]$Value)
    if ([string]::IsNullOrEmpty($Value)) { return $null }
    try {
        return [datetime]::Parse($Value, [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::AdjustToUniversal -bor [Globalization.DateTimeStyles]::AssumeUniversal)
    } catch { return $null }
}

function Get-TopKey {
    param([hashtable]$Map)
    if (-not $Map -or $Map.Count -eq 0) { return $null }
    ($Map.GetEnumerator() | Sort-Object -Property @{ Expression = 'Value'; Descending = $true } | Select-Object -First 1).Key
}

# ---------------------------------------------------------------------------
# Report builder
# ---------------------------------------------------------------------------

function Build-CopilotReport {
    <#
    .SYNOPSIS
        Build a self-contained HTML dashboard from per-user interaction JSON.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InputDir,
        [Parameter(Mandatory)][string]$OutHtml
    )

    $files = Get-ChildItem -Path $InputDir -Filter *.json -File |
        Where-Object { -not $_.Name.StartsWith('_') } | Sort-Object Name
    if (-not $files) { throw "No user JSON files found in $InputDir" }

    $perUser      = [System.Collections.Generic.List[object]]::new()
    $globalByApp  = @{}
    $eventsTable  = [System.Collections.Generic.List[object]]::new()
    $allDates     = [System.Collections.Generic.List[datetime]]::new()
    $featureCounts = @{}
    $featureUsers  = @{}

    foreach ($f in $files) {
        try { $d = Get-Content $f.FullName -Raw | ConvertFrom-Json } catch { Write-Warning "skip $($f.Name): $_"; continue }

        $upn     = if ($d.PSObject.Properties['user'] -and $d.user) { $d.user } else { $f.BaseName }
        $display = if ($d.PSObject.Properties['displayName'] -and $d.displayName) { $d.displayName } else { $upn }
        $ints = @()
        if ($d.PSObject.Properties['interactions'] -and $d.interactions) { $ints = @($d.interactions) }

        $byApp = @{}
        $sessions = [System.Collections.Generic.HashSet[string]]::new()
        $prompts = 0; $responses = 0; $errs = 0
        $userDates = [System.Collections.Generic.List[datetime]]::new()

        foreach ($i in $ints) {
            $app = Get-SurfaceLabel -Interaction $i
            if ($byApp.ContainsKey($app)) { $byApp[$app]++ } else { $byApp[$app] = 1 }
            if ($globalByApp.ContainsKey($app)) { $globalByApp[$app]++ } else { $globalByApp[$app] = 1 }

            $sid = if ($i.PSObject.Properties['sessionId']) { [string]$i.sessionId } else { '' }
            if ($sid) { [void]$sessions.Add($sid) }

            $typ = if ($i.PSObject.Properties['interactionType']) { [string]$i.interactionType } else { '' }
            if ($typ -eq 'userPrompt') {
                $prompts++
                $txt = Get-InteractionText -Interaction $i
                $matched = $false
                foreach ($fp in $script:FeaturePatterns) {
                    if ($fp.Re.IsMatch($txt)) {
                        if ($featureCounts.ContainsKey($fp.Name)) { $featureCounts[$fp.Name]++ } else { $featureCounts[$fp.Name] = 1 }
                        if (-not $featureUsers.ContainsKey($fp.Name)) { $featureUsers[$fp.Name] = [System.Collections.Generic.HashSet[string]]::new() }
                        [void]$featureUsers[$fp.Name].Add($upn)
                        $matched = $true
                        break
                    }
                }
                if (-not $matched) {
                    if ($featureCounts.ContainsKey('Other')) { $featureCounts['Other']++ } else { $featureCounts['Other'] = 1 }
                    if (-not $featureUsers.ContainsKey('Other')) { $featureUsers['Other'] = [System.Collections.Generic.HashSet[string]]::new() }
                    [void]$featureUsers['Other'].Add($upn)
                }
            }
            elseif ($typ -eq 'aiResponse') {
                $responses++
                if ($script:ErrPattern.IsMatch((Get-InteractionText -Interaction $i))) { $errs++ }
            }

            $when = if ($i.PSObject.Properties['createdDateTime']) { ConvertTo-UtcDate -Value ([string]$i.createdDateTime) } else { $null }
            if ($when) {
                $userDates.Add($when); $allDates.Add($when)
                $dayKey = $when.ToString('yyyy-MM-dd')
                if ($eventsTable.Count -lt 5000 -and $typ -eq 'userPrompt') {
                    $snippet = Get-InteractionText -Interaction $i
                    if ($snippet.Length -gt 140) { $snippet = $snippet.Substring(0, 137) + [char]0x2026 }
                    $eventsTable.Add([pscustomobject]@{
                        When     = $when.ToString('yyyy-MM-dd HH:mm')
                        WhenSort = $when.ToString('o')
                        Upn      = $upn
                        App      = $app
                        Type     = 'Prompt'
                        Session  = if ($sid.Length -ge 8) { $sid.Substring(0, 8) } else { $sid }
                        Snippet  = $snippet
                    })
                }
            }
        }

        $lastDt = if ($userDates.Count) { ($userDates | Sort-Object | Select-Object -Last 1) } else { $null }
        $daysSince = if ($lastDt) { [int]([datetime]::UtcNow - $lastDt).TotalDays } else { $null }
        $activeDays = @($userDates | ForEach-Object { $_.Date } | Sort-Object -Unique).Count

        $perUser.Add([pscustomobject]@{
            Upn        = $upn
            Display    = $display
            Total      = $ints.Count
            Prompts    = $prompts
            Responses  = $responses
            Sessions   = $sessions.Count
            Errors     = $errs
            ErrRate    = if ($responses) { $errs / $responses * 100 } else { 0.0 }
            ByApp      = $byApp
            LastStr    = if ($lastDt) { $lastDt.ToString('yyyy-MM-dd') } else { [char]0x2014 }
            DaysSince  = $daysSince
            ActiveDays = $activeDays
        })
    }

    $licensed          = $perUser.Count
    $active            = @($perUser | Where-Object { $_.Prompts -ge 1 }).Count
    $totalInteractions = ($perUser | Measure-Object -Property Total -Sum).Sum
    $totalPrompts      = ($perUser | Measure-Object -Property Prompts -Sum).Sum
    $totalSessions     = ($perUser | Measure-Object -Property Sessions -Sum).Sum
    if (-not $totalInteractions) { $totalInteractions = 0 }
    if (-not $totalPrompts) { $totalPrompts = 0 }
    if (-not $totalSessions) { $totalSessions = 0 }

    $surfacesSorted = $globalByApp.GetEnumerator() |
        Sort-Object -Property @{ Expression = 'Value'; Descending = $true }, @{ Expression = 'Key' } |
        ForEach-Object { $_.Key }
    $surfacesSorted = @($surfacesSorted)

    # ---- report period / day axis ----
    if ($allDates.Count) {
        $tsMin = ($allDates | Sort-Object | Select-Object -First 1)
        $tsMax = ($allDates | Sort-Object | Select-Object -Last 1)
    }
    else {
        $tsMax = [datetime]::UtcNow.Date
        $tsMin = $tsMax.AddDays(-14)
    }
    $dMin = $tsMin.Date; $dMax = $tsMax.Date

    $span = $tsMax - $tsMin
    $durParts = @()
    $secs = [Math]::Max(0, [int]$span.TotalSeconds)
    $days = [Math]::Floor($secs / 86400); $secs -= $days * 86400
    $hours = [Math]::Floor($secs / 3600); $secs -= $hours * 3600
    $mins = [Math]::Floor($secs / 60)
    if ($days) { $durParts += "${days}d" }
    if ($hours) { $durParts += "${hours}h" }
    if ($mins -and -not $days) { $durParts += "${mins}m" }
    $dur = if ($durParts.Count) { $durParts -join ' ' } else { 'under 1m' }
    if ($dMin -eq $dMax) {
        $coverageLabel = "{0} - {1} UTC . {2}" -f $tsMin.ToString('yyyy-MM-dd HH:mm'), $tsMax.ToString('HH:mm'), $dur
    }
    else {
        $coverageLabel = "{0} - {1} UTC . {2}" -f $tsMin.ToString('yyyy-MM-dd HH:mm'), $tsMax.ToString('yyyy-MM-dd HH:mm'), $dur
    }

    $daysAxis = [System.Collections.Generic.List[datetime]]::new()
    $cur = $dMin
    while ($cur -le $dMax) { $daysAxis.Add($cur); $cur = $cur.AddDays(1) }

    $topSurfaces = @($surfacesSorted | Select-Object -First 5)
    $series = @{}
    foreach ($s in $topSurfaces) { $series[$s] = New-Object 'int[]' $daysAxis.Count }
    $dayIndex = @{}
    for ($k = 0; $k -lt $daysAxis.Count; $k++) { $dayIndex[$daysAxis[$k].ToString('yyyy-MM-dd')] = $k }

    foreach ($f in $files) {
        try { $d = Get-Content $f.FullName -Raw | ConvertFrom-Json } catch { continue }
        $ints = @()
        if ($d.PSObject.Properties['interactions'] -and $d.interactions) { $ints = @($d.interactions) }
        foreach ($i in $ints) {
            $app = Get-SurfaceLabel -Interaction $i
            if (-not $series.ContainsKey($app)) { continue }
            $when = if ($i.PSObject.Properties['createdDateTime']) { ConvertTo-UtcDate -Value ([string]$i.createdDateTime) } else { $null }
            if (-not $when) { continue }
            $idxDay = $dayIndex[$when.ToString('yyyy-MM-dd')]
            if ($null -ne $idxDay) { $series[$app][$idxDay]++ }
        }
    }

    $byTotal = @($perUser | Sort-Object -Property Total -Descending)
    $topUsersCount = [Math]::Min(15, $byTotal.Count)

    $appUserCount = @{}
    foreach ($u in $perUser) {
        foreach ($kv in $u.ByApp.GetEnumerator()) {
            if ($kv.Value -gt 0) {
                if ($appUserCount.ContainsKey($kv.Key)) { $appUserCount[$kv.Key]++ } else { $appUserCount[$kv.Key] = 1 }
            }
        }
    }

    $userActionsTop = @($byTotal | Select-Object -First 10)
    $errTop = @($perUser | Where-Object { $_.Responses -ge 5 } | Sort-Object -Property ErrRate -Descending | Select-Object -First 10)

    $eventsTable = @($eventsTable | Sort-Object -Property WhenSort -Descending | Select-Object -First 1000)

    $tuSurfaces = @($surfacesSorted | Select-Object -First 6)

    # ---- HTML fragments ----
    $appUsersRows = ($surfacesSorted | ForEach-Object {
        $cnt = $globalByApp[$_]; $usr = if ($appUserCount.ContainsKey($_)) { $appUserCount[$_] } else { 0 }
        "<tr><td>$(ConvertTo-HtmlText $_)</td><td class=`"right num`">$usr</td><td class=`"right num`">$cnt</td></tr>"
    }) -join "`n"
    $appUsersRows += "`n<tr class=`"tot-row`"><td>Total</td><td class=`"right num`">$active</td><td class=`"right num`">$totalInteractions</td></tr>"

    $tuRows = (@($byTotal | Select-Object -First $topUsersCount) | ForEach-Object {
        $u = $_
        $cells = ($tuSurfaces | ForEach-Object {
            $v = if ($u.ByApp.ContainsKey($_)) { $u.ByApp[$_] } else { 0 }
            "<td class=`"right num`">$(if ($v) { $v } else { '' })</td>"
        }) -join ''
        "<tr><td class=`"upn`" title=`"$(ConvertTo-HtmlText $u.Upn)`">$(ConvertTo-HtmlText $u.Display)</td>" +
        "<td class=`"right num`">$($u.Total)</td><td class=`"right num`">$($u.Sessions)</td>" +
        "<td class=`"right num`">$($u.LastStr)</td>$cells</tr>"
    }) -join "`n"

    $userActionsRows = ($userActionsTop | ForEach-Object {
        $name = $_.Display; if ($name.Length -gt 24) { $name = $name.Substring(0, 22) + [char]0x2026 }
        "<tr><td class=`"upn`" title=`"$(ConvertTo-HtmlText $_.Upn)`">$(ConvertTo-HtmlText $name)</td><td class=`"right num`">$($_.Total)</td></tr>"
    }) -join "`n"
    $userActionsSum = ($userActionsTop | Measure-Object -Property Total -Sum).Sum
    if (-not $userActionsSum) { $userActionsSum = 0 }
    $userActionsRows += "`n<tr class=`"tot-row`"><td>Total</td><td class=`"right num`">$userActionsSum</td></tr>"

    if ($errTop.Count) {
        $errRows = ($errTop | ForEach-Object {
            $name = $_.Display; if ($name.Length -gt 24) { $name = $name.Substring(0, 22) + [char]0x2026 }
            "<tr><td class=`"upn`" title=`"$(ConvertTo-HtmlText $_.Upn)`">$(ConvertTo-HtmlText $name)</td>" +
            "<td class=`"right num`">$($_.Responses)</td>" +
            "<td class=`"right num`" style=`"color:var(--err)`">$($_.Errors) ($('{0:N0}' -f $_.ErrRate)%)</td></tr>"
        }) -join "`n"
    }
    else {
        $errRows = '<tr><td colspan="3" style="color:var(--mute)">No high-error users (&#8805;5 responses).</td></tr>'
    }

    $featureSorted = $featureCounts.GetEnumerator() | Sort-Object -Property Value -Descending
    $featureSorted = @($featureSorted)
    if ($featureSorted.Count) {
        $maxCount = $featureSorted[0].Value
        $featureRows = ($featureSorted | ForEach-Object {
            $usr = if ($featureUsers.ContainsKey($_.Key)) { $featureUsers[$_.Key].Count } else { 0 }
            $pct = if ($totalPrompts) { $_.Value / $totalPrompts * 100 } else { 0 }
            $barW = if ($maxCount) { $_.Value / $maxCount * 100 } else { 0 }
            "<tr><td>$(ConvertTo-HtmlText $_.Key)</td><td class=`"right num`">$($_.Value)</td><td class=`"right num`">$usr</td>" +
            "<td style=`"width:30%`"><div style=`"height:6px;background:var(--alt);border-radius:3px;overflow:hidden`">" +
            "<div style=`"height:100%;width:$('{0:N1}' -f $barW)%;background:var(--accent);border-radius:3px`"></div></div></td>" +
            "<td class=`"right num`">$('{0:N1}' -f $pct)%</td></tr>"
        }) -join "`n"
    }
    else {
        $featureRows = '<tr><td colspan="4" style="color:var(--mute)">No prompt data available.</td></tr>'
    }

    $leaderRows = ($byTotal | ForEach-Object {
        $u = $_; $top = Get-TopKey -Map $u.ByApp; if (-not $top) { $top = '' }
        $errColor = if ($u.ErrRate -ge 10) { 'var(--err)' } else { 'inherit' }
        "<tr data-app=`"$(ConvertTo-HtmlText $top)`">" +
        "<td class=`"upn`" title=`"$(ConvertTo-HtmlText $u.Upn)`">$(ConvertTo-HtmlText $u.Display)</td>" +
        "<td class=`"right num`">$($u.Total)</td><td class=`"right num`">$($u.Prompts)</td>" +
        "<td class=`"right num`">$($u.Responses)</td><td class=`"right num`">$($u.Sessions)</td>" +
        "<td class=`"right num`">$($u.ActiveDays)</td>" +
        "<td>$(if ($top) { ConvertTo-HtmlText $top } else { [char]0x2014 })</td>" +
        "<td class=`"right num`" style=`"color:$errColor`">$($u.Errors) ($('{0:N0}' -f $u.ErrRate)%)</td>" +
        "<td class=`"right num`">$(ConvertTo-HtmlText $u.LastStr)</td></tr>"
    }) -join "`n"

    $eventRows = ($eventsTable | ForEach-Object {
        "<tr><td class=`"num`">$(ConvertTo-HtmlText $_.When)</td><td class=`"upn`">$(ConvertTo-HtmlText $_.Upn)</td>" +
        "<td>$(ConvertTo-HtmlText $_.App)</td><td>$(ConvertTo-HtmlText $_.Type)</td>" +
        "<td class=`"num`" style=`"font-family:Consolas,monospace;color:var(--mute)`">$(ConvertTo-HtmlText $_.Session)</td>" +
        "<td>$(ConvertTo-HtmlText $_.Snippet)</td></tr>"
    }) -join "`n"

    # ---- chart + leaderboard data ----
    $chartDatasets = @()
    for ($i = 0; $i -lt $topSurfaces.Count; $i++) {
        $s = $topSurfaces[$i]; $color = $script:Palette[$i % $script:Palette.Count]
        $chartDatasets += '{"label":' + (ConvertTo-Json -Compress -InputObject $s) +
            ',"data":' + (ConvertTo-JsonArray $series[$s]) +
            ',"borderColor":"' + $color + '","backgroundColor":"' + $color + '20"' +
            ',"tension":0.25,"pointRadius":2,"borderWidth":1.5}'
    }
    $chartDatasetsJson = '[' + ($chartDatasets -join ',') + ']'
    $daysLabelsJson = ConvertTo-JsonArray (@($daysAxis | ForEach-Object { $_.ToString('MMM dd') }))

    $lbData = $perUser | ForEach-Object {
        $top = Get-TopKey -Map $_.ByApp; if (-not $top) { $top = [char]0x2014 }
        [pscustomobject][ordered]@{
            display    = $_.Display; upn = $_.Upn; total = $_.Total
            prompts    = $_.Prompts; responses = $_.Responses; sessions = $_.Sessions
            last       = $_.LastStr; errors = $_.Errors
            err_rate   = [Math]::Round($_.ErrRate, 1)
            active_days = $_.ActiveDays
            top_surface = $top
            days_since = if ($null -ne $_.DaysSince) { $_.DaysSince } else { 999 }
        }
    }
    $lbDataJson = ConvertTo-JsonArray $lbData

    $legendParts = for ($i = 0; $i -lt $topSurfaces.Count; $i++) {
        "<span><i style=`"background:$($script:Palette[$i % $script:Palette.Count])`"></i>$(ConvertTo-HtmlText $topSurfaces[$i])</span>"
    }
    $legendHtml = $legendParts -join ''
    $tuHead = ($tuSurfaces | ForEach-Object { "<th class=`"right`">$(ConvertTo-HtmlText $_)</th>" }) -join ''

    $totalInteractionsFmt = '{0:N0}' -f [int64]$totalInteractions
    $totalSessionsFmt = '{0:N0}' -f [int64]$totalSessions
    $generated = [datetime]::UtcNow.ToString('yyyy-MM-dd HH:mm') + ' UTC'
    $eventsCount = $eventsTable.Count

    $css = Get-ReportCss
    $html = @"
<!doctype html><html lang="en"><head><meta charset="utf-8">
<title>Copilot Audit Dashboard</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<style>$css</style></head><body>
<div class="app">

<div class="bar">
  <div>
    <h1>Copilot Audit Dashboard</h1>
    <div class="stats">
      <div class="stat"><div class="num">$active</div><div class="lab">Active Users</div></div>
      <div class="stat"><div class="num">$licensed</div><div class="lab">Total Users</div></div>
      <div class="stat"><div class="num">$totalInteractionsFmt</div><div class="lab">Interactions</div></div>
      <div class="stat"><div class="num">$totalSessionsFmt</div><div class="lab">Sessions</div></div>
    </div>
  </div>
  <div style="flex:1;text-align:right;color:var(--mute);font-size:12px;align-self:flex-end">
    <div style="font-weight:600;color:var(--ink2)">Report period</div>
    $coverageLabel
  </div>
</div>

<div class="grid">
  <div class="panel col-7">
    <h3>Copilot Events Over Time</h3>
    <canvas id="eventsChart" height="120"></canvas>
    <div class="legend">$legendHtml</div>
  </div>
  <div class="panel col-5">
    <h3>App / # Users / # Actions</h3>
    <table class="t">
      <thead><tr><th>App</th><th class="right"># Users</th><th class="right"># Actions</th></tr></thead>
      <tbody>$appUsersRows</tbody>
    </table>
  </div>
</div>

<div class="grid">
  <div class="panel col-7">
    <h3>Top Users</h3>
    <div class="sub">Interaction breakdown across the most-used Copilot surfaces.</div>
    <table class="t">
      <thead><tr><th>UPN</th><th class="right">Total</th><th class="right">Sessions</th><th class="right">Last seen</th>$tuHead</tr></thead>
      <tbody>$tuRows</tbody>
    </table>
  </div>
  <div class="panel col-3">
    <h3>User / # Actions</h3>
    <table class="t">
      <thead><tr><th>User</th><th class="right"># Actions</th></tr></thead>
      <tbody>$userActionsRows</tbody>
    </table>
  </div>
  <div class="panel col-2">
    <h3>Friction</h3>
    <div class="sub">Top error rates</div>
    <table class="t">
      <thead><tr><th>User</th><th class="right">Resp</th><th class="right">Err</th></tr></thead>
      <tbody>$errRows</tbody>
    </table>
  </div>
</div>

<div class="grid">
  <div class="panel col-12">
    <h3>Usage by App Feature</h3>
    <div class="sub">Prompt intent classified by keyword pattern matching across all user prompts.</div>
    <table class="t">
      <thead><tr><th>Feature / Intent</th><th class="right">Prompts</th><th class="right">Users</th><th>Distribution</th><th class="right">Share</th></tr></thead>
      <tbody>$featureRows</tbody>
    </table>
  </div>
</div>

<div class="grid">
  <div class="panel col-12">
    <h3>All Users</h3>
    <table class="t" id="leader">
      <thead><tr>
        <th data-k="display">User</th>
        <th data-k="total" class="right">Total</th>
        <th data-k="prompts" class="right">Prompts</th>
        <th data-k="responses" class="right">Responses</th>
        <th data-k="sessions" class="right">Sessions</th>
        <th data-k="active_days" class="right">Active Days</th>
        <th data-k="top_surface">Top Surface</th>
        <th data-k="err_rate" class="right">Errors</th>
        <th data-k="last" class="right">Last Active</th>
      </tr></thead>
      <tbody>$leaderRows</tbody>
    </table>
  </div>
</div>

<div class="grid">
  <div class="panel col-12">
    <h3>Audited Events <span style="font-weight:400;color:var(--mute);font-size:12px">&#8212; most recent $eventsCount prompts</span></h3>
    <div class="events-tbl">
      <table class="t">
        <thead><tr><th>CreationTime</th><th>UserPrincipalName</th><th>App</th><th>Type</th><th>SessionId</th><th>Prompt snippet</th></tr></thead>
        <tbody>$eventRows</tbody>
      </table>
    </div>
  </div>
</div>

<p style="color:var(--mute);font-size:11px;margin:24px 0 4px;line-height:1.5;text-align:center">
  Note: Copilot Studio agents (declarative / custom agents invoked from Copilot Chat) do not register with the
  Microsoft Graph interaction-history API this report is built on, so their usage is not reflected in the counts above.
</p>
<footer>Generated $generated</footer>
</div>

<script>
Chart.defaults.color = '#707070';
Chart.defaults.borderColor = '#e8e8e8';
Chart.defaults.font.family = "'Segoe UI Variable Text','Segoe UI',-apple-system,system-ui,sans-serif";
Chart.defaults.font.size = 11;

new Chart(document.getElementById('eventsChart'), {
  type:'line',
  data:{labels:$daysLabelsJson,datasets:$chartDatasetsJson},
  options:{
    plugins:{legend:{display:false},tooltip:{mode:'index',intersect:false}},
    interaction:{mode:'index',intersect:false},
    scales:{y:{grid:{color:'#f0f0f0'},beginAtZero:true},x:{grid:{display:false}}}
  }
});

(function(){
  const tbl  = document.getElementById('leader');
  const body = tbl.querySelector('tbody');
  const rows = Array.from(body.querySelectorAll('tr'));
  const data = $lbDataJson;
  let sortKey='total', sortDir=-1;

  function render(){
    const order = data.map((d,i)=>({d,i}))
      .sort((a,b)=>{
        const va=a.d[sortKey], vb=b.d[sortKey];
        if (typeof va === 'number') return (va-vb)*sortDir;
        return String(va).localeCompare(String(vb))*sortDir;
      });
    body.innerHTML='';
    order.forEach(x=>body.appendChild(rows[x.i]));
  }

  tbl.querySelectorAll('th[data-k]').forEach(th=>{
    th.onclick = ()=>{
      const k = th.dataset.k;
      sortDir = (sortKey===k) ? -sortDir : -1;
      sortKey = k; render();
    };
  });
})();
</script>
</body></html>
"@

    $outDir = Split-Path -Parent $OutHtml
    if ($outDir) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
    $html | Set-Content -Path $OutHtml -Encoding utf8

    [pscustomobject]@{
        Out          = $OutHtml
        Users        = $licensed
        Active       = $active
        Interactions = $totalInteractions
        Sessions     = $totalSessions
    }
}

function Get-ReportCss {
    @'
:root{
  --ink:#242424;--ink2:#424242;--mute:#707070;--border:#e8e8e8;--rule:#d1d1d1;
  --bg:#f5f5f5;--card:#ffffff;--alt:#fafafa;--accent:#0f6cbd;--accent2:#107c10;
  --pill:#ebf3fc;--pillb:#b4d6fa;--err:#c4314b;
  --shadow:0 2px 4px rgba(0,0,0,.04),0 1px 2px rgba(0,0,0,.02);
  --shadow-lg:0 4px 8px rgba(0,0,0,.06),0 2px 4px rgba(0,0,0,.04);
  --radius:8px;--radius-sm:6px;
}
*{box-sizing:border-box;margin:0}
html,body{padding:0;background:var(--bg);color:var(--ink);
  font-family:'Segoe UI Variable Text','Segoe UI',-apple-system,system-ui,sans-serif;font-size:13px;line-height:1.5;-webkit-font-smoothing:antialiased}
.app{max-width:1700px;margin:0 auto;padding:20px 24px}
.bar{display:flex;align-items:flex-start;gap:24px;flex-wrap:wrap;
  background:var(--card);border-radius:var(--radius);padding:20px 24px;margin-bottom:16px;box-shadow:var(--shadow)}
.bar h1{margin:0 0 14px;font-size:20px;font-weight:600;color:var(--ink);letter-spacing:-.02em}
.bar .stats{display:flex;gap:28px}
.stat .num{font-size:30px;font-weight:600;line-height:1;color:var(--ink);font-variant-numeric:tabular-nums}
.stat .lab{font-size:11px;color:var(--mute);margin-top:4px;font-weight:500;letter-spacing:.2px}

.grid{display:grid;grid-template-columns:repeat(12,1fr);gap:14px;margin-bottom:14px}
.col-12{grid-column:span 12}.col-8{grid-column:span 8}.col-7{grid-column:span 7}.col-6{grid-column:span 6}.col-5{grid-column:span 5}.col-4{grid-column:span 4}.col-3{grid-column:span 3}.col-2{grid-column:span 2}
@media(max-width:1100px){.col-8,.col-7,.col-6,.col-5,.col-4,.col-3,.col-2{grid-column:span 12}}

.panel{background:var(--card);border-radius:var(--radius);padding:16px 18px;box-shadow:var(--shadow)}
.panel h3{margin:0 0 10px;font-size:14px;font-weight:600;color:var(--ink);letter-spacing:-.01em}
.panel.compact{padding:12px 14px}
.panel .sub{color:var(--mute);font-size:11px;margin-top:-6px;margin-bottom:10px}

table.t{width:100%;border-collapse:collapse;font-size:12px}
table.t th{text-align:left;font-weight:600;color:var(--mute);border-bottom:1px solid var(--rule);
  padding:6px 8px;font-size:11px;letter-spacing:.2px;background:transparent;white-space:nowrap;cursor:pointer;user-select:none}
table.t th.right,table.t td.right{text-align:right}
table.t td{padding:5px 8px;border-bottom:1px solid var(--border);vertical-align:middle}
table.t tr:nth-child(even) td{background:var(--alt)}
table.t tr:hover td{background:#ebf3fc}
table.t .upn{color:var(--accent);font-weight:500}
table.t .num{font-variant-numeric:tabular-nums}
.tot-row td{font-weight:600;background:#f0f0f0 !important;border-top:1px solid var(--rule)}

canvas{max-width:100%}

.events-tbl{max-height:380px;overflow:auto;border:1px solid var(--border);border-radius:var(--radius-sm)}
.events-tbl table.t th{position:sticky;top:0;background:var(--card);z-index:1}

.legend{display:flex;gap:14px;flex-wrap:wrap;margin-top:8px}
.legend span{display:inline-flex;align-items:center;gap:5px;font-size:11px;color:var(--mute)}
.legend i{display:inline-block;width:10px;height:10px;border-radius:2px}
footer{color:var(--mute);font-size:11px;text-align:center;padding:20px}
'@
}


Export-ModuleMember -Function New-GraphContext, Export-CopilotInteractions, Build-CopilotReport
