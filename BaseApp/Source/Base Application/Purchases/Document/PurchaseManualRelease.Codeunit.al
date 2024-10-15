namespace Microsoft.Purchases.Document;

codeunit 4142 "Purchase Manual Release"
{
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        ReleasePurchaseDocument.PerformManualRelease(Rec);
    end;
}