param(
  [Parameter(Mandatory = $true)]
  [string]$JenkinsUrl,

  [Parameter(Mandatory = $true)]
  [string]$JobName,

  [Parameter(Mandatory = $true)]
  [string]$JenkinsUser,

  [Parameter(Mandatory = $true)]
  [string]$JenkinsApiToken,

  [string]$ConfigPath = "jenkins/rds-mysql-provision-job.xml",

  [Parameter(Mandatory = $true)]
  [string]$GitRepositoryUrl,

  [string]$GitBranch = "main",

  [string]$GitCredentialsId = ""
)

$ErrorActionPreference = "Stop"

function Join-JenkinsUrl {
  param(
    [string]$BaseUrl,
    [string]$Path
  )

  return ($BaseUrl.TrimEnd("/") + "/" + $Path.TrimStart("/"))
}

function ConvertTo-BasicAuthHeader {
  param(
    [string]$User,
    [string]$Token
  )

  $bytes = [System.Text.Encoding]::ASCII.GetBytes("${User}:${Token}")
  return "Basic " + [Convert]::ToBase64String($bytes)
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
  throw "Jenkins job config file was not found: $ConfigPath"
}

$headers = @{
  Authorization = ConvertTo-BasicAuthHeader -User $JenkinsUser -Token $JenkinsApiToken
}

$crumbUrl = Join-JenkinsUrl -BaseUrl $JenkinsUrl -Path "crumbIssuer/api/json"
$crumb = Invoke-RestMethod -Method Get -Uri $crumbUrl -Headers $headers
$headers[$crumb.crumbRequestField] = $crumb.crumb

$configXml = Get-Content -LiteralPath $ConfigPath -Raw
$configXml = $configXml.Replace("__GIT_REPOSITORY_URL__", [System.Security.SecurityElement]::Escape($GitRepositoryUrl))
$configXml = $configXml.Replace("__GIT_BRANCH__", [System.Security.SecurityElement]::Escape($GitBranch))
$configXml = $configXml.Replace("__GIT_CREDENTIALS_ID__", [System.Security.SecurityElement]::Escape($GitCredentialsId))

$jobApiUrl = Join-JenkinsUrl -BaseUrl $JenkinsUrl -Path "job/$JobName/api/json"
$jobExists = $true

try {
  Invoke-RestMethod -Method Get -Uri $jobApiUrl -Headers $headers | Out-Null
} catch {
  $jobExists = $false
}

if ($jobExists) {
  $configUrl = Join-JenkinsUrl -BaseUrl $JenkinsUrl -Path "job/$JobName/config.xml"
  Invoke-RestMethod -Method Post -Uri $configUrl -Headers $headers -ContentType "application/xml" -Body $configXml | Out-Null
  Write-Host "Updated Jenkins job '$JobName'."
} else {
  $createUrl = Join-JenkinsUrl -BaseUrl $JenkinsUrl -Path "createItem?name=$([uri]::EscapeDataString($JobName))"
  Invoke-RestMethod -Method Post -Uri $createUrl -Headers $headers -ContentType "application/xml" -Body $configXml | Out-Null
  Write-Host "Created Jenkins job '$JobName'."
}

