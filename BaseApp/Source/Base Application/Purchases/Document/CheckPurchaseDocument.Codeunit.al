namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Posting;

codeunit 9067 "Check Purchase Document"
{
    TableNo = "Purchase Header";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    local procedure RunCheck(var PurchaseHeader: Record "Purchase Header")
    var
        PurchPost: Codeunit "Purch.-Post";
    begin
        PurchPost.PrepareCheckDocument(PurchaseHeader);
        PurchPost.CheckPurchDocument(PurchaseHeader);
    end;
}