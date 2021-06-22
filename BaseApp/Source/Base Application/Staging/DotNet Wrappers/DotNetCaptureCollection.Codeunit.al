codeunit 3057 DotNet_CaptureCollection
{

    trigger OnRun()
    begin
    end;

    var
        DotNetCaptureCollection: DotNet CaptureCollection;

    procedure "Count"(): Integer
    begin
        exit(DotNetCaptureCollection.Count);
    end;

    procedure IsReadOnly(): Boolean
    begin
        exit(DotNetCaptureCollection.IsReadOnly);
    end;

    procedure Item(CaptureNumber: Integer; var DotNet_Capture: Codeunit DotNet_Capture)
    var
        DotNetCapture: DotNet Capture;
    begin
        DotNetCapture := DotNetCaptureCollection.Item(CaptureNumber);
        DotNet_Capture.SetCapture(DotNetCapture);
    end;

    procedure CopyTo(var DotNet_Array: Codeunit DotNet_Array; Index: Integer)
    var
        DotNetArray: DotNet Array;
    begin
        DotNetCaptureCollection.CopyTo(DotNetArray, Index);
        DotNet_Array.SetArray(DotNetArray);
    end;

    procedure Equals(var DotNet_CaptureCollection: Codeunit DotNet_CaptureCollection): Boolean
    var
        DotNetCaptures: DotNet CaptureCollection;
    begin
        DotNet_CaptureCollection.GetCaptureCollection(DotNetCaptures);
        exit(DotNetCaptureCollection.Equals(DotNetCaptures));
    end;

    procedure GetHashCode(): Integer
    begin
        exit(DotNetCaptureCollection.GetHashCode());
    end;

    procedure IsDotNetNull(): Boolean
    begin
        exit(IsNull(DotNetCaptureCollection));
    end;

    [Scope('OnPrem')]
    procedure GetCaptureCollection(var DotNetCaptureCollection2: DotNet CaptureCollection)
    begin
        DotNetCaptureCollection2 := DotNetCaptureCollection;
    end;

    [Scope('OnPrem')]
    procedure SetCaptureCollection(var DotNetCaptureCollection2: DotNet CaptureCollection)
    begin
        DotNetCaptureCollection := DotNetCaptureCollection2;
    end;
}

