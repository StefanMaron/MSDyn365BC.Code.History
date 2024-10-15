codeunit 10501 "Upgrade IRS 1099 Form Boxes"
{
    Permissions = TableData Vendor = rim,
                  TableData "Vendor Ledger Entry" = rim,
                  TableData "Purchase Header" = rim,
                  TableData "Gen. Journal Line" = rim,
                  TableData "Purch. Inv. Header" = rim,
                  TableData "Purch. Cr. Memo Hdr." = rim;

    trigger OnRun()
    var
        IRS1099Management: Codeunit "IRS 1099 Management";
    begin
        if not IRS1099Management.UpgradeNeeded then
            exit;

        UpdateIRS1099FormBoxes;
    end;

    var
        ConfirmIRS1099CodeUpdateQst: Label 'One or more entries have been posted with IRS 1099 code %1.\\Do you want to continue and update all the data associated with this vendor and the existing IRS 1099 code with the new code, %2?', Comment = '%1 - old code;%2 - new code';

    local procedure UpdateIRS1099FormBoxes()
    begin
        ShiftIRS1099('DIV-11');
        ShiftIRS1099('DIV-10');
        ShiftIRS1099('DIV-09');
        ShiftIRS1099('DIV-08');
        ShiftIRS1099('DIV-06');
        ShiftIRS1099('DIV-05');
        InsertIRS1099('DIV-05', 'Section 199A dividends', 10.0);
    end;

    local procedure ShiftIRS1099(IRSCode: Code[10])
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        if not IRS1099FormBox.Get(IRSCode) then
            exit;

        IRS1099FormBox.Rename(IncStr(IRSCode));
    end;

    local procedure InsertIRS1099(NewCode: Code[10]; NewDescription: Text[100]; NewMinimum: Decimal)
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.Init;
        IRS1099FormBox.Code := NewCode;
        IRS1099FormBox.Description := NewDescription;
        IRS1099FormBox."Minimum Reportable" := NewMinimum;
        IRS1099FormBox.Insert;
    end;

    [Scope('OnPrem')]
    procedure UpdateIRSCodeInPostedData(VendNo: Code[20]; ExistingCode: Code[10]; NewCode: Code[10])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GenJournalLineAccount: Record "Gen. Journal Line";
        GenJournalLineBalAccount: Record "Gen. Journal Line";
        Confirmed: Boolean;
    begin
        if ExistingCode = '' then
            exit;

        if ExistingCode <> NewCode then begin
            VendorLedgerEntry.SetRange("Vendor No.", VendNo);
            VendorLedgerEntry.SetRange("IRS 1099 Code", ExistingCode);
            PurchaseHeader.SetRange("Pay-to Vendor No.", VendNo);
            PurchaseHeader.SetRange("IRS 1099 Code", ExistingCode);
            PurchInvHeader.SetRange("Pay-to Vendor No.", VendNo);
            PurchInvHeader.SetRange("IRS 1099 Code", ExistingCode);
            PurchCrMemoHdr.SetRange("Pay-to Vendor No.", VendNo);
            PurchCrMemoHdr.SetRange("IRS 1099 Code", ExistingCode);
            GenJournalLineAccount.SetRange("Account Type", GenJournalLineAccount."Account Type"::Vendor);
            GenJournalLineAccount.SetRange("Account No.", VendNo);
            GenJournalLineAccount.SetRange("IRS 1099 Code", ExistingCode);
            GenJournalLineBalAccount.SetRange("Bal. Account Type", GenJournalLineAccount."Bal. Account Type"::Vendor);
            GenJournalLineBalAccount.SetRange("Bal. Account No.", VendNo);
            GenJournalLineBalAccount.SetRange("IRS 1099 Code", ExistingCode);
            if VendorLedgerEntry.IsEmpty and PurchaseHeader.IsEmpty and PurchInvHeader.IsEmpty and
               PurchCrMemoHdr.IsEmpty and GenJournalLineAccount.IsEmpty and GenJournalLineBalAccount.IsEmpty
            then
                exit;
            if GuiAllowed then
                Confirmed := Confirm(StrSubstNo(ConfirmIRS1099CodeUpdateQst, ExistingCode, NewCode))
            else
                Confirmed := true;
            if not Confirmed then
                exit;
            VendorLedgerEntry.ModifyAll("IRS 1099 Code", NewCode);
            PurchaseHeader.ModifyAll("IRS 1099 Code", NewCode);
            PurchInvHeader.ModifyAll("IRS 1099 Code", NewCode);
            PurchCrMemoHdr.ModifyAll("IRS 1099 Code", NewCode);
            GenJournalLineAccount.ModifyAll("IRS 1099 Code", NewCode);
            GenJournalLineBalAccount.ModifyAll("IRS 1099 Code", NewCode);
        end;
    end;
}

