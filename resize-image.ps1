# Importing .NET libraries for image processing
Add-Type -AssemblyName System.Drawing

# Set the sourceFolder path to the current folder

$sourceFolder = "$($PSScriptRoot)\source"

$destinationFolder = "$($PSScriptRoot)\destination"

# Create destination folder if it doesn't exist
if (-not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder
}

# Set the target sizes
$targetWidth1 = 1920
$targetHeight1 = 1280
$targetWidth2 = 1280
$targetHeight2 = 1920

# Define the JPEG quality level
$jpegQuality = 40

# Function to calculate new size while maintaining aspect ratio
function Get-NewSize {
    param (
        [int]$originalWidth,
        [int]$originalHeight,
        [int]$targetWidth,
        [int]$targetHeight
    )

    $ratioX = $targetWidth / $originalWidth
    $ratioY = $targetHeight / $originalHeight
    $ratio = [Math]::Min($ratioX, $ratioY)

    return @{
        Width  = [int]($originalWidth * $ratio)
        Height = [int]($originalHeight * $ratio)
    }
}

# Function to resize and save image
function Resize-Image {
    param (
        [string]$filePath
    )

    # Load the image
    $img = [System.Drawing.Image]::FromFile($filePath)

    # Calculate new size for both orientations
    $newSize1 = Get-NewSize -originalWidth $img.Width -originalHeight $img.Height -targetWidth $targetWidth1 -targetHeight $targetHeight1
    $newSize2 = Get-NewSize -originalWidth $img.Width -originalHeight $img.Height -targetWidth $targetWidth2 -targetHeight $targetHeight2

    # Choose the best fit
    if (($newSize1.Width * $newSize1.Height) > ($newSize2.Width * $newSize2.Height)) {
        $newWidth = $newSize1.Width
        $newHeight = $newSize1.Height
    } else {
        $newWidth = $newSize2.Width
        $newHeight = $newSize2.Height
    }

    # Create new resized bitmap
    $resizedImage = New-Object System.Drawing.Bitmap($newWidth, $newHeight)

    # Create graphic object
    $graphics = [System.Drawing.Graphics]::FromImage($resizedImage)
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    # Draw the resized image
    $graphics.DrawImage($img, 0, 0, $newWidth, $newHeight)

    # Release resources
    $graphics.Dispose()

    # Set the output file path
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
    $outputPath = Join-Path $destinationFolder ("$fileName-resized.jpg")

    # Save the image with JPEG quality of 40%
    $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $jpegQuality)
    $resizedImage.Save($outputPath, $jpegCodec, $encoderParams)

    # Release resources
    $resizedImage.Dispose()
    $img.Dispose()
}

# Process each jpg image in the folder
Get-ChildItem -Path $sourceFolder -Include ('*.jpg', '*.jpeg') -Recurse | ForEach-Object {
    Resize-Image -filePath $_.FullName
}

Write-Host "Image resizing completed!"
