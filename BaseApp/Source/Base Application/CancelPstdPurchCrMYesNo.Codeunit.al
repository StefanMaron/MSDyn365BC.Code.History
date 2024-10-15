codeunit 1401 "Cancel PstdPurchCrM (Yes/No)"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Purch. Cr. Memo Hdr.";

    trigger OnRun()
    begin
        CancelCrMemo(Rec);
    end;

    var
        CancelPostedCrMemoQst: Label 'The posted purchase credit memo will be canceled, and a purchase invoice will be created and posted, which reverses the posted purchase credit memo. Do you want to continue?';
        OpenPostedInvQst: Label 'The invoice was successfully created. Do you want to open the posted invoice?';

    local procedure CancelCrMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."): Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        CancelledDocument: Record "Cancelled Document";
        CancelPostedPurchCrMemo: Codeunit "Cancel Posted Purch. Cr. Memo";
    begin
        CancelPostedPurchCrMemo.TestCorrectCrMemoIsAllowed(PurchCrMemoHdr);
        if Confirm(CancelPostedCrMemoQst) then
            if CancelPostedPurchCrMemo.CancelPostedCrMemo(PurchCrMemoHdr) then
                if Confirm(OpenPostedInvQst) then begin
                    CancelledDocument.FindPurchCancelledCrMemo(PurchCrMemoHdr."No.");
                    PurchInvHeader.Get(CancelledDocument."Cancelled By Doc. No.");
                    PAGE.Run(PAGE::"Posted Purchase Invoice", PurchInvHeader);
                    exit(true);
                end;

        exit(false);
    end;
}

