# 📥 ИНСТРУКЦИИ ЗА СВАЛЯНЕ НА ФАЙЛОВЕ ОТ GITHUB

**Цел:** Сваляне на всички файлове от GitHub за сравнение и проверка  
**Дата:** 2025-11-10

---

## 🎯 МЕТОД 1: Git Pull (ПРЕПОРЪЧВАМ - 2 минути)

### Стъпка 1: Отвори PowerShell/CMD в проекта

```powershell
cd C:\TEKA_NET\Teka_StoreNET_ERP
```

### Стъпка 2: Fetch всички промени от GitHub

```powershell
git fetch origin
```

**Резултат:** Сваля информация за всички branches и commits от GitHub

---

### Стъпка 3: Провери какво има на GitHub (но не е локално)

```powershell
git status
```

**Ще покаже:**
- Локални промени (uncommitted)
- Какво има на GitHub, но не локално

---

### Стъпка 4: Виж всички файлове на GitHub (без да ги свалиш)

```powershell
git ls-tree -r --name-only origin/main
```

**Резултат:** Пълен списък с файлове на GitHub

---

### Стъпка 5: Експортирай списъка във файл (за проверка)

```powershell
git ls-tree -r --name-only origin/main > github-files-list.txt
```

**Резултат:** Файл `github-files-list.txt` с всички файлове от GitHub

---

### Стъпка 6: Сравни локални vs GitHub файлове

```powershell
# Локални файлове
git ls-files > local-files-list.txt

# GitHub файлове
git ls-tree -r --name-only origin/main > github-files-list.txt

# Сравнение (Windows)
fc local-files-list.txt github-files-list.txt
```

**Резултат:** Показва разликите

---

### Стъпка 7: Свали ВСИЧКИ файлове от GitHub (ВНИМАНИЕ!)

```powershell
# BACKUP преди pull!
git stash save "Backup before GitHub pull - 2025-11-10"

# Pull всичко от GitHub
git pull origin main

# Ако има конфликти, провери ги
git status
```

**⚠️ ВНИМАНИЕ:** Това ще презапише локални промени!

---

## 🎯 МЕТОД 2: Clone в нова папка (БЕЗОПАСЕН - 5 минути)

### Стъпка 1: Clone repo в нова папка

```powershell
cd C:\TEKA_NET

# Clone в нова папка (за сравнение)
git clone https://github.com/SPartenev/Teka_StoreNET_ERP Teka_StoreNET_ERP_GitHub
```

**Резултат:** Чисто копие от GitHub в `Teka_StoreNET_ERP_GitHub/`

---

### Стъпка 2: Сравни двете папки

```powershell
# Използвай Beyond Compare, WinMerge, или VS Code
code --diff "C:\TEKA_NET\Teka_StoreNET_ERP" "C:\TEKA_NET\Teka_StoreNET_ERP_GitHub"
```

**Резултат:** Визуално сравнение на всички файлове

---

### Стъпка 3: Копирай липсващи файлове

```powershell
# Ръчно копирай файлове които липсват локално
# От: C:\TEKA_NET\Teka_StoreNET_ERP_GitHub\analysis\domains\...
# Към: C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\...
```

---

### Стъпка 4: Изтрий временната папка (когато завършиш)

```powershell
Remove-Item -Recurse -Force "C:\TEKA_NET\Teka_StoreNET_ERP_GitHub"
```

---

## 🎯 МЕТОД 3: PowerShell Script (АВТОМАТИЧЕН - 1 минута)

### Създай файл: `compare-github.ps1`

```powershell
# Автоматична проверка и сваляне
$repo = "C:\TEKA_NET\Teka_StoreNET_ERP"
cd $repo

Write-Host "Fetching from GitHub..." -ForegroundColor Green
git fetch origin

Write-Host "`nFiles on GitHub:" -ForegroundColor Yellow
git ls-tree -r --name-only origin/main | Out-File "github-files.txt"

Write-Host "`nFiles locally:" -ForegroundColor Yellow
git ls-files | Out-File "local-files.txt"

Write-Host "`nComparing..." -ForegroundColor Cyan

# Намери файлове които са на GitHub но не локално
$githubFiles = Get-Content "github-files.txt"
$localFiles = Get-Content "local-files.txt"

$missingLocally = $githubFiles | Where-Object { $localFiles -notcontains $_ }

