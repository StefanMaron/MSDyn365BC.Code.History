codeunit 9069 "Check Sales Document Line"
{
    TableNo = "Sales Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        SalesHeader: Record "Sales Header";

    procedure SetSalesHeader(NewSalesHeader: Record "Sales Header")
    begin
        SalesHeader := NewSalesHeader;
    end;

    local procedure RunCheck(var SalesLine: Record "Sales Line")
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesPost.TestSalesLine(SalesHeader, SalesLine);
    end;
}