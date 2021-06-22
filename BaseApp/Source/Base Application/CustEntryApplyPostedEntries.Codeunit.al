codeunit 226 "CustEntry-Apply Posted Entries"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    TableNo = "Cust. Ledger Entry";

    trigger OnRun()
    begin
        if PreviewMode then
            case RunOptionPreviewContext of
                RunOptionPreview::Apply:
                    Apply(Rec, DocumentNoPreviewContext, ApplicationDatePreviewContext);
                RunOptionPreview::Unapply:
                    PostUnApplyCustomer(DetailedCustLedgEntryPreviewContext, DocumentNoPreviewContext, ApplicationDatePreviewContext);
            end
        else
            Apply(Rec, "Document No.", 0D);
    end;

    var
        PostingApplicationMsg: Label 'Posting application...';
        MustNotBeBeforeErr: Label 'The Posting Date entered must not be before the Posting Date on the Cust. Ledger Entry.';
        NoEntriesAppliedErr: Label 'Cannot post because you did not specify which entry to apply. You must specify an entry in the %1 field for one or more open entries.', Comment = '%1 - Caption of "Applies to ID" field of Gen. Journal Line';
        UnapplyPostedAfterThisEntryErr: Label 'Before you can unapply this entry, you must first unapply all application entries that were posted after this entry.';
        NoApplicationEntryErr: Label 'Cust. Ledger Entry No. %1 does not have an application entry.';
        UnapplyingMsg: Label 'Unapplying and posting...';
        UnapplyAllPostedAfterThisEntryErr: Label 'Before you can unapply this entry, you must first unapply all application entries in Cust. Ledger Entry No. %1 that were posted after this entry.';
        NotAllowedPostingDatesErr: Label 'Posting date is not within the range of allowed posting dates.';
        LatestEntryMustBeAnApplicationErr: Label 'The latest Transaction No. must be an application in Cust. Ledger Entry No. %1.';
        CannotUnapplyExchRateErr: Label 'You cannot unapply the entry with the posting date %1, because the exchange rate for the additional reporting currency has been changed.';
        CannotUnapplyInReversalErr: Label 'You cannot unapply Cust. Ledger Entry No. %1 because the entry is part of a reversal.';
        CannotApplyClosedEntriesErr: Label 'One or more of the entries that you selected is closed. You cannot apply closed entries.';
        DetailedCustLedgEntryPreviewContext: Record "Detailed Cust. Ledg. Entry";
        ApplicationDatePreviewContext: Date;
        DocumentNoPreviewContext: Code[20];
        RunOptionPreview: Option Apply,Unapply;
        RunOptionPreviewContext: Option Apply,Unapply;
        PreviewMode: Boolean;

    procedure Apply(CustLedgEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; ApplicationDate: Date): Boolean
    var
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
    begin
        with CustLedgEntry do begin
            if not PreviewMode then
                if not PaymentToleranceMgt.PmtTolCust(CustLedgEntry) then
                    exit(false);
            Get("Entry No.");

            if ApplicationDate = 0D then
                ApplicationDate := GetApplicationDate(CustLedgEntry)
            else
                if ApplicationDate < GetApplicationDate(CustLedgEntry) then
                    Error(MustNotBeBeforeErr);

            if DocumentNo = '' then
                DocumentNo := "Document No.";

            CustPostApplyCustLedgEntry(CustLedgEntry, DocumentNo, ApplicationDate);
            exit(true);
        end;
    end;

    procedure GetApplicationDate(CustLedgEntry: Record "Cust. Ledger Entry") ApplicationDate: Date
    var
        ApplyToCustLedgEntry: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetApplicationDate(CustLedgEntry, ApplicationDate, IsHandled);
        if IsHandled then
            exit(ApplicationDate);

        with CustLedgEntry do begin
            ApplicationDate := 0D;
            ApplyToCustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID");
            ApplyToCustLedgEntry.SetRange("Customer No.", "Customer No.");
            ApplyToCustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            OnGetApplicationDateOnAfterSetFilters(ApplyToCustLedgEntry, CustLedgEntry);
            ApplyToCustLedgEntry.FindSet;
            repeat
                if ApplyToCustLedgEntry."Posting Date" > ApplicationDate then
                    ApplicationDate := ApplyToCustLedgEntry."Posting Date";
            until ApplyToCustLedgEntry.Next = 0;
        end;
    end;

    local procedure CustPostApplyCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; ApplicationDate: Date)
    var
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        Window: Dialog;
        EntryNoBeforeApplication: Integer;
        EntryNoAfterApplication: Integer;
    begin
        with CustLedgEntry do begin
            Window.Open(PostingApplicationMsg);

            SourceCodeSetup.Get();

            GenJnlLine.Init();
            GenJnlLine."Document No." := DocumentNo;
            GenJnlLine."Posting Date" := ApplicationDate;
            GenJnlLine."Document Date" := GenJnlLine."Posting Date";
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
            GenJnlLine."Account No." := "Customer No.";
            CalcFields("Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");
            GenJnlLine.Correction :=
              ("Debit Amount" < 0) or ("Credit Amount" < 0) or
              ("Debit Amount (LCY)" < 0) or ("Credit Amount (LCY)" < 0);
            GenJnlLine.CopyCustLedgEntry(CustLedgEntry);
            GenJnlLine."Source Code" := SourceCodeSetup."Sales Entry Application";
            GenJnlLine."System-Created Entry" := true;

            EntryNoBeforeApplication := FindLastApplDtldCustLedgEntry;

            OnBeforePostApplyCustLedgEntry(GenJnlLine, CustLedgEntry, GenJnlPostLine);
            GenJnlPostLine.CustPostApplyCustLedgEntry(GenJnlLine, CustLedgEntry);
            OnAfterPostApplyCustLedgEntry(GenJnlLine, CustLedgEntry, GenJnlPostLine);

            EntryNoAfterApplication := FindLastApplDtldCustLedgEntry;
            if EntryNoAfterApplication = EntryNoBeforeApplication then
                Error(NoEntriesAppliedErr, GenJnlLine.FieldCaption("Applies-to ID"));

            if PreviewMode then
                GenJnlPostPreview.ThrowError;

            Commit();
            Window.Close;
            UpdateAnalysisView.UpdateAll(0, true);
        end;
    end;

    local procedure FindLastApplDtldCustLedgEntry(): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.LockTable();
        exit(DtldCustLedgEntry.GetLastEntryNo());
    end;

    procedure FindLastApplEntry(CustLedgEntryNo: Integer): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplicationEntryNo: Integer;
    begin
        with DtldCustLedgEntry do begin
            SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
            SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
            SetRange("Entry Type", "Entry Type"::Application);
            SetRange(Unapplied, false);
            OnFindLastApplEntryOnAfterSetFilters(DtldCustLedgEntry);
            ApplicationEntryNo := 0;
            if Find('-') then
                repeat
                    if "Entry No." > ApplicationEntryNo then
                        ApplicationEntryNo := "Entry No.";
                until Next = 0;
        end;
        exit(ApplicationEntryNo);
    end;

    local procedure FindLastTransactionNo(CustLedgEntryNo: Integer): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LastTransactionNo: Integer;
    begin
        with DtldCustLedgEntry do begin
            SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
            SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
            SetRange(Unapplied, false);
            SetFilter("Entry Type", '<>%1&<>%2', "Entry Type"::"Unrealized Loss", "Entry Type"::"Unrealized Gain");
            LastTransactionNo := 0;
            if FindSet then
                repeat
                    if LastTransactionNo < "Transaction No." then
                        LastTransactionNo := "Transaction No.";
                until Next = 0;
        end;
        exit(LastTransactionNo);
    end;

    procedure UnApplyDtldCustLedgEntry(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        ApplicationEntryNo: Integer;
    begin
        DtldCustLedgEntry.TestField("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.TestField(Unapplied, false);
        ApplicationEntryNo := FindLastApplEntry(DtldCustLedgEntry."Cust. Ledger Entry No.");

        if DtldCustLedgEntry."Entry No." <> ApplicationEntryNo then
            Error(UnapplyPostedAfterThisEntryErr);
        CheckReversal(DtldCustLedgEntry."Cust. Ledger Entry No.");
        UnApplyCustomer(DtldCustLedgEntry);
    end;

    procedure UnApplyCustLedgEntry(CustLedgEntryNo: Integer)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplicationEntryNo: Integer;
    begin
        CheckReversal(CustLedgEntryNo);
        ApplicationEntryNo := FindLastApplEntry(CustLedgEntryNo);
        if ApplicationEntryNo = 0 then
            Error(NoApplicationEntryErr, CustLedgEntryNo);
        DtldCustLedgEntry.Get(ApplicationEntryNo);
        UnApplyCustomer(DtldCustLedgEntry);
    end;

    local procedure UnApplyCustomer(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        UnapplyCustEntries: Page "Unapply Customer Entries";
    begin
        with DtldCustLedgEntry do begin
            TestField("Entry Type", "Entry Type"::Application);
            TestField(Unapplied, false);
            UnapplyCustEntries.SetDtldCustLedgEntry("Entry No.");
            UnapplyCustEntries.LookupMode(true);
            UnapplyCustEntries.RunModal;
        end;
    end;

    procedure PostUnApplyCustomer(DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; DocNo: Code[20]; PostingDate: Date)
    begin
        PostUnApplyCustomerCommit(DtldCustLedgEntry2, DocNo, PostingDate, true);
    end;

    procedure PostUnApplyCustomerCommit(DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; DocNo: Code[20]; PostingDate: Date; CommitChanges: Boolean)
    var
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DateComprReg: Record "Date Compr. Register";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        AdjustExchangeRates: Report "Adjust Exchange Rates";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        Window: Dialog;
        LastTransactionNo: Integer;
        AddCurrChecked: Boolean;
        MaxPostingDate: Date;
    begin
        MaxPostingDate := 0D;
        GLEntry.LockTable();
        DtldCustLedgEntry.LockTable();
        CustLedgEntry.LockTable();
        CustLedgEntry.Get(DtldCustLedgEntry2."Cust. Ledger Entry No.");
        CheckPostingDate(PostingDate, MaxPostingDate);
        if PostingDate < DtldCustLedgEntry2."Posting Date" then
            Error(MustNotBeBeforeErr);
        if DtldCustLedgEntry2."Transaction No." = 0 then begin
            DtldCustLedgEntry.SetCurrentKey("Application No.", "Customer No.", "Entry Type");
            DtldCustLedgEntry.SetRange("Application No.", DtldCustLedgEntry2."Application No.");
        end else begin
            DtldCustLedgEntry.SetCurrentKey("Transaction No.", "Customer No.", "Entry Type");
            DtldCustLedgEntry.SetRange("Transaction No.", DtldCustLedgEntry2."Transaction No.");
        end;
        DtldCustLedgEntry.SetRange("Customer No.", DtldCustLedgEntry2."Customer No.");
        DtldCustLedgEntry.SetFilter("Entry Type", '<>%1', DtldCustLedgEntry."Entry Type"::"Initial Entry");
        DtldCustLedgEntry.SetRange(Unapplied, false);
        OnPostUnApplyCustomerCommitOnAfterSetFilters(DtldCustLedgEntry, DtldCustLedgEntry2);
        if DtldCustLedgEntry.Find('-') then
            repeat
                if not AddCurrChecked then begin
                    CheckAdditionalCurrency(PostingDate, DtldCustLedgEntry."Posting Date");
                    AddCurrChecked := true;
                end;
                CheckReversal(DtldCustLedgEntry."Cust. Ledger Entry No.");
                if DtldCustLedgEntry."Transaction No." <> 0 then begin
                    if DtldCustLedgEntry."Entry Type" = DtldCustLedgEntry."Entry Type"::Application then begin
                        LastTransactionNo :=
                          FindLastApplTransactionEntry(DtldCustLedgEntry."Cust. Ledger Entry No.");
                        if (LastTransactionNo <> 0) and (LastTransactionNo <> DtldCustLedgEntry."Transaction No.") then
                            Error(UnapplyAllPostedAfterThisEntryErr, DtldCustLedgEntry."Cust. Ledger Entry No.");
                    end;
                    LastTransactionNo := FindLastTransactionNo(DtldCustLedgEntry."Cust. Ledger Entry No.");
                    if (LastTransactionNo <> 0) and (LastTransactionNo <> DtldCustLedgEntry."Transaction No.") then
                        Error(LatestEntryMustBeAnApplicationErr, DtldCustLedgEntry."Cust. Ledger Entry No.");
                end;
            until DtldCustLedgEntry.Next = 0;

        DateComprReg.CheckMaxDateCompressed(MaxPostingDate, 0);

        with DtldCustLedgEntry2 do begin
            SourceCodeSetup.Get();
            CustLedgEntry.Get("Cust. Ledger Entry No.");
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Posting Date" := PostingDate;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
            GenJnlLine."Account No." := "Customer No.";
            GenJnlLine.Correction := true;
            GenJnlLine.CopyCustLedgEntry(CustLedgEntry);
            GenJnlLine."Source Code" := SourceCodeSetup."Unapplied Sales Entry Appln.";
            GenJnlLine."Source Currency Code" := "Currency Code";
            GenJnlLine."System-Created Entry" := true;
            Window.Open(UnapplyingMsg);

            OnBeforePostUnapplyCustLedgEntry(GenJnlLine, CustLedgEntry, DtldCustLedgEntry2, GenJnlPostLine);
            CollectAffectedLedgerEntries(TempCustLedgerEntry, DtldCustLedgEntry2);
            GenJnlPostLine.UnapplyCustLedgEntry(GenJnlLine, DtldCustLedgEntry2);
            AdjustExchangeRates.AdjustExchRateCust(GenJnlLine, TempCustLedgerEntry);
            OnAfterPostUnapplyCustLedgEntry(GenJnlLine, CustLedgEntry, DtldCustLedgEntry2, GenJnlPostLine);

            if PreviewMode then
                GenJnlPostPreview.ThrowError;

            if CommitChanges then
                Commit();
            Window.Close;
        end;
    end;

    local procedure CheckPostingDate(PostingDate: Date; var MaxPostingDate: Date)
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        if GenJnlCheckLine.DateNotAllowed(PostingDate) then
            Error(NotAllowedPostingDatesErr);

        if PostingDate > MaxPostingDate then
            MaxPostingDate := PostingDate;
    end;

    local procedure CheckAdditionalCurrency(OldPostingDate: Date; NewPostingDate: Date)
    var
        GLSetup: Record "General Ledger Setup";
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if OldPostingDate = NewPostingDate then
            exit;
        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" <> '' then
            if CurrExchRate.ExchangeRate(OldPostingDate, GLSetup."Additional Reporting Currency") <>
               CurrExchRate.ExchangeRate(NewPostingDate, GLSetup."Additional Reporting Currency")
            then
                Error(CannotUnapplyExchRateErr, NewPostingDate);
    end;

    procedure CheckReversal(CustLedgEntryNo: Integer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.Get(CustLedgEntryNo);
        if CustLedgEntry.Reversed then
            Error(CannotUnapplyInReversalErr, CustLedgEntryNo);
    end;

    procedure ApplyCustEntryFormEntry(var ApplyingCustLedgEntry: Record "Cust. Ledger Entry")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        ApplyCustEntries: Page "Apply Customer Entries";
        CustEntryApplID: Code[50];
    begin
        if not ApplyingCustLedgEntry.Open then
            Error(CannotApplyClosedEntriesErr);

        CustEntryApplID := UserId;
        if CustEntryApplID = '' then
            CustEntryApplID := '***';
        if ApplyingCustLedgEntry."Remaining Amount" = 0 then
            ApplyingCustLedgEntry.CalcFields("Remaining Amount");

        ApplyingCustLedgEntry."Applying Entry" := true;
        ApplyingCustLedgEntry."Applies-to ID" := CustEntryApplID;
        ApplyingCustLedgEntry."Amount to Apply" := ApplyingCustLedgEntry."Remaining Amount";
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", ApplyingCustLedgEntry);
        Commit();

        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
        CustLedgEntry.SetRange("Customer No.", ApplyingCustLedgEntry."Customer No.");
        CustLedgEntry.SetRange(Open, true);
        if CustLedgEntry.FindFirst then begin
            ApplyCustEntries.SetCustLedgEntry(ApplyingCustLedgEntry);
            ApplyCustEntries.SetRecord(CustLedgEntry);
            ApplyCustEntries.SetTableView(CustLedgEntry);
            ApplyCustEntries.RunModal;
            Clear(ApplyCustEntries);
            ApplyingCustLedgEntry."Applying Entry" := false;
            ApplyingCustLedgEntry."Applies-to ID" := '';
            ApplyingCustLedgEntry."Amount to Apply" := 0;
        end;
    end;

    local procedure CollectAffectedLedgerEntries(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        TempCustLedgerEntry.DeleteAll();
        with DetailedCustLedgEntry do begin
            if DetailedCustLedgEntry2."Transaction No." = 0 then begin
                SetCurrentKey("Application No.", "Customer No.", "Entry Type");
                SetRange("Application No.", DetailedCustLedgEntry2."Application No.");
            end else begin
                SetCurrentKey("Transaction No.", "Customer No.", "Entry Type");
                SetRange("Transaction No.", DetailedCustLedgEntry2."Transaction No.");
            end;
            SetRange("Customer No.", DetailedCustLedgEntry2."Customer No.");
            SetRange(Unapplied, false);
            SetFilter("Entry Type", '<>%1', "Entry Type"::"Initial Entry");
            if FindSet then
                repeat
                    TempCustLedgerEntry."Entry No." := "Cust. Ledger Entry No.";
                    if TempCustLedgerEntry.Insert() then;
                until Next = 0;
        end;
    end;

    local procedure FindLastApplTransactionEntry(CustLedgEntryNo: Integer): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LastTransactionNo: Integer;
    begin
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        LastTransactionNo := 0;
        if DtldCustLedgEntry.Find('-') then
            repeat
                if (DtldCustLedgEntry."Transaction No." > LastTransactionNo) and not DtldCustLedgEntry.Unapplied then
                    LastTransactionNo := DtldCustLedgEntry."Transaction No.";
            until DtldCustLedgEntry.Next = 0;
        exit(LastTransactionNo);
    end;

    procedure PreviewApply(CustLedgEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; ApplicationDate: Date)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
    begin
        if not PaymentToleranceMgt.PmtTolCust(CustLedgEntry) then
            exit;

        BindSubscription(CustEntryApplyPostedEntries);
        CustEntryApplyPostedEntries.SetApplyContext(ApplicationDate, DocumentNo);
        GenJnlPostPreview.Preview(CustEntryApplyPostedEntries, CustLedgEntry);
    end;

    procedure PreviewUnapply(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DocumentNo: Code[20]; ApplicationDate: Date)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        BindSubscription(CustEntryApplyPostedEntries);
        CustEntryApplyPostedEntries.SetUnapplyContext(DetailedCustLedgEntry, ApplicationDate, DocumentNo);
        GenJnlPostPreview.Preview(CustEntryApplyPostedEntries, CustLedgEntry);
    end;

    procedure SetApplyContext(ApplicationDate: Date; DocumentNo: Code[20])
    begin
        ApplicationDatePreviewContext := ApplicationDate;
        DocumentNoPreviewContext := DocumentNo;
        RunOptionPreviewContext := RunOptionPreview::Apply;
    end;

    procedure SetUnapplyContext(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; ApplicationDate: Date; DocumentNo: Code[20])
    begin
        ApplicationDatePreviewContext := ApplicationDate;
        DocumentNoPreviewContext := DocumentNo;
        DetailedCustLedgEntryPreviewContext := DetailedCustLedgEntry;
        RunOptionPreviewContext := RunOptionPreview::Unapply;
    end;

    [EventSubscriber(ObjectType::Codeunit, 19, 'OnRunPreview', '', false, false)]
    local procedure OnPreviewRun(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        CustEntryApplyPostedEntries := Subscriber;
        PreviewMode := true;
        Result := CustEntryApplyPostedEntries.Run(RecVar);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostApplyCustLedgEntry(GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUnapplyCustLedgEntry(GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetApplicationDate(CustLedgEntry: Record "Cust. Ledger Entry"; var ApplicationDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostApplyCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUnapplyCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetApplicationDateOnAfterSetFilters(var ApplyToCustLedgEntry: Record "Cust. Ledger Entry"; CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindLastApplEntryOnAfterSetFilters(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnApplyCustomerCommitOnAfterSetFilters(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry")
    begin
    end;
}

