#Run Powershell ISE as admin
#Highlight line below and run selection, accept permissions to run
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

function CompareDirFiles
{
    param([string]$dir1, [string]$dir2)

    $filelist = 'A','B','C','D', 'E', 'F', 'G', 'H', 'I', 'J', 'K','L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T'
    foreach ($item in $filelist)
    {
        #"Comparing file: [$item]"
        #Compare-Object (Get-Content ($dir1 + $item)) (Get-Content ($dir2 + $item)) -SyncWindow 0

        if ((Get-FileHash ($dir1 + $item)).Hash -eq (Get-FileHash ($dir2 + $item)).Hash) {
            "[$item] match"
        }
        else {
            "[$item] do not match"
        }

        $l1 = (Get-Item ($dir2 + $item)).Length
        $l2 = (Get-Item ($dir2 + $item)).Length
        if ($l1 -ne $l2) {
            "ERROR. Length mismatch"
        }
    }

}

clear

$rootdir = $PSScriptRoot
$compdir1 = "caves"
$compdir2 = "output"
$subdir = 'BoulderDash01', 'BoulderDash02', 'BoulderDash03', 'BoulderDashP1', 'ArnoDash01'

foreach ($item in $subdir)
{
    "########## Comparing files for $item in folders $compdir1 vs $compdir2"
    CompareDirFiles "${rootdir}\${compdir1}\${item}\" "${rootdir}\${compdir2}\${item}\"
}
