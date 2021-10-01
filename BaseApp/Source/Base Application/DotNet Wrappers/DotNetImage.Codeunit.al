#if not CLEAN19
codeunit 3010 DotNet_Image
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit is obsolete. Use the Image codeunit in the Image Module instead.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    begin
    end;

    var
        DotNetImage: DotNet Image;

    procedure FromStream(InStream: InStream)
    begin
        DotNetImage := DotNetImage.FromStream(InStream)
    end;

    [Obsolete('Provide format in Save() function instead', '19.0')]
    procedure RawFormat(var DotNet_ImageFormat: Codeunit DotNet_ImageFormat)
    begin
        DotNet_ImageFormat.SetImageFormat(DotNetImage.RawFormat)
    end;

    procedure FromBitmap(Width: Integer; Height: Integer)
    var
        DotNetBitmap: DotNet Bitmap;
    begin
        DotNetImage := DotNetBitmap.Bitmap(DotNetImage, Width, Height);
    end;

    [Obsolete('Codeunit has been replaced by enum in the Image module', '19.0')]
    procedure Save(var OutStream: OutStream; DotNet_ImageFormat: Codeunit DotNet_ImageFormat)
    var
        DotNetImageFormat: DotNet ImageFormat;
    begin
        DotNet_ImageFormat.GetImageFormat(DotNetImageFormat);
        DotNetImage.Save(OutStream, DotNetImageFormat);
    end;

    procedure GetWidth(): Integer
    begin
        exit(DotNetImage.Width);
    end;

    procedure GetHeight(): Integer
    begin
        exit(DotNetImage.Height);
    end;

    [Obsolete('Removed as we do not need to handle memory allocation in the new module.', '19.0')]
    procedure Dispose()
    begin
        DotNetImage.Dispose;
    end;

    [Obsolete('Removed as we only support streams', '19.0')]
    [Scope('OnPrem')]
    procedure GetImage(var DotNetImage2: DotNet Image)
    begin
        DotNetImage2 := DotNetImage
    end;

    [Obsolete('Removed as we only support streams', '19.0')]
    [Scope('OnPrem')]
    procedure SetImage(DotNetImage2: DotNet Image)
    begin
        DotNetImage := DotNetImage2
    end;
}
#endif