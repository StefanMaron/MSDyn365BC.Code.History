codeunit 3012 DotNet_ImageFormat
{

    trigger OnRun()
    begin
    end;

    var
        DotNetImageFormat: DotNet ImageFormat;

    procedure Bmp()
    begin
        DotNetImageFormat := DotNetImageFormat.Bmp;
    end;

    procedure Emf()
    begin
        DotNetImageFormat := DotNetImageFormat.Emf;
    end;

    procedure Exif()
    begin
        DotNetImageFormat := DotNetImageFormat.Exif;
    end;

    procedure Gif()
    begin
        DotNetImageFormat := DotNetImageFormat.Gif;
    end;

    procedure Icon()
    begin
        DotNetImageFormat := DotNetImageFormat.Icon;
    end;

    procedure Jpeg()
    begin
        DotNetImageFormat := DotNetImageFormat.Jpeg;
    end;

    procedure Png()
    begin
        DotNetImageFormat := DotNetImageFormat.Png;
    end;

    procedure Tiff()
    begin
        DotNetImageFormat := DotNetImageFormat.Tiff;
    end;

    procedure Wmf()
    begin
        DotNetImageFormat := DotNetImageFormat.Wmf;
    end;

    [Scope('OnPrem')]
    procedure GetImageFormat(var DotNetImageFormat2: DotNet ImageFormat)
    begin
        DotNetImageFormat2 := DotNetImageFormat
    end;

    [Scope('OnPrem')]
    procedure SetImageFormat(DotNetImageFormat2: DotNet ImageFormat)
    begin
        DotNetImageFormat := DotNetImageFormat2
    end;
}

