codeunit 3056 DotNet_Capture
{

    trigger OnRun()
    begin
    end;

    var
        DotNetCapture: DotNet Capture;

    procedure Index(): Integer
    begin
        exit(DotNetCapture.Index);
    end;

    procedure Length(): Integer
    begin
        exit(DotNetCapture.Length);
    end;

    procedure Value(): Text
    begin
        exit(DotNetCapture.Value);
    end;

    procedure Equals(var DotNet_Capture: Codeunit DotNet_Capture): Boolean
    var
        DotNetCapture2: DotNet Capture;
    begin
        DotNet_Capture.GetCapture(DotNetCapture2);

        exit(DotNetCapture.Equals(DotNetCapture2));
    end;

    procedure GetHashCode(): Integer
    begin
        exit(DotNetCapture.GetHashCode());
    end;

    procedure IsDotNetNull(): Boolean
    begin
        exit(IsNull(DotNetCapture));
    end;

    [Scope('OnPrem')]
    procedure GetCapture(var DotNetCapture2: DotNet Capture)
    begin
        DotNetCapture2 := DotNetCapture;
    end;

    [Scope('OnPrem')]
    procedure SetCapture(var DotNetCapture2: DotNet Capture)
    begin
        DotNetCapture := DotNetCapture2;
    end;
}