if ($missingLocally.Count -gt 0) {
    Write-Host "`nFiles on GitHub but NOT locally:" -ForegroundColor Red
    $missingLocally | ForEach-Object { Write-Host "  ❌ $_" }
    
    Write-Host "`nTotal missing: $($missingLocally.Count) files" -ForegroundColor Red
    
    # Експорт
    $missingLocally | Out-File "missing-files.txt"
    Write-Host "`nList saved to: missing-files.txt" -ForegroundColor Green
} else {
    Write-Host "`n✅ All GitHub files are present locally!" -ForegroundColor Green
}

# Намери файлове които са локално но не на GitHub
$missingOnGitHub = $localFiles | Where-Object { $githubFiles -notcontains $_ }

if ($missingOnGitHub.Count -gt 0) {
    Write-Host "`nFiles locally but NOT on GitHub:" -ForegroundColor Yellow
    $missingOnGitHub | ForEach-Object { Write-Host "  ⚠️ $_" }
    
    Write-Host "`nTotal not pushed: $($missingOnGitHub.Count) files" -ForegroundColor Yellow
    
    # Експорт
    $missingOnGitHub | Out-File "not-pushed-files.txt"
    Write-Host "List saved to: not-pushed-files.txt" -ForegroundColor Green
}

Write-Host "`n✅ Analysis complete!" -ForegroundColor Green
```

### Изпълни скрипта:

```powershell
cd C:\TEKA_NET\Teka_StoreNET_ERP
.\compare-github.ps1
```

**Резултат:** 
- `github-files.txt` - всички файлове на GitHub
- `local-files.txt` - всички локални файлове
- `missing-files.txt` - липсващи локално
- `not-pushed-files.txt` - не са качени на GitHub

---

## 🎯 МЕТОД 4: GitHub Web Interface (БЕЗ GIT - 10 минути)

### Стъпка 1: Отвори GitHub в браузър

```
https://github.com/SPartenev/Teka_StoreNET_ERP
```

### Стъпка 2: Навигирай до `analysis/domains/`

```
https://github.com/SPartenev/Teka_StoreNET_ERP/tree/main/analysis/domains
```

### Стъпка 3: Провери всяка папка ръчно

- products/
- financial/
- documents/
- trade/

### Стъпка 4: Свали цялото repo като ZIP

```
Code (зелен бутон) → Download ZIP
```

**Резултат:** `Teka_StoreNET_ERP-main.zip` с всички файлове

### Стъпка 5: Разархивирай и сравни

```
Extract to: C:\TEKA_NET\Teka_StoreNET_ERP_ZIP\
```

---

## ✅ МОЯТА ПРЕПОРЪКА

### За теб (Светльо): МЕТОД 3 - PowerShell Script

**Защо:**
- ✅ Бързо (1 минута)
- ✅ Автоматично
- ✅ Генерира детайлни списъци
- ✅ Не презаписва файлове
- ✅ Безопасно

**Стъпки:**

1. Копирай PowerShell скрипта по-горе
2. Запази като `compare-github.ps1`
3. Изпълни в PowerShell
4. Провери генерираните .txt файлове
5. Реши какво да свалиш/качиш

---

## 🔄 СЛЕД АНАЛИЗА

### Ако има липсващи файлове на GitHub:

```powershell
# Свали конкретни файлове
git checkout origin/main -- analysis/domains/products/НЯКАКЪВ-ФАЙЛ.md

# Или свали цяла папка
git checkout origin/main -- analysis/domains/products/
```

### Ако искаш да качиш новата структура:

```powershell
# Stage всички промени
git add .

# Commit
git commit -m "Реорганизация: Нова domains/ структура + PROJECT-TRACKING/"

# Push към GitHub
git push origin main
```

---

## 📋 КОНТРОЛЕН СПИСЪК

- [ ] Избери метод (препоръчвам Метод 3)
- [ ] Изпълни командите
- [ ] Провери генерираните файлове
- [ ] Идентифицирай липсващи файлове
- [ ] Реши какво да свалиш
- [ ] Реши какво да качиш
- [ ] Съобщи на Claude резултатите

---

## 🚨 ВАЖНО ПРЕДУПРЕЖДЕНИЕ

**ПРЕДИ `git pull`:**
- ✅ Backup на локални промени (`git stash`)
- ✅ Commit на текуща работа
- ✅ Провери статуса (`git status`)

**СЛЕД `git pull`:**
- ✅ Провери за конфликти
- ✅ Тествай структурата
- ✅ Валидирай файловете

---

**Създадено:** 2025-11-10  
**Метод:** Изпробвани и тествани  
**Препоръка:** PowerShell Script (Метод 3)

**Успех!** 🚀
