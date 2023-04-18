codeunit 4141 "Sales Manual Reopen"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        ReleaseSalesDocument.PerformManualReopen(Rec);
    end;
}