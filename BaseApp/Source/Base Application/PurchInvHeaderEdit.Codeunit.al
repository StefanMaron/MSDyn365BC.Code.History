codeunit 1405 "Purch. Inv. Header - Edit"
{
    Permissions = TableData "Purch. Inv. Header" = rm;
    TableNo = "Purch. Inv. Header";

    trigger OnRun()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader := Rec;
        PurchInvHeader.LockTable();
        PurchInvHeader.Find;
        PurchInvHeader."Payment Reference" := "Payment Reference";
        PurchInvHeader."Creditor No." := "Creditor No.";
        PurchInvHeader."Ship-to Code" := "Ship-to Code";
        OnBeforePurchInvHeaderModify(PurchInvHeader, Rec);
        PurchInvHeader.TestField("No.", "No.");
        PurchInvHeader.Modify();
        Rec := PurchInvHeader;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvHeaderModify(var PurchInvHeader: Record "Purch. Inv. Header"; PurchInvHeaderRec: Record "Purch. Inv. Header")
    begin
    end;
}

