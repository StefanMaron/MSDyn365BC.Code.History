codeunit 31053 "Release Credit Document"
{
    TableNo = "Credit Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Compensation Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    trigger OnRun()
    begin
        CreditHeader.Copy(Rec);
        Code;
        Rec := CreditHeader;
    end;

    var
        CreditHeader: Record "Credit Header";
        CreditsSetup: Record "Credits Setup";
        MustBeLessOrEqualErr: Label '%1 must be less or equal to %2.', Comment = '%1=Fieldcaption of Credit Balance (LCY);%2=Fieldcaption of Max. Rounding Amount';
        UseChangedLedgerEntryQst: Label '%1 %2 %3 is used on Issued Payment Order. Do you want to use it for Credit?', Comment = '%1=Tablecaption of Customer/Vendor Ledger Entry;%2=Fieldcaption of Entry No.;%3=Entry No.';
        CurrencyFactorErr: Label 'All lines with currency %1 must have the same currency factor.', Comment = '%1 = Currency Code';
        ApprovalProcessReleaseErr: Label 'This document can only be released when the approval process is complete.';
        ApprovalProcessReopenErr: Label 'The approval process must be cancelled or completed to reopen this document.';

    local procedure "Code"()
    begin
        with CreditHeader do begin
            if Status = Status::Released then
                exit;

            OnBeforeReleaseCreditDoc(CreditHeader);
            OnCheckCreditReleaseRestrictions;

            CheckCreditBalance(CreditHeader);
            CheckCreditLines(CreditHeader);

            TestField("Company No.");
            TestField("Posting Date");

            Status := Status::Released;
            Modify;

            OnAfterReleaseCreditDoc(CreditHeader);
        end;
    end;

    [Scope('OnPrem')]
    procedure Reopen(var CreditHeader: Record "Credit Header")
    begin
        OnBeforeReopenCreditDoc(CreditHeader);

        with CreditHeader do begin
            if Status = Status::Open then
                exit;
            Status := Status::Open;
            Modify(true);
        end;

        OnAfterReopenCreditDoc(CreditHeader);
    end;

    [Scope('OnPrem')]
    procedure PerformManualRelease(var CreditHeader: Record "Credit Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if ApprovalsMgmt.IsCreditApprovalsWorkflowEnabled(CreditHeader) and
           (CreditHeader.Status = CreditHeader.Status::Open)
        then
            Error(ApprovalProcessReleaseErr);

        CODEUNIT.Run(CODEUNIT::"Release Credit Document", CreditHeader);
    end;

    [Scope('OnPrem')]
    procedure PerformManualReopen(var CreditHeader: Record "Credit Header")
    begin
        if CreditHeader.Status = CreditHeader.Status::"Pending Approval" then
            Error(ApprovalProcessReopenErr);

        Reopen(CreditHeader);
    end;

    local procedure CheckCreditBalance(CreditHeader: Record "Credit Header")
    begin
        with CreditHeader do begin
            CreditsSetup.Get();
            CalcFields("Credit Balance (LCY)");
            if Abs("Credit Balance (LCY)") > CreditsSetup."Max. Rounding Amount" then
                Error(MustBeLessOrEqualErr, FieldCaption("Credit Balance (LCY)"), CreditsSetup.FieldCaption("Max. Rounding Amount"));
        end;
    end;

    local procedure CheckCreditLines(CreditHeader: Record "Credit Header")
    var
        CreditLine: Record "Credit Line";
        CreditLine2: Record "Credit Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CurrencyFactor: Decimal;
    begin
        with CreditLine do begin
            SetRange("Credit No.", CreditHeader."No.");
            if FindSet then
                repeat
                    CheckPostingDate;
                    case "Source Type" of
                        "Source Type"::Customer:
                            if "Source Entry No." <> 0 then begin
                                CustLedgEntry.Get("Source Entry No.");
                                CustLedgEntry.CalcFields("Amount on Payment Order (LCY)");
                                CustLedgEntry.TestField(Prepayment, false);
                                CustLedgEntry.TestField("Prepayment Type", CustLedgEntry."Prepayment Type"::" ");
                                if CustLedgEntry."Amount on Payment Order (LCY)" <> 0 then
                                    if not Confirm(UseChangedLedgerEntryQst, false,
                                         CustLedgEntry.TableCaption, CustLedgEntry.FieldCaption("Entry No."), CustLedgEntry."Entry No.")
                                    then
                                        CustLedgEntry.TestField("Amount on Payment Order (LCY)", 0);
                            end;
                        "Source Type"::Vendor:
                            if "Source Entry No." <> 0 then begin
                                VendLedgEntry.Get("Source Entry No.");
                                VendLedgEntry.CalcFields("Amount on Payment Order (LCY)");
                                VendLedgEntry.TestField(Prepayment, false);
                                VendLedgEntry.TestField("Prepayment Type", VendLedgEntry."Prepayment Type"::" ");
                                if VendLedgEntry."Amount on Payment Order (LCY)" <> 0 then
                                    if not Confirm(UseChangedLedgerEntryQst, false,
                                         VendLedgEntry.TableCaption, VendLedgEntry.FieldCaption("Entry No."), VendLedgEntry."Entry No.")
                                    then
                                        VendLedgEntry.TestField("Amount on Payment Order (LCY)", 0);
                            end;
                    end;
                until Next() = 0;

            SetFilter("Currency Code", '<>%1', '');
            if FindSet then
                repeat
                    CreditLine2.SetRange("Credit No.", CreditHeader."No.");
                    CreditLine2.SetRange("Currency Code", "Currency Code");
                    CreditLine2.FindSet();
                    CurrencyFactor := CreditLine2."Currency Factor";
                    while CreditLine2.Next <> 0 do
                        if CreditLine2."Currency Factor" <> CurrencyFactor then
                            Error(CurrencyFactorErr, CreditLine2."Currency Code");
                until Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseCreditDoc(var CreditHdr: Record "Credit Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseCreditDoc(var CreditHdr: Record "Credit Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenCreditDoc(var CreditHdr: Record "Credit Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenCreditDoc(var CreditHdr: Record "Credit Header")
    begin
    end;
}

