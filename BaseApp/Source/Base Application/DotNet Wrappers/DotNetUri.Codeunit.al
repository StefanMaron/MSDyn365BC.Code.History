codeunit 3024 DotNet_Uri
{

    trigger OnRun()
    begin
    end;

    var
        DotNetUri: DotNet Uri;

    procedure Init(Url: Text)
    begin
        DotNetUri := DotNetUri.Uri(Url);
    end;

    procedure AbsoluteUri(): Text
    begin
        exit(DotNetUri.AbsoluteUri)
    end;

    procedure EscapeDataString(Text: Text): Text
    begin
        exit(DotNetUri.EscapeDataString(Text));
    end;

    procedure UnescapeDataString(Text: Text): Text
    begin
        exit(DotNetUri.UnescapeDataString(Text));
    end;

    procedure Scheme(): Text
    begin
        exit(DotNetUri.Scheme);
    end;

    procedure Segments(var DotNet_Array: Codeunit DotNet_Array)
    begin
        DotNet_Array.SetArray(DotNetUri.Segments);
    end;

    [Scope('OnPrem')]
    procedure GetUri(var DotNetUri2: DotNet Uri)
    begin
        DotNetUri2 := DotNetUri;
    end;

    [Scope('OnPrem')]
    procedure SetUri(DotNetUri2: DotNet Uri)
    begin
        DotNetUri := DotNetUri2;
    end;
}

