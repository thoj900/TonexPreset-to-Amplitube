# Generate-At5p.ps1
param(
  [string]$CsvPath = ".\Presets.csv",
  [string]$TemplatePath = ".\base_template.at5p",
  [string]$OutDir = ".\out"
)

# --- Helpers
function Map-OnOff($v) {
  if ($null -eq $v) { return "Off" }
  $s = ($v.ToString()).ToLower().Trim()
  if ($s -in @("1","true","on","yes")) { "On" } else { "Off" }
}
function Map-PrePost($v) {
  if ($null -eq $v) { return "Pre" }
  $s = ($v.ToString()).ToLower().Trim()
  if ($s -in @("1","true","post")) { "Post" } else { "Pre" }
}
function Coalesce([string[]]$vals) {
  foreach ($v in $vals) { if ($v -and $v.Trim() -ne "") { return $v } }
  return ""
}
function Sanitize-FileName($name) {
  $n = "$name"
  $n = $n -replace '"',''  # drop quotes
  $n = $n.Trim()
  $invalid = ([IO.Path]::GetInvalidFileNameChars() -join '')
  $re = "[{0}]" -f [Regex]::Escape($invalid)
  $n -replace $re, "_"
}
function Nz($val, $fallback) {
  if ($null -eq $val -or "$val".Trim() -eq "") { return $fallback } else { return "$val" }
}

# --- Load template (full preset structure)
if (!(Test-Path $TemplatePath)) { throw "Template not found: $TemplatePath" }
$template = Get-Content -Raw -Path $TemplatePath

# Do NOT touch <Input> — per your request, we leave it exactly as in the template

# Capture the opening <AmpA ...> (to preserve its attributes from your template)
$ampAOpenMatch = [regex]::Match($template, '(?s)(<AmpA\b[^>]*>)')
if (-not $ampAOpenMatch.Success) { throw "AmpA block not found in template." }
$ampAOpener = $ampAOpenMatch.Groups[1].Value

# --- Read CSV (first row is headers; data starts automatically from row 2)
if (!(Test-Path $CsvPath)) { throw "CSV not found: $CsvPath" }
$rows = Import-Csv -Path $CsvPath

# Ensure out dir
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

# --- Generate one .at5p per row
$exported = 0
foreach ($row in $rows) {
  # Map values
  $EqPosition   = Map-PrePost $row.EqPost
  $CompPosition = Map-PrePost $row.CompPost

  $ReverbEnable = Map-OnOff $row.ReverbEnable
  $CompEnable   = Map-OnOff $row.CompEnable
  $CabVIREnable = Map-OnOff $row.CabVIREnable

  # Noise gate: fixed off, but keep thresholds from CSV
  # $NoiseEnable  = Map-OnOff $row.NoiseGateEnable   # ignored by design

  $ToneModelGUID = Coalesce @($row.ToneModel_GUID, $row.OptionalToneModel_GUID, $row.ToneModelGUID)
  $ToneModelName = Coalesce @($row.PresetName, $row.Tag_PresetName, $row.ToneModelName)

  # Build <Amp .../> 
  # - ModelEnable fixed to "1"
  # - NoiseGateEnable fixed to "0"
  # - Other parameters read from CSV
  $ampTag = @"
<Amp ModelEnable="1" Mix="$(Nz $row.ModelMix '100')" EqPosition="$EqPosition"
     Bass="$($row.EqBass)" BassFreq="$($row.EqBassFreq)"
     Mid="$($row.EqMid)" MidQ="$($row.EqMidQ)" MidFreq="$($row.EqMidFreq)"
     Treble="$($row.EqTreble)" TrebleFreq="$($row.EqTrebleFreq)"
     Gain="$($row.ModelGain)" Volume="$($row.ModelVolume)"
     Presence="$($row.PwrAmpEqPresence)" Depth="$($row.PwrAmpEqDepth)"
     ReverbEnable="$ReverbEnable" ReverbModel="$($row.ReverbModel)" ReverbTime="$($row.ReverbTime)"
     ReverbPreDelay="$($row.ReverbPreDelay)" ReverbColor="$($row.ReverbColor)" ReverbLevel="$(Coalesce @($row.ReverbLevel, $row.ReverbMix))"
     NoiseGateEnable="0" NoiseGateThreshold="$($row.NoiseGateThreshold)"
     NoiseGateRelease="$($row.NoiseGateRelease)" NoiseGateDepth="$($row.NoiseGateDepth)"
     CompEnable="$CompEnable" CompPosition="$CompPosition" CompThreshold="$($row.CompThreshold)"
     CompMakeUp="$($row.CompMakeUp)" CompAttack="$($row.CompAttack)"
     CabVIREnable="$CabVIREnable"
     ToneModelGUID="$ToneModelGUID" ToneModelName="$ToneModelName" />
"@.Trim()

  # New AmpA block (reuse the opener from the template)
  $newAmpABlock = "$ampAOpener`r`n        $ampTag`r`n    </AmpA>"

  # Replace the existing AmpA block with our new one; everything else stays untouched
  $finalXml = [regex]::Replace(
    $template,
    '(?s)<AmpA\b[^>]*>.*?</AmpA>',
    [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $newAmpABlock }
  )

  # File name from Tag_PresetName, else ToneModelName
  $name = if ($row.Tag_PresetName) { $row.Tag_PresetName } else { $ToneModelName }
  $safe = Sanitize-FileName $name
  if (-not $safe) { $safe = "Preset_$exported" }
  $outFile = Join-Path $OutDir ($safe + ".at5p")

  # Write the preset
  Set-Content -LiteralPath $outFile -Value $finalXml -Encoding UTF8
  $exported++
  Write-Host "Wrote $outFile"
}

Write-Host "Done. Exported $exported preset(s) to $OutDir."