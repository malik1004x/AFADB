Add-Type -AssemblyName PresentationFramework

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    $name = [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function Check-AdminRights {
  return !([Security.Principal.WindowsPrincipal] `
  [Security.Principal.WindowsIdentity]::GetCurrent() `
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Add-ToPath {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $dir
    )

    $dir = (Resolve-Path $dir)
    if (!($current_path.Contains($dir))) {

        # append dir to path
        [Environment]::SetEnvironmentVariable("PATH", $current_path + ";$dir", $path_target)
        echo "Added $dir to PATH"
        return
    }
    echo "$dir is already in PATH"
}

function Show-EndMessage {
    $msg_body = "Installation Complete. Please restart any CMD or Terminal windows."
    $msg_icon = [System.Windows.MessageBoxImage]::Information
    $msg_buttons = [System.Windows.MessageBoxButton]::OK
    $msg_title = "Complete"
    $msg_result = [System.Windows.MessageBox]::Show($msg_body,$msg_title,$msg_buttons,$msg_icon)
}

#decides on installation directory and path variable to update.
#try restarting as admin if we don't have admin. on faliure it switches to installation in user dir.
if(Check-AdminRights == False) {
    echo "No admin rights granted. Installing in user directory instead."
    $install_dir = $env:USERPROFILE
    $current_path = [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
    $path_target = [EnvironmentVariableTarget]::User
} else {
    echo "Admin rights OK. Installing systemwide."
    $install_dir = "C:\"
    $current_path = [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
    $path_target = [EnvironmentVariableTarget]::Machine
}


$zip_download_name = "platformtools.zip"
$download_url = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
$webclient = New-Object Net.WebClient
$tmpdir = New-TemporaryDirectory
#this is the name of the directory inside the archive we get from google. only change this if the api gets changed.
$extracted_dirname = "platform-tools"
$finalpath = (Join-Path $install_dir $extracted_dirname)

#check if installation directory already exists. ask user if they wanna overwrite it.
if(Test-Path $finalpath) {

    $msg_body = "The installation path already exists. If it contains files of the same names, they will be overwritten. Continue?"
    $msg_icon = [System.Windows.MessageBoxImage]::Warning
    $msg_buttons = [System.Windows.MessageBoxButton]::YesNo
    $msg_title = "Overwrite warning"
    $msg_result = [System.Windows.MessageBox]::Show($msg_body,$msg_title,$msg_buttons,$msg_icon)
    
    if($msg_result -eq "No"){
        exit
    }  
 }

echo "Downloading from $download_url"
$webclient.DownloadFile("$download_url","$tmpdir\$zip_download_name")

$zip_path = Join-Path $tmpdir $zip_download_name

echo "Extracting $zip_path into $install_dir"
Expand-Archive -LiteralPath $zip_path -DestinationPath $install_dir -Force

echo "Adding installation directory to PATH variable"
Add-ToPath $finalpath

Show-EndMessage
