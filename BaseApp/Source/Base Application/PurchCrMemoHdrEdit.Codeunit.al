codeunit 10767 "Purch. Cr. Memo Hdr. - Edit"
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
        PurchCrMemoHdr."Special Scheme Code" := "Special Scheme Code";
        PurchCrMemoHdr."Cr. Memo Type" := "Cr. Memo Type";
        PurchCrMemoHdr."Correction Type" := "Correction Type";
        PurchCrMemoHdr.TestField("No.", "No.");
        PurchCrMemoHdr.Modify;
        Rec := PurchCrMemoHdr;
    end;
}

