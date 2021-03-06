﻿. .\Connect-Mstsc.ps1


$runtime      = [int]$args[0]
$reqs_per_sec = [int]$args[1]
$rdp_host     = $args[2]
$name_base    = $args[3]
$pass         = $args[4]
$net_use_host = $args[5]
$urls         = $args[6]


$runtime = 604800 # 1 Week
$reqs_per_second = 10

$rdp = 0
$net_use = 0
$web_req = 0

$num_services = 1

if ($runtime -eq $null) { $runtime = 60 }
if ($reqs_sec -eq $null) { $reqs_sec = 10 }
if ($rdp_host -eq $null) { $rdp_host = 'ts.afnet.com' }
if ($name_base -eq $null ) { $name_base = "user" }
if ($pass -eq $null ) { $pass = "!@12QWqwe" }
if ($net_use_host -eq $null) { $net_use_host = '\\TS\Shared' }
if ($urls -eq $null ) { $urls = "google.com,yahoo.com,espn.com".Split(',') }
else { $urls = $urls.Split(',') }

$end_time = [convert]::ToDecimal((Get-Date -UFormat "%s")) + $runtime
do {
    $start_time = [convert]::ToDecimal((Get-Date -UFormat "%s"))
    for ( $i = 0; $i -lt $reqs_sec; $i+=$num_services ) {

        # Simple AD Authentication (use RDP credentials)
        $name = $name_base + (Get-Random -Minimum 0 -Maximum 30000)
        if ((new-object directoryservices.directoryentry "",$name,$pass).psbase.name -eq $null) {

            # Make connection
            $connection = New-Object -TypeName System.Net.Sockets.TcpClient("192.168.224.7", 514)
            $stream = $connection.GetStream()
            $writer = New-Object System.IO.StreamWriter($stream)
            $writer.AutoFlush = $true
            
            # Send Message
            while (!$connection.Connected -and !$stream.CanWrite()) {}
            $writer.WriteLine("SERVICE_FAILURE") | Out-Null
            start-sleep -Milliseconds 500
            
            $writer.Close()
            $connection.Close()
            Exit
        }
            
        # Remote Desktop
        if ($rdp) {
            Write-Host "Initiating RDP Connection to: $rdp_host"
            Connect-Mstsc -CN $rdp_host -U $name -P $pass
        }

        # Network Share (Connect, write 100 random bytes, delete file, disconnect)
        if ($net_use) {
            Write-Host "Initiating Net Share Access on: $net_use_host"
            
            New-PSDrive -Name Shared -PSProvider FileSystem -Root $net_use_host
            
            for ($i=0;$i -lt 100;$i++) {
                $text += Get-Random -InputObject (48..90) | %{[char]$_}
            }

            $text > 'Shared:\file.txt'
            Remove-Item 'Shared:\file.txt'
            Remove-PSDrive Shared
           
        }

        # Web Requests
        if ($web_req) {
            $rand = (Get-Random -Minimum 0 -Maximum 100) % $urls.Count
            $url = $urls[$rand]
            Write-Host "Initiating WebRequest to: $url, from: $client"
            
            $user_agent = "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 7.0; InfoPath.3; .NET CLR 3.1.40767; Trident/6.0; en-IN)"
            $r = Invoke-WebRequest -Uri $url -UserAgent $user_agent
            if ($r.StatusCode -notcontains "200") {
                Write-Warning "Warning:  Recieved status code '$r.StatusCode' on request to $url"
            }

            # Simulate browsing
            $rand = (Get-Random -Minimum 0 -Maximum $r.Links.Count)
            $r2 = Invoke-WebRequest -Uri $r.Links[$rand].href -UserAgent $user_agent
            if ($r2.StatusCode -notcontains "200") {
                Write-Warning "Warning:  Recieved status code '$r.StatusCode' on request to $url"
            }
        }
    }

    $current_time = [convert]::ToDecimal((Get-Date -UFormat "%s"))
    $diff_time = $current_time - $start_time 
    if ( $diff_time -lt 1.0 ) {
        $diff_time /= 1000
        [math]::floor($diff_time)
        Start-Sleep -Milliseconds $diff_time
    }
} while ( $current_time -lt $end_time ) 







