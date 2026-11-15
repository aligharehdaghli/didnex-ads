$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
  flutter --version
  if ($LASTEXITCODE -ne 0) { throw 'Flutter is required.' }
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'pub get failed.' }
  flutter analyze
  if ($LASTEXITCODE -ne 0) { throw 'analyze failed.' }
  flutter test
  if ($LASTEXITCODE -ne 0) { throw 'SDK tests failed.' }
  Push-Location example
  try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'example pub get failed.' }
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'example analyze failed.' }
  } finally { Pop-Location }
} finally { Pop-Location }
