# Git Quick Commit - Fast commit without push
# Purpose: Commit work-in-progress to local Git (safety net)
# Usage: .\GIT-QUICK-COMMIT.ps1 -Message "Working on financial domain"

param(
    [Parameter(Mandatory=$true)]
    [string]$Message,
    
    [switch]$Push = $false
)

$repoPath = "C:\TEKA_NET\Teka_StoreNET_ERP"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "=== GIT QUICK COMMIT ===" -ForegroundColor Cyan
Write-Host ""

Push-Location $repoPath

# Check if there are changes
$status = git status --porcelain
if ($status) {
    Write-Host "[1/3] Found changes to commit:" -ForegroundColor Yellow
    git status --short
    Write-Host ""
    
    # Add all changes
    git add .
    Write-Host "[2/3] Staged all changes" -ForegroundColor Green
    
    # Commit
    $commitMessage = "WIP: $Message [$timestamp]"
    git commit -m $commitMessage
    Write-Host "[3/3] Committed: $commitMessage" -ForegroundColor Green
    
    # Optional push
    if ($Push) {
        Write-Host ""
        Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
        git push origin main
        Write-Host "[✓] Pushed to remote" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "[!] Not pushed to remote (use -Push to push)" -ForegroundColor Yellow
        Write-Host "    To push later: cd $repoPath && git push" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "=== COMMIT COMPLETE ===" -ForegroundColor Cyan
} else {
    Write-Host "[!] No changes to commit" -ForegroundColor Yellow
    Write-Host ""
}

Pop-Location

