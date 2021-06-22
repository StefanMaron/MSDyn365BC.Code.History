codeunit 227 "VendEntry-Apply Posted Entries"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    TableNo = "Vendor Ledger Entry";

    trigger OnRun()
    begin
        if PreviewMode then
            case RunOptionPreviewContext of
                RunOptionPreview::Apply:
                    Apply(Rec, DocumentNoPreviewContext, ApplicationDatePreviewContext);
                RunOptionPreview::Unapply:
                    PostUnApplyVendor(DetailedVendorLedgEntryPreviewContext, DocumentNoPreviewContext, ApplicationDatePreviewContext);
            end
        else
            Apply(Rec, "Document No.", 0D);
    end;

    var
        PostingApplicationMsg: Label 'Posting application...';
        MustNotBeBeforeErr: Label 'The posting date entered must not be before the posting date on the vendor ledger entry.';
        NoEntriesAppliedErr: Label 'Cannot post because you did not specify which entry to apply. You must specify an entry in the %1 field for one or more open entries.', Comment = '%1 - Caption of "Applies to ID" field of Gen. Journal Line';
        UnapplyPostedAfterThisEntryErr: Label 'Before you can unapply this entry, you must first unapply all application entries that were posted after this entry.';
        NoApplicationEntryErr: Label 'Vendor Ledger Entry No. %1 does not have an application entry.';
        UnapplyingMsg: Label 'Unapplying and posting...';
        UnapplyAllPostedAfterThisEntryErr: Label 'Before you can unapply this entry, you must first unapply all application entries in Vendor Ledger Entry No. %1 that were posted after this entry.';
        NotAllowedPostingDatesErr: Label 'Posting date is not within the range of allowed posting dates.';
        LatestEntryMustBeApplicationErr: Label 'The latest Transaction No. must be an application in Vendor Ledger Entry No. %1.';
        CannotUnapplyExchRateErr: Label 'You cannot unapply the entry with the posting date %1, because the exchange rate for the additional reporting currency has been changed.';
        CannotUnapplyInReversalErr: Label 'You cannot unapply Vendor Ledger Entry No. %1 because the entry is part of a reversal.';
        CannotApplyClosedEntriesErr: Label 'One or more of the entries that you selected is closed. You cannot apply closed entries.';
        DetailedVendorLedgEntryPreviewContext: Record "Detailed Vendor Ledg. Entry";
        ApplicationDatePreviewContext: Date;
        DocumentNoPreviewContext: Code[20];
        RunOptionPreview: Option Apply,Unapply;
        RunOptionPreviewContext: Option Apply,Unapply;
        PreviewMode: Boolean;

    procedure Apply(VendLedgEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20]; ApplicationDate: Date): Boolean
    var
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
    begin
        with VendLedgEntry do begin
            if not PreviewMode then
                if not PaymentToleranceMgt.PmtTolVend(VendLedgEntry) then
                    exit(false);
            Get("Entry No.");

            if ApplicationDate = 0D then
                ApplicationDate := GetApplicationDate(VendLedgEntry)
            else
                if ApplicationDate < GetApplicationDate(VendLedgEntry) then
                    Error(MustNotBeBeforeErr);

            if DocumentNo = '' then
                DocumentNo := "Document No.";

            VendPostApplyVendLedgEntry(VendLedgEntry, DocumentNo, ApplicationDate);
            exit(true);
        end;
    end;

    procedure GetApplicationDate(VendLedgEntry: Record "Vendor Ledger Entry") ApplicationDate: Date
    var
        ApplyToVendLedgEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetApplicationDate(VendLedgEntry, ApplicationDate, IsHandled);
        if IsHandled then
            exit(ApplicationDate);

        with VendLedgEntry do begin
            ApplicationDate := 0D;
            ApplyToVendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID");
            ApplyToVendLedgEntry.SetRange("Vendor No.", "Vendor No.");
            ApplyToVendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            OnGetApplicationDateOnAfterSetFilters(ApplyToVendLedgEntry, VendLedgEntry);
            ApplyToVendLedgEntry.Find('-');
            repeat
                if ApplyToVendLedgEntry."Posting Date" > ApplicationDate then
                    ApplicationDate := ApplyToVendLedgEntry."Posting Date";
            until ApplyToVendLedgEntry.Next = 0;
        end;
    end;

    local procedure VendPostApplyVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20]; ApplicationDate: Date)
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
        with VendLedgEntry do begin
            Window.Open(PostingApplicationMsg);

            SourceCodeSetup.Get();

            GenJnlLine.Init();
            GenJnlLine."Document No." := DocumentNo;
            GenJnlLine."Posting Date" := ApplicationDate;
            GenJnlLine."Document Date" := GenJnlLine."Posting Date";
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
            GenJnlLine."Account No." := "Vendor No.";
            CalcFields("Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");
            GenJnlLine.Correction :=
              ("Debit Amount" < 0) or ("Credit Amount" < 0) or
              ("Debit Amount (LCY)" < 0) or ("Credit Amount (LCY)" < 0);
            GenJnlLine."Document Type" := "Document Type";
            GenJnlLine.Description := Description;
            GenJnlLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
            GenJnlLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
            GenJnlLine."Dimension Set ID" := "Dimension Set ID";
            GenJnlLine."Posting Group" := "Vendor Posting Group";
            GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
            GenJnlLine."Source No." := "Vendor No.";
            GenJnlLine."Source Code" := SourceCodeSetup."Purchase Entry Application";
            GenJnlLine."System-Created Entry" := true;

            EntryNoBeforeApplication := FindLastApplDtldVendLedgEntry;

            OnBeforePostApplyVendLedgEntry(GenJnlLine, VendLedgEntry, GenJnlPostLine);
            GenJnlPostLine.VendPostApplyVendLedgEntry(GenJnlLine, VendLedgEntry);
            OnAfterPostApplyVendLedgEntry(GenJnlLine, VendLedgEntry, GenJnlPostLine);

            EntryNoAfterApplication := FindLastApplDtldVendLedgEntry;
            if EntryNoAfterApplication = EntryNoBeforeApplication then
                Error(NoEntriesAppliedErr, GenJnlLine.FieldCaption("Applies-to ID"));

            if PreviewMode then
                GenJnlPostPreview.ThrowError;

            Commit();
            Window.Close;
            UpdateAnalysisView.UpdateAll(0, true);
        end;
    end;

    local procedure FindLastApplDtldVendLedgEntry(): Integer
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.LockTable();
        exit(DtldVendLedgEntry.GetLastEntryNo());
    end;

    procedure FindLastApplEntry(VendLedgEntryNo: Integer): Integer
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ApplicationEntryNo: Integer;
    begin
        with DtldVendLedgEntry do begin
            SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
            SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
            SetRange("Entry Type", "Entry Type"::Application);
            SetRange(Unapplied, false);
            ApplicationEntryNo := 0;
            if Find('-') then
                repeat
                    if "Entry No." > ApplicationEntryNo then
                        ApplicationEntryNo := "Entry No.";
                until Next = 0;
        end;
        exit(ApplicationEntryNo);
    end;

    local procedure FindLastTransactionNo(VendLedgEntryNo: Integer): Integer
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        LastTransactionNo: Integer;
    begin
        with DtldVendLedgEntry do begin
            SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
            SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
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

    procedure UnApplyDtldVendLedgEntry(DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        ApplicationEntryNo: Integer;
    begin
        DtldVendLedgEntry.TestField("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.TestField(Unapplied, false);
        ApplicationEntryNo := FindLastApplEntry(DtldVendLedgEntry."Vendor Ledger Entry No.");

        if DtldVendLedgEntry."Entry No." <> ApplicationEntryNo then
            Error(UnapplyPostedAfterThisEntryErr);
        CheckReversal(DtldVendLedgEntry."Vendor Ledger Entry No.");
        UnApplyVendor(DtldVendLedgEntry);
    end;

    procedure UnApplyVendLedgEntry(VendLedgEntryNo: Integer)
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ApplicationEntryNo: Integer;
    begin
        CheckReversal(VendLedgEntryNo);
        ApplicationEntryNo := FindLastApplEntry(VendLedgEntryNo);
        if ApplicationEntryNo = 0 then
            Error(NoApplicationEntryErr, VendLedgEntryNo);
        DtldVendLedgEntry.Get(ApplicationEntryNo);
        UnApplyVendor(DtldVendLedgEntry);
    end;

    local procedure UnApplyVendor(DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        UnapplyVendEntries: Page "Unapply Vendor Entries";
    begin
        with DtldVendLedgEntry do begin
            TestField("Entry Type", "Entry Type"::Application);
            TestField(Unapplied, false);
            UnapplyVendEntries.SetDtldVendLedgEntry("Entry No.");
            UnapplyVendEntries.LookupMode(true);
            UnapplyVendEntries.RunModal;
        end;
    end;

    procedure PostUnApplyVendor(DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry"; DocNo: Code[20]; PostingDate: Date)
    var
        GLEntry: Record "G/L Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        DateComprReg: Record "Date Compr. Register";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
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
        DtldVendLedgEntry.LockTable();
        VendLedgEntry.LockTable();
        VendLedgEntry.Get(DtldVendLedgEntry2."Vendor Ledger Entry No.");
        CheckPostingDate(PostingDate, MaxPostingDate);
        if PostingDate < DtldVendLedgEntry2."Posting Date" then
            Error(MustNotBeBeforeErr);
        if DtldVendLedgEntry2."Transaction No." = 0 then begin
            DtldVendLedgEntry.SetCurrentKey("Application No.", "Vendor No.", "Entry Type");
            DtldVendLedgEntry.SetRange("Application No.", DtldVendLedgEntry2."Application No.");
        end else begin
            DtldVendLedgEntry.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
            DtldVendLedgEntry.SetRange("Transaction No.", DtldVendLedgEntry2."Transaction No.");
        end;
        DtldVendLedgEntry.SetRange("Vendor No.", DtldVendLedgEntry2."Vendor No.");
        DtldVendLedgEntry.SetFilter("Entry Type", '<>%1', DtldVendLedgEntry."Entry Type"::"Initial Entry");
        DtldVendLedgEntry.SetRange(Unapplied, false);
        if DtldVendLedgEntry.Find('-') then
            repeat
                if not AddCurrChecked then begin
                    CheckAdditionalCurrency(PostingDate, DtldVendLedgEntry."Posting Date");
                    AddCurrChecked := true;
                end;
                CheckReversal(DtldVendLedgEntry."Vendor Ledger Entry No.");
                if DtldVendLedgEntry."Transaction No." <> 0 then begin
                    if DtldVendLedgEntry."Entry Type" = DtldVendLedgEntry."Entry Type"::Application then begin
                        LastTransactionNo :=
                          FindLastApplTransactionEntry(DtldVendLedgEntry."Vendor Ledger Entry No.");
                        if (LastTransactionNo <> 0) and (LastTransactionNo <> DtldVendLedgEntry."Transaction No.") then
                            Error(UnapplyAllPostedAfterThisEntryErr, DtldVendLedgEntry."Vendor Ledger Entry No.");
                    end;
                    LastTransactionNo := FindLastTransactionNo(DtldVendLedgEntry."Vendor Ledger Entry No.");
                    if (LastTransactionNo <> 0) and (LastTransactionNo <> DtldVendLedgEntry."Transaction No.") then
                        Error(LatestEntryMustBeApplicationErr, DtldVendLedgEntry."Vendor Ledger Entry No.");
                end;
            until DtldVendLedgEntry.Next = 0;

        DateComprReg.CheckMaxDateCompressed(MaxPostingDate, 0);

        with DtldVendLedgEntry2 do begin
            SourceCodeSetup.Get();
            VendLedgEntry.Get("Vendor Ledger Entry No.");
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Posting Date" := PostingDate;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
            GenJnlLine."Account No." := "Vendor No.";
            GenJnlLine.Correction := true;
            GenJnlLine."Document Type" := "Document Type";
            GenJnlLine.Description := VendLedgEntry.Description;
            GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
            GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
            GenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
            GenJnlLine."Posting Group" := VendLedgEntry."Vendor Posting Group";
            GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
            GenJnlLine."Source No." := "Vendor No.";
            GenJnlLine."Source Code" := SourceCodeSetup."Unapplied Purch. Entry Appln.";
            GenJnlLine."Source Currency Code" := "Currency Code";
            GenJnlLine."System-Created Entry" := true;
            Window.Open(UnapplyingMsg);
            OnBeforePostUnapplyVendLedgEntry(GenJnlLine, VendLedgEntry, DtldVendLedgEntry2, GenJnlPostLine);
            CollectAffectedLedgerEntries(TempVendorLedgerEntry, DtldVendLedgEntry2);
            GenJnlPostLine.UnapplyVendLedgEntry(GenJnlLine, DtldVendLedgEntry2);
            AdjustExchangeRates.AdjustExchRateVend(GenJnlLine, TempVendorLedgerEntry);
            OnAfterPostUnapplyVendLedgEntry(GenJnlLine, VendLedgEntry, DtldVendLedgEntry2, GenJnlPostLine);

            if PreviewMode then
                GenJnlPostPreview.ThrowError;

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

    procedure CheckReversal(VendLedgEntryNo: Integer)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.Get(VendLedgEntryNo);
        if VendLedgEntry.Reversed then
            Error(CannotUnapplyInReversalErr, VendLedgEntryNo);
    end;

    procedure ApplyVendEntryFormEntry(var ApplyingVendLedgEntry: Record "Vendor Ledger Entry")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        ApplyVendEntries: Page "Apply Vendor Entries";
        VendEntryApplID: Code[50];
    begin
        if not ApplyingVendLedgEntry.Open then
            Error(CannotApplyClosedEntriesErr);

        VendEntryApplID := UserId;
        if VendEntryApplID = '' then
            VendEntryApplID := '***';
        if ApplyingVendLedgEntry."Remaining Amount" = 0 then
            ApplyingVendLedgEntry.CalcFields("Remaining Amount");

        ApplyingVendLedgEntry."Applying Entry" := true;
        if ApplyingVendLedgEntry."Applies-to ID" = '' then
            ApplyingVendLedgEntry."Applies-to ID" := VendEntryApplID;
        ApplyingVendLedgEntry."Amount to Apply" := ApplyingVendLedgEntry."Remaining Amount";
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", ApplyingVendLedgEntry);
        Commit();

        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
        VendLedgEntry.SetRange("Vendor No.", ApplyingVendLedgEntry."Vendor No.");
        VendLedgEntry.SetRange(Open, true);
        if VendLedgEntry.FindFirst then begin
            ApplyVendEntries.SetVendLedgEntry(ApplyingVendLedgEntry);
            ApplyVendEntries.SetRecord(VendLedgEntry);
            ApplyVendEntries.SetTableView(VendLedgEntry);
            if ApplyingVendLedgEntry."Applies-to ID" <> VendEntryApplID then
                ApplyVendEntries.SetAppliesToID(ApplyingVendLedgEntry."Applies-to ID");
            ApplyVendEntries.RunModal;
            Clear(ApplyVendEntries);
            ApplyingVendLedgEntry."Applying Entry" := false;
            ApplyingVendLedgEntry."Applies-to ID" := '';
            ApplyingVendLedgEntry."Amount to Apply" := 0;
        end;
    end;

    local procedure CollectAffectedLedgerEntries(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        TempVendorLedgerEntry.DeleteAll();
        with DetailedVendorLedgEntry do begin
            if DetailedVendorLedgEntry2."Transaction No." = 0 then begin
                SetCurrentKey("Application No.", "Vendor No.", "Entry Type");
                SetRange("Application No.", DetailedVendorLedgEntry2."Application No.");
            end else begin
                SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
                SetRange("Transaction No.", DetailedVendorLedgEntry2."Transaction No.");
            end;
            SetRange("Vendor No.", DetailedVendorLedgEntry2."Vendor No.");
            SetRange(Unapplied, false);
            SetFilter("Entry Type", '<>%1', "Entry Type"::"Initial Entry");
            if FindSet then
                repeat
                    TempVendorLedgerEntry."Entry No." := "Vendor Ledger Entry No.";
                    if TempVendorLedgerEntry.Insert() then;
                until Next = 0;
        end;
    end;

    local procedure FindLastApplTransactionEntry(VendLedgEntryNo: Integer): Integer
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        LastTransactionNo: Integer;
    begin
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        LastTransactionNo := 0;
        if DtldVendLedgEntry.Find('-') then
            repeat
                if (DtldVendLedgEntry."Transaction No." > LastTransactionNo) and not DtldVendLedgEntry.Unapplied then
                    LastTransactionNo := DtldVendLedgEntry."Transaction No.";
            until DtldVendLedgEntry.Next = 0;
        exit(LastTransactionNo);
    end;

    procedure PreviewApply(VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20]; ApplicationDate: Date)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
    begin
        if not PaymentToleranceMgt.PmtTolVend(VendorLedgerEntry) then
            exit;

        BindSubscription(VendEntryApplyPostedEntries);
        VendEntryApplyPostedEntries.SetApplyContext(ApplicationDate, DocumentNo);
        GenJnlPostPreview.Preview(VendEntryApplyPostedEntries, VendorLedgerEntry);
    end;

    procedure PreviewUnapply(DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; DocumentNo: Code[20]; ApplicationDate: Date)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
    begin
        BindSubscription(VendEntryApplyPostedEntries);
        VendEntryApplyPostedEntries.SetUnapplyContext(DetailedVendorLedgEntry, ApplicationDate, DocumentNo);
        GenJnlPostPreview.Preview(VendEntryApplyPostedEntries, VendorLedgerEntry);
    end;

    procedure SetApplyContext(ApplicationDate: Date; DocumentNo: Code[20])
    begin
        ApplicationDatePreviewContext := ApplicationDate;
        DocumentNoPreviewContext := DocumentNo;
        RunOptionPreviewContext := RunOptionPreview::Apply;
    end;

    procedure SetUnapplyContext(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; ApplicationDate: Date; DocumentNo: Code[20])
    begin
        ApplicationDatePreviewContext := ApplicationDate;
        DocumentNoPreviewContext := DocumentNo;
        DetailedVendorLedgEntryPreviewContext := DetailedVendorLedgEntry;
        RunOptionPreviewContext := RunOptionPreview::Unapply;
    end;

    [EventSubscriber(ObjectType::Codeunit, 19, 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
    begin
        VendEntryApplyPostedEntries := Subscriber;
        PreviewMode := true;
        Result := VendEntryApplyPostedEntries.Run(RecVar);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostApplyVendLedgEntry(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUnapplyVendLedgEntry(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetApplicationDate(VendorLedgEntry: Record "Vendor Ledger Entry"; var ApplicationDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostApplyVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUnapplyVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetApplicationDateOnAfterSetFilters(var ApplyToVendLedgEntry: Record "Vendor Ledger Entry"; VendorLedgEntry: Record "Vendor Ledger Entry");
    begin
    end;
}

