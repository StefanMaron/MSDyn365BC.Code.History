codeunit 9065 "Check Service Document"
{
    TableNo = "Service Header";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    local procedure RunCheck(var ServiceHeader: Record "Service Header")
    var
        TempServLine: Record "Service Line" temporary;
        ServicePost: Codeunit "Service-Post";
    begin
        ServicePost.CheckServiceDocument(ServiceHeader, TempServLine);
    end;
}