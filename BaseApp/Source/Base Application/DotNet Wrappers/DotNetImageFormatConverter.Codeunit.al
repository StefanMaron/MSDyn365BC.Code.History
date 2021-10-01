#if not CLEAN19
codeunit 3011 DotNet_ImageFormatConverter
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit is obsolete. Use the Image codeunit in the Image Module instead.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    begin
    end;

    var
        DotNetImageFormatConverter: DotNet ImageFormatConverter;

    procedure InitImageFormatConverter()
    begin
        DotNetImageFormatConverter := DotNetImageFormatConverter.ImageFormatConverter
    end;

    [Obsolete('Replaced by GetFormatAsString() in Image module', '19.0')]
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
#endif