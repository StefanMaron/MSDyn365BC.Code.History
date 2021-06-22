codeunit 320 "PurchCrMemo-Printed"
{
    Permissions = TableData "Purch. Cr. Memo Hdr." = rimd;
    TableNo = "Purch. Cr. Memo Hdr.";

    trigger OnRun()
    begin
        Find;
        "No. Printed" := "No. Printed" + 1;
        OnBeforeModify(Rec);
        Modify;
        if not SuppressCommit then
            Commit;
    end;

    var
        SuppressCommit: Boolean;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;
}

