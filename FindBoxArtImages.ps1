
<#
    Just a tool I use to assist in copying boxart images to Retroarch
    I am not a professional but it works for me.

    The Directory names MUST be equal in the Playlist directory and Thumbnail
    directory. If you save a log file, if there are missed ROMs, the log file 
    will state which ones were not found.  Just have to copy the PNGs missing and 
    rename the PNG file to the Label listed in the log file, after the colon ( : ),
    for it to work. Just run the script again to pick up the missing ones,or do it 
    by hand. 
#>

$filelog = $false

Add-Type -AssemblyName PresentationCore,PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

$ButtonType = [System.Windows.MessageBoxButton]::YesNo
$MessageIcon = [System.Windows.MessageBoxImage]::Question
$MessageBody = "Save a log file?"
$MessageTitle = "Save a Log File?"
$Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)

if($Result -eq "Yes")
{
    $filelog = $true
}

do
{
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowser.Description = "Select Retroarch Playlists Directory"
    $result = $FolderBrowser.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
    if( Get-ChildItem $FolderBrowser.SelectedPath -Filter *.lpl)
    {
        $PlaylistsDirectory = $FolderBrowser.SelectedPath
    }
    else
    {
        $PlaylistsDirectory = ""
        $ButtonType = [System.Windows.MessageBoxButton]::YesNo
        $MessageIcon = [System.Windows.MessageBoxImage]::Error
        $MessageBody = "No Playlists found. Try Again?"
        $MessageTitle = "Playlist Error"
        $Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
        if($Result -eq "No")
        {
            Exit
        }
    }

}while($PlaylistsDirectory -eq "")

do
{
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowser.Description = "Select Boxart Directory"
    $result = $FolderBrowser.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
    if( Get-ChildItem $FolderBrowser.SelectedPath -Filter *.png -Recurse -Depth 2)
    {
        $BoxartDirectory = $FolderBrowser.SelectedPath
    }
    else
    {
        $BoxartDirectory = ""
        $ButtonType = [System.Windows.MessageBoxButton]::YesNo
        $MessageIcon = [System.Windows.MessageBoxImage]::Error
        $MessageBody = "Boxart PNG Files NOT found. Try Again?"
        $MessageTitle = "Playlist Error"
        $Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
        if($Result -eq "No")
        {
            Exit
        }
    }

}while($BoxartDirectory -eq "")

if($BoxartDirectory[$BoxartDirectory.Length - 1] -ne "\")
{
    $BoxartDirectory += "\"
}

if($PlaylistsDirectory[$PlaylistsDirectory.Length - 1] -ne "\")
{
    $PlaylistsDirectory += "\"
}

$output = @()
$copied = @()
$missed = @()

foreach($file in (gci -Path $PlaylistsDirectory *.lpl))
{
    $json = gc $file.FullName | ConvertFrom-Json


    foreach($thing in $json.items)
    {
        $str = $thing.label
        $path = $BoxartDirectory
        $path += $file.BaseName
        $found = gci $path -Recurse | where -Property BaseName -EQ $thing.label
        if($found.FullName)
        {
            
            $targetdir = ($PlaylistsDirectory -split "playlists")[0]
            if($targetdir[ $targetdir.Length - 1] -ne "\")
            {
                $targetdir += "\"
            }
            $targetdir += "thumbnails\"
            $targetdir += $file.BaseName 
            $targetdir += "\Named_Boxarts\"
             
            if( (Test-Path $targetdir) -eq $false)
            {
                #Write-Host "Copying: " $found.FullName "To: " $targetdir
                $message = "Copied: "
                $message += $found.FullName
                $message += " To: "
                $message += $targetdir
                $copied += $targetdir
                Copy-Item $found.FullName $targetdir
            }
        }
        else
        {
            $failed = "Failed: "
            $failed += $File.BaseName.ToString()
            $failed += " : "
            $failed += $thing.label.ToString()
            $missed += $failed
        }
    }

    
}

if($filelog)
{
    $count = $copied.Length + $missed.Length
    if($count -gt 0)
    {
        $output = $copied
        foreach($label in $missed)
        {
            $output += $label
        }

        $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $SaveFileDialog.InitialDirectory = pwd
        $SaveFileDialog.Title = "Save Log File"
        $SaveFileDialog.FileName = "*.txt"
        $SaveFileDialog.ShowDialog() | Out-Null
    
        $output | Out-File -FilePath $SaveFileDialog.FileName 
    }
    else
    {
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageIcon = [System.Windows.MessageBoxImage]::Information
        $MessageBody = "No Changes or Missed ROMs. Skipping log file"
        $MessageTitle = "Complete"
        $Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
    }
}
else
{
    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageIcon = [System.Windows.MessageBoxImage]::Information
    $MessageBody = "Number of files copied: "
    $MessageBody += $copied.Length.ToString()
    $MessageBody += "`nNumber of missed files: "
    $MessageBody += $missed.Length.ToString()
    $MessageTitle = "Complete"
    $Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
}