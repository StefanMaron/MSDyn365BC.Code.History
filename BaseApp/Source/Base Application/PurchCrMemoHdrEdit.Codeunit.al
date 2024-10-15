codeunit 28066 "Purch. Cr. Memo Hdr. - Edit"
{
    Permissions = TableData "Purch. Cr. Memo Hdr." = rm;
    TableNo = "Purch. Cr. Memo Hdr.";

    trigger OnRun()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr := Rec;
        PurchCrMemoHdr.LockTable;
        PurchCrMemoHdr.Find;
        PurchCrMemoHdr."Adjustment Applies-to" := "Adjustment Applies-to";
        PurchCrMemoHdr."Reason Code" := "Reason Code";
        PurchCrMemoHdr.TestField("No.", "No.");
        PurchCrMemoHdr.Modify;
        Rec := PurchCrMemoHdr;
    end;
}

