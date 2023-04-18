codeunit 4140 "Sales Manual Release"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        ReleaseSalesDocument.PerformManualRelease(Rec);
    end;
}