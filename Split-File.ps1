<#
.Synopsis
    Split a file in smaller files.

. Description
    Given a particular file or path, it will check the size and split in
    files with the name <prefix>.<number>.part, where <prefix> is the
    file name, <number> is the number of the chunk, padded by 0.

. Example
    TODO

#>
function Split-File()
{
    [CmdletBinding()]
    param (
        [parameter (Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Path,
        [int[]]$Chunks = $null,
        [switch]$GetChunkQuantity,
        [int]$chunkSize = 31457280,
        [switch]$WhatIf
    )
    
    BEGIN {}
    PROCESS
    {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($Path);
        $directory = [System.IO.Path]::GetDirectoryName($Path);
        $extension = [System.IO.Path]::GetExtension($Path);

        $file = New-Object System.IO.FileInfo($Path);
        $reader = $null;
        $totalChunks = [int]($file.Length / $chunkSize) + 1;
        $digitCount = [int][System.Math]::Log10($totalChunks) + 1;
        $previous_chunk = -1;
        $buffer = New-Object Byte[] $chunkSize;

        if ($GetChunkQuantity) { return $totalChunks; }

        if ($Chunks -eq $null) { $Chunks = (0..($totalChunks - 1)); }
        
        $reader = [System.IO.File]::OpenRead($Path);
        foreach ($chunk in $Chunks)
        {
            $chunkFileName = "$directory\$fileName$extension.{0:D$digitCount}.part";
            $chunkFileName = $chunkFileName -f $chunk;
            if (-Not $WhatIf)
            {
                if ($previous_chunk + 1 -ne $chunk) { $reader.Seek($chunk * $chunkSize, [System.IO.SeekOrigin]::Begin) | Out-Null; }
                $bytesRead = $reader.Read($buffer, 0, $buffer.Length);
                $output = $buffer;
                if ($bytesRead -ne $buffer.Length)
                {
                    $output = New-Object Byte[] $bytesRead;
                    [System.Array]::Copy($buffer, $output, $bytesRead);
                }
                [System.IO.File]::WriteAllBytes($chunkFileName, $output);
            }
            $previous_chunk = $chunk;
            Write-Output $chunkFileName;
        }
        $reader.Close();
    }
    END {}
}
