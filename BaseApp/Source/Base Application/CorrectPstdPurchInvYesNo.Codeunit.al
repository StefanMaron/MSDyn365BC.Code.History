codeunit 1324 "Correct PstdPurchInv (Yes/No)"
{
    Permissions = TableData "Purch. Inv. Header" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm;
    TableNo = "Purch. Inv. Header";

    trigger OnRun()
    begin
        CorrectInvoice(Rec);
    end;

    var
        CorrectPostedInvoiceQst: Label 'The posted purchase invoice will be canceled, and a new version of the purchase invoice will be created so that you can make the correction.\ \Do you want to continue?';

    procedure CorrectInvoice(var PurchInvHeader: Record "Purch. Inv. Header"): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);
        if Confirm(CorrectPostedInvoiceQst) then begin
            CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeader);
            PAGE.Run(PAGE::"Purchase Invoice", PurchaseHeader);
            exit(true);
        end;

        exit(false);
    end;
}

