codeunit 3010 DotNet_Image
{

    trigger OnRun()
    begin
    end;

    var
        DotNetImage: DotNet Image;

    procedure FromStream(InStream: InStream)
    begin
        DotNetImage := DotNetImage.FromStream(InStream)
    end;

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

    procedure Dispose()
    begin
        DotNetImage.Dispose;
    end;

    [Scope('OnPrem')]
    procedure GetImage(var DotNetImage2: DotNet Image)
    begin
        DotNetImage2 := DotNetImage
    end;

    [Scope('OnPrem')]
    procedure SetImage(DotNetImage2: DotNet Image)
    begin
        DotNetImage := DotNetImage2
    end;
}

