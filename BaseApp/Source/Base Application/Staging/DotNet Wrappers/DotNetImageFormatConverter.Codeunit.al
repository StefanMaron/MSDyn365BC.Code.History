codeunit 3011 DotNet_ImageFormatConverter
{

    trigger OnRun()
    begin
    end;

    var
        DotNetImageFormatConverter: DotNet ImageFormatConverter;

    procedure InitImageFormatConverter()
    begin
        DotNetImageFormatConverter := DotNetImageFormatConverter.ImageFormatConverter
    end;

    procedure ConvertToString(var DotNet_ImageFormat: Codeunit DotNet_ImageFormat): Text
    var
        DotNetImageFormat: DotNet ImageFormat;
    begin
        DotNet_ImageFormat.GetImageFormat(DotNetImageFormat);
        exit(DotNetImageFormatConverter.ConvertToString(DotNetImageFormat))
    end;

    [Scope('OnPrem')]
    procedure GetImageFormatConverter(var DotNetImageFormatConverter2: DotNet ImageFormatConverter)
    begin
        DotNetImageFormatConverter2 := DotNetImageFormatConverter
    end;

    [Scope('OnPrem')]
    procedure SetImageFormatConverter(DotNetImageFormatConverter2: DotNet ImageFormatConverter)
    begin
        DotNetImageFormatConverter := DotNetImageFormatConverter2
    end;
}

