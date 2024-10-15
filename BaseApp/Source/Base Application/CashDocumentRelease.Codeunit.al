codeunit 11731 "Cash Document-Release"
{
    TableNo = "Cash Document Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLineCheck: Codeunit "Gen. Jnl.-Check Line";
    begin
        if Status = Status::Released then
            exit;

        OnBeforeReleaseCashDoc(Rec);
        OnCheckCashDocReleaseRestrictions;

        CheckCashDocument(Rec);

        CashDocLine.Reset();
        CashDocLine.SetRange("Cash Desk No.", "Cash Desk No.");
        CashDocLine.SetRange("Cash Document No.", "No.");
        CashDocLine.FindSet;
        repeat
            if CashDocLine."Account Type" <> CashDocLine."Account Type"::" " then begin
                CashDocLine.TestField("Account No.");
                CashDocLine.TestField(Amount);
                if CashDocLine."Gen. Posting Type" <> CashDocLine."Gen. Posting Type"::" " then
                    VATPostingSetup.Get(CashDocLine."VAT Bus. Posting Group", CashDocLine."VAT Prod. Posting Group");
                SetOnHold(CashDocLine);
                CashDocumentPost.InitGenJnlLine(Rec, CashDocLine);
                CashDocumentPost.GetGenJnlLine(GenJnlLine);
                GenJnlLineCheck.RunCheck(GenJnlLine);
            end;
        until CashDocLine.Next = 0;

        CashDocHeader.Get("Cash Desk No.", "No.");
        CashDocHeader.Status := Status::Released;
        CashDocHeader."Released ID" := UserId;
        CashDocHeader.CalcFields("Amount Including VAT");
        CashDocHeader."Released Amount" := CashDocHeader."Amount Including VAT";
        CashDocHeader.Modify();
        Rec := CashDocHeader;

        OnAfterReleaseCashDoc(Rec);
    end;

    var
        CashDocHeader: Record "Cash Document Header";
        CashDocLine: Record "Cash Document Line";
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        CashDocumentPost: Codeunit "Cash Document-Post";
        CashDeskMgt: Codeunit CashDeskManagement;
        LinesNotExistsErr: Label 'There are no Cash Document Lines to release.';
        AmountExceededLimitErr: Label 'Cash Document Amount exceeded maximal limit %1.', Comment = '%1 = maximal limit';
        BalanceGreaterThanErr: Label 'Balance will be greater than %1 after release.', Comment = '%1 = fieldcaption';
        BalanceLowerThanErr: Label 'Balance will be lower than %1 after release.', Comment = '%1 = fieldcaption';
        BalanceGreaterThanQst: Label 'Balance will be greater than %1 after release.\\Do you want to continue?', Comment = '%1 = fieldcaption';
        BalanceLowerThanQst: Label 'Balance will be lower than %1 after release.\\Do you want to continue?', Comment = '%1 = fieldcaption';
        EmptyFieldQst: Label '%1 or %2 is empty.\\Do you want to continue?', Comment = '%1 = fieldcaption, %2 = fieldcaption';
        ApprovalProcessReleaseErr: Label 'This document can only be released when the approval process is complete.';
        ApprovalProcessReopenErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        EETDocReleaseDeniedErr: Label 'Cash document containing EET line cannot be released only.';
        MustBePositiveErr: Label 'must be positive';
        CashPaymentLimitErr: Label 'The maximum daily limit of cash payments of %1 was exceeded for the partner %2.', Comment = '%1 = amount of limit of cash payment; %2 = number of partner';

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure Reopen(var CashDocHeader: Record "Cash Document Header")
    begin
        OnBeforeReopenCashDoc(CashDocHeader);

        with CashDocHeader do begin
            if Status = Status::Open then
                exit;
            Status := Status::Open;
            Modify(true);
        end;

        OnAfterReopenCashDoc(CashDocHeader);
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure PerformManualRelease(var CashDocHeader: Record "Cash Document Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if ApprovalsMgmt.IsCashDocApprovalsWorkflowEnabled(CashDocHeader) and (CashDocHeader.Status = CashDocHeader.Status::Open) then
            Error(ApprovalProcessReleaseErr);

        if CashDocHeader.IsEETTransaction then
            Error(EETDocReleaseDeniedErr);

        CODEUNIT.Run(CODEUNIT::"Cash Document-Release", CashDocHeader);
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure PerformManualReopen(var CashDocHeader: Record "Cash Document Header")
    begin
        if CashDocHeader.Status = CashDocHeader.Status::"Pending Approval" then
            Error(ApprovalProcessReopenErr);

        CashDocHeader.TestField(Status, CashDocHeader.Status::Approved);
        Reopen(CashDocHeader);
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CheckCashDocument(CashDocHeader: Record "Cash Document Header")
    begin
        CheckCashDesk(CashDocHeader);
        CheckMandatoryFields(CashDocHeader);
        CheckCashDocumentAmount(CashDocHeader);
        CheckExceededBalanceLimit(CashDocHeader);
        CheckCashDocumentLines(CashDocHeader);
        CheckCashPaymentLimit(CashDocHeader);
    end;

    local procedure CheckCashDesk(CashDocHeader: Record "Cash Document Header")
    begin
        with CashDocHeader do begin
            GetBankAccount("Cash Desk No.");
            BankAccount.TestField("Account Type", BankAccount."Account Type"::"Cash Desk");
            BankAccount.TestField("Bank Acc. Posting Group");
            BankAccount.TestField(Blocked, false);
            if Status <> Status::Released then
                CashDeskMgt.CheckUserRights("Cash Desk No.", 2, IsEETTransaction);
        end;
    end;

    local procedure CheckCashDocumentAmount(CashDocHeader: Record "Cash Document Header")
    begin
        with CashDocHeader do begin
            GetBankAccount("Cash Desk No.");
            CalcFields("Amount Including VAT");

            if "Amount Including VAT" < 0 then
                FieldError("Amount Including VAT", MustBePositiveErr);

            case "Cash Document Type" of
                "Cash Document Type"::Receipt:
                    if "Amount Including VAT" > BankAccount."Cash Receipt Limit" then
                        Error(AmountExceededLimitErr, BankAccount."Cash Receipt Limit");
                "Cash Document Type"::Withdrawal:
                    if "Amount Including VAT" > BankAccount."Cash Withdrawal Limit" then
                        Error(AmountExceededLimitErr, BankAccount."Cash Withdrawal Limit");
            end;
        end;
    end;

    local procedure CheckExceededBalanceLimit(CashDocHeader: Record "Cash Document Header")
    var
        CurrentBalance: Decimal;
    begin
        with CashDocHeader do begin
            GetBankAccount("Cash Desk No.");
            if (BankAccount."Max. Balance Checking" = BankAccount."Max. Balance Checking"::"No Checking") and
               (BankAccount."Min. Balance Checking" = BankAccount."Min. Balance Checking"::"No Checking")
            then
                exit;

            CalcFields("Amount Including VAT");
            case "Cash Document Type" of
                "Cash Document Type"::Receipt:
                    CurrentBalance := BankAccount.CalcBalance + "Amount Including VAT";
                "Cash Document Type"::Withdrawal:
                    CurrentBalance := BankAccount.CalcBalance - "Amount Including VAT";
            end;

            case BankAccount."Max. Balance Checking" of
                BankAccount."Max. Balance Checking"::Warning:
                    if "Cash Document Type" = "Cash Document Type"::Receipt then
                        if CurrentBalance > BankAccount."Max. Balance" then
                            if not Confirm(BalanceGreaterThanQst, false, BankAccount.FieldCaption("Max. Balance")) then
                                Error('');
                BankAccount."Max. Balance Checking"::Blocking:
                    if "Cash Document Type" = "Cash Document Type"::Receipt then
                        if CurrentBalance > BankAccount."Max. Balance" then
                            Error(BalanceGreaterThanErr, BankAccount.FieldCaption("Max. Balance"));
            end;

            case BankAccount."Min. Balance Checking" of
                BankAccount."Min. Balance Checking"::Warning:
                    if "Cash Document Type" = "Cash Document Type"::Withdrawal then
                        if CurrentBalance < BankAccount."Min. Balance" then
                            if not Confirm(BalanceLowerThanQst, false, BankAccount.FieldCaption("Min. Balance")) then
                                Error('');
                BankAccount."Min. Balance Checking"::Blocking:
                    if "Cash Document Type" = "Cash Document Type"::Withdrawal then
                        if CurrentBalance < BankAccount."Min. Balance" then
                            Error(BalanceLowerThanErr, BankAccount.FieldCaption("Min. Balance"));
            end;
        end;
    end;

    local procedure CheckMandatoryFields(CashDocHeader: Record "Cash Document Header")
    begin
        with CashDocHeader do begin
            TestField("No.");
            TestField("Posting Date");
            VATRounding;
            CalcFields("Amount Including VAT", "Amount Including VAT (LCY)");
            TestField("Amount Including VAT");
            TestField("Amount Including VAT (LCY)");
            TestField("Document Date");
            TestField("Payment Purpose");
            if "Currency Code" <> '' then
                TestField("Currency Factor");

            GetBankAccount("Cash Desk No.");
            case BankAccount."Payed To/By Checking" of
                BankAccount."Payed To/By Checking"::Warning:
                    case "Cash Document Type" of
                        "Cash Document Type"::Receipt:
                            if ("Received By" = '') or ("Received From" = '') then
                                if not Confirm(EmptyFieldQst, false, FieldCaption("Received By"), FieldCaption("Received From")) then
                                    Error('');
                        "Cash Document Type"::Withdrawal:
                            if ("Paid By" = '') or ("Paid To" = '') then
                                if not Confirm(EmptyFieldQst, false, FieldCaption("Paid By"), FieldCaption("Paid To")) then
                                    Error('');
                    end;
                BankAccount."Payed To/By Checking"::Blocking:
                    case "Cash Document Type" of
                        "Cash Document Type"::Receipt:
                            begin
                                TestField("Received By");
                                TestField("Received From");
                            end;
                        "Cash Document Type"::Withdrawal:
                            begin
                                TestField("Paid By");
                                TestField("Paid To");
                            end;
                    end;
            end;
        end;
    end;

    local procedure CheckCashDocumentLines(CashDocHeader: Record "Cash Document Header")
    var
        CashDocLine: Record "Cash Document Line";
    begin
        with CashDocHeader do begin
            CashDocLine.Reset();
            CashDocLine.SetRange("Cash Desk No.", "Cash Desk No.");
            CashDocLine.SetRange("Cash Document No.", "No.");
            CashDocLine.SetFilter("Account No.", '<>%1', '');
            if CashDocLine.IsEmpty then
                Error(LinesNotExistsErr);

            CashDocLine.SetRange("Account No.");
            CashDocLine.SetFilter(Amount, '<>%1', 0);
            if CashDocLine.IsEmpty then
                Error(LinesNotExistsErr);

            CashDocLine.SetFilter("Account Type", '<>%1', CashDocLine."Account Type"::" ");
            CashDocLine.SetRange(Amount, 0);
            if CashDocLine.FindFirst then
                CashDocLine.FieldError(Amount);
        end;
    end;

    local procedure CheckCashPaymentLimit(CashDocHeader: Record "Cash Document Header")
    var
        CashDocHeader2: Record "Cash Document Header";
        GLSetup: Record "General Ledger Setup";
        PostedCashDocHeader: Record "Posted Cash Document Header";
        CashPaymentTotal: Decimal;
    begin
        GLSetup.Get();
        if GLSetup."Cash Payment Limit (LCY)" = 0 then
            exit;

        with CashDocHeader do begin
            if not ("Partner Type" in ["Partner Type"::Customer, "Partner Type"::Vendor]) then
                exit;

            PostedCashDocHeader.SetRange("Partner Type", "Partner Type");
            PostedCashDocHeader.SetRange("Partner No.", "Partner No.");
            PostedCashDocHeader.SetRange("Posting Date", "Posting Date");
            if PostedCashDocHeader.FindSet then
                repeat
                    PostedCashDocHeader.CalcFields("Amount Including VAT (LCY)");
                    if PostedCashDocHeader."Cash Document Type" = PostedCashDocHeader."Cash Document Type"::Withdrawal then
                        CashPaymentTotal -= PostedCashDocHeader."Amount Including VAT (LCY)"
                    else
                        CashPaymentTotal += PostedCashDocHeader."Amount Including VAT (LCY)";
                until PostedCashDocHeader.Next = 0;

            CashDocHeader2.SetRange("Partner Type", "Partner Type");
            CashDocHeader2.SetRange("Partner No.", "Partner No.");
            CashDocHeader2.SetRange("Posting Date", "Posting Date");
            if CashDocHeader2.FindSet then
                repeat
                    CashDocHeader2.CalcFields("Amount Including VAT (LCY)");
                    if CashDocHeader2."Cash Document Type" = CashDocHeader2."Cash Document Type"::Withdrawal then
                        CashPaymentTotal -= CashDocHeader2."Amount Including VAT (LCY)"
                    else
                        CashPaymentTotal += CashDocHeader2."Amount Including VAT (LCY)";
                until CashDocHeader2.Next = 0;

            if Abs(CashPaymentTotal) > GLSetup."Cash Payment Limit (LCY)" then
                Error(CashPaymentLimitErr, GLSetup."Cash Payment Limit (LCY)", "Partner No.");
        end;
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure SetOnHold(CashDocLine2: Record "Cash Document Line")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        with CashDocLine2 do
            if ("On Hold" <> '') and ("Applies-To Doc. Type" > 0) and ("Applies-To Doc. No." <> '') then begin
                if "Account Type" = "Account Type"::Customer then begin
                    CustLedgEntry.Reset();
                    CustLedgEntry.SetCurrentKey("Customer No.");
                    CustLedgEntry.SetRange("Customer No.");
                    CustLedgEntry.SetRange("Document Type", "Applies-To Doc. Type");
                    CustLedgEntry.SetRange("Document No.", "Applies-To Doc. No.");
                    CustLedgEntry.SetRange(Open, true);
                    CustLedgEntry.ModifyAll("On Hold", "On Hold");
                end;
                if "Account Type" = "Account Type"::Vendor then begin
                    VendLedgEntry.Reset();
                    VendLedgEntry.SetCurrentKey("Vendor No.");
                    VendLedgEntry.SetRange("Vendor No.");
                    VendLedgEntry.SetRange("Document Type", "Applies-To Doc. Type");
                    VendLedgEntry.SetRange("Document No.", "Applies-To Doc. No.");
                    VendLedgEntry.SetRange(Open, true);
                    VendLedgEntry.ModifyAll("On Hold", "On Hold");
                end;
            end;
    end;

    local procedure GetBankAccount(BankAccountNo: Code[20])
    begin
        if BankAccount."No." <> BankAccountNo then
            BankAccount.Get(BankAccountNo);
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseCashDoc(var CashDocHdr: Record "Cash Document Header")
    begin
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseCashDoc(var CashDocHdr: Record "Cash Document Header")
    begin
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenCashDoc(var CashDocHdr: Record "Cash Document Header")
    begin
    end;

    [Obsolete('Moved to Cash Desk Localization for Czech.', '17.4')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenCashDoc(var CashDocHdr: Record "Cash Document Header")
    begin
    end;
}

