codeunit 9071 "Check Sales Document"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    local procedure RunCheck(var SalesHeader: Record "Sales Header")
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesPost.PrepareCheckDocument(SalesHeader);
        SalesPost.CheckSalesDocument(SalesHeader);
    end;
}