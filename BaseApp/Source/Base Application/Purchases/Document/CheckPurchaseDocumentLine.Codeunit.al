namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Posting;

codeunit 9066 "Check Purchase Document Line"
{
    TableNo = "Purchase Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        PurchaseHeader: Record "Purchase Header";

    procedure SetPurchaseHeader(NewPurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader := NewPurchaseHeader;
    end;

    local procedure RunCheck(var PurchaseLine: Record "Purchase Line")
    var
        PurchPost: Codeunit "Purch.-Post";
    begin
        PurchPost.TestPurchLine(PurchaseHeader, PurchaseLine);
    end;
}