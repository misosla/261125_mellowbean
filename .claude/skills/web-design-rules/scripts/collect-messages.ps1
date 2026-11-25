# Prints the messages the user typed in this project since the last update.
# Keep this file ASCII only: Windows PowerShell 5.1 misreads UTF-8 without a BOM.
param(
  [Parameter(Mandatory = $true)][string]$ProjectDir,
  [string]$Since
)
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$utf8 = New-Object System.Text.UTF8Encoding $false
$project = $ProjectDir.TrimEnd('\', '/').Replace('/', '\')

if (-not $Since) {
  $stamp = Join-Path (Split-Path $PSScriptRoot -Parent) 'last-updated.txt'
  if (Test-Path -LiteralPath $stamp) { $Since = [IO.File]::ReadAllText($stamp, $utf8).Trim() } else { $Since = '2000-01-01 00:00' }
}
if ($Since.Length -eq 10) { $Since += ' 00:00' }
$sinceDate = [datetime]::ParseExact($Since, 'yyyy-MM-dd HH:mm', [Globalization.CultureInfo]::InvariantCulture)

$files = Get-ChildItem -Path (Join-Path $env:USERPROFILE '.claude\projects\*\*.jsonl') -ErrorAction SilentlyContinue |
  Where-Object { $_.LastWriteTime -ge $sinceDate } | Sort-Object LastWriteTime

foreach ($f in $files) {
  # ReadWrite sharing: the transcript of the running session is still open.
  $stream = New-Object IO.FileStream $f.FullName, 'Open', 'Read', 'ReadWrite'
  $reader = New-Object IO.StreamReader $stream, $utf8
  try {
    while ($null -ne ($line = $reader.ReadLine())) {
      if ($line.Length -gt 500000) { continue }
      if ($line -notmatch '"type":"user"' -or $line -match '"type":"tool_result"') { continue }
      try { $r = $line | ConvertFrom-Json } catch { continue }
      if ($r.type -ne 'user' -or $r.isMeta -or $r.isSidechain -or -not $r.cwd) { continue }
      if ($r.cwd.TrimEnd('\', '/').Replace('/', '\') -ine $project) { continue }
      $when = ([datetime]$r.timestamp).ToLocalTime()
      if ($when -lt $sinceDate) { continue }
      $c = $r.message.content
      if ($c -is [string]) { $text = $c }
      else { $text = (@($c | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join "`n") }
      $text = [regex]::Replace($text, '(?s)<(system-reminder|ide_[a-z_]+|task-notification|local-command-[a-z]+)\b[^>]*>.*?</\1>', '').Trim()
      if (-not $text) { continue }
      '[' + $when.ToString('yyyy-MM-dd HH:mm') + '] ' + $text
      '---'
    }
  } finally { $reader.Dispose() }
}
