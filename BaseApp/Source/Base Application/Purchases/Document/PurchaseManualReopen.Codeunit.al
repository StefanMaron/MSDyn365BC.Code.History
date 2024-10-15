namespace Microsoft.Purchases.Document;

codeunit 4144 "Purchase Manual Reopen"
{
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        ReleasePurchaseDocument.PerformManualReopen(Rec);
    end;
}