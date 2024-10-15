codeunit 1405 "Purch. Inv. Header - Edit"
{
    Permissions = TableData "Purch. Inv. Header" = rm;
    TableNo = "Purch. Inv. Header";

    trigger OnRun()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader := Rec;
        PurchInvHeader.LockTable;
        PurchInvHeader.Find;
        PurchInvHeader."Payment Reference" := "Payment Reference";
        PurchInvHeader."Creditor No." := "Creditor No.";
        PurchInvHeader."Ship-to Code" := "Ship-to Code";
        PurchInvHeader."Special Scheme Code" := "Special Scheme Code";
        PurchInvHeader."Invoice Type" := "Invoice Type";
        PurchInvHeader."ID Type" := "ID Type";
        PurchInvHeader."Succeeded Company Name" := "Succeeded Company Name";
        PurchInvHeader."Succeeded VAT Registration No." := "Succeeded VAT Registration No.";
        PurchInvHeader.TestField("No.", "No.");
        PurchInvHeader.Modify;
        Rec := PurchInvHeader;
    end;
}

