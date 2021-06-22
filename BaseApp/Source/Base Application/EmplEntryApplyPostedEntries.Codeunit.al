codeunit 224 "EmplEntry-Apply Posted Entries"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Employee Ledger Entry" = rimd,
                  TableData "Detailed Employee Ledger Entry" = rimd;
    TableNo = "Employee Ledger Entry";

    trigger OnRun()
    begin
        if PreviewMode then
            case RunOptionPreviewContext of
                RunOptionPreview::Apply:
                    Apply(Rec, DocumentNoPreviewContext, ApplicationDatePreviewContext);
                RunOptionPreview::Unapply:
                    PostUnApplyEmployee(DetailedEmployeeLedgEntryPreviewContext, DocumentNoPreviewContext, ApplicationDatePreviewContext);
            end
        else
            Apply(Rec, "Document No.", 0D);
    end;

    var
        PostingApplicationMsg: Label 'Posting application...';
        MustNotBeBeforeErr: Label 'The posting date entered must not be before the posting date on the employee ledger entry.';
        NoEntriesAppliedErr: Label 'Cannot post because you did not specify which entry to apply. You must specify an entry in the Applies-to ID field for one or more open entries.', Comment = '%1 - Caption of "Applies to ID" field of Gen. Journal Line';
        UnapplyPostedAfterThisEntryErr: Label 'Before you can unapply this entry, you must first unapply all application entries that were posted after this entry.';
        NoApplicationEntryErr: Label 'Employee ledger entry number %1 does not have an application entry.', Comment = '%1 - arbitrary text, the identifier of the ledger entry';
        UnapplyingMsg: Label 'Unapplying and posting...';
        UnapplyAllPostedAfterThisEntryErr: Label 'Before you can unapply this entry, you must first unapply all application entries in employee ledger entry number %1 that were posted after this entry.', Comment = '%1 - arbitrary text, the identifier of the ledger entry';
        NotAllowedPostingDatesErr: Label 'Posting date is not within the range of allowed posting dates.';
        LatestEntryMustBeApplicationErr: Label 'The latest transaction number must be an application in employee ledger entry number %1.', Comment = '%1 - arbitrary text, the identifier of the ledger entry';
        CannotUnapplyExchRateErr: Label 'You cannot unapply the entry with the posting date %1, because the exchange rate for the additional reporting currency has been changed.', Comment = '%1 - a date';
        CannotApplyClosedEntriesErr: Label 'One or more of the entries that you selected is closed. You cannot apply closed entries.';
        DetailedEmployeeLedgEntryPreviewContext: Record "Detailed Employee Ledger Entry";
        ApplicationDatePreviewContext: Date;
        DocumentNoPreviewContext: Code[20];
        RunOptionPreview: Option Apply,Unapply;
        RunOptionPreviewContext: Option Apply,Unapply;
        PreviewMode: Boolean;

    procedure Apply(EmplLedgEntry: Record "Employee Ledger Entry"; DocumentNo: Code[20]; ApplicationDate: Date)
    begin
        with EmplLedgEntry do begin
            Get("Entry No.");

            if ApplicationDate = 0D then
                ApplicationDate := GetApplicationDate(EmplLedgEntry)
            else
                if ApplicationDate < GetApplicationDate(EmplLedgEntry) then
                    Error(MustNotBeBeforeErr);

            if DocumentNo = '' then
                DocumentNo := "Document No.";

            EmplPostApplyEmplLedgEntry(EmplLedgEntry, DocumentNo, ApplicationDate);
        end;
    end;

    procedure GetApplicationDate(EmplLedgEntry: Record "Employee Ledger Entry") ApplicationDate: Date
    var
        ApplyToEmplLedgEntry: Record "Employee Ledger Entry";
    begin
        with EmplLedgEntry do begin
            ApplicationDate := 0D;
            ApplyToEmplLedgEntry.SetCurrentKey("Employee No.", "Applies-to ID");
            ApplyToEmplLedgEntry.SetRange("Employee No.", "Employee No.");
            ApplyToEmplLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            ApplyToEmplLedgEntry.Find('-');
            repeat
                if ApplyToEmplLedgEntry."Posting Date" > ApplicationDate then
                    ApplicationDate := ApplyToEmplLedgEntry."Posting Date";
            until ApplyToEmplLedgEntry.Next = 0;
        end;
    end;

    local procedure EmplPostApplyEmplLedgEntry(EmplLedgEntry: Record "Employee Ledger Entry"; DocumentNo: Code[20]; ApplicationDate: Date)
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
        with EmplLedgEntry do begin
            Window.Open(PostingApplicationMsg);

            SourceCodeSetup.Get();

            GenJnlLine.Init();
            GenJnlLine."Document No." := DocumentNo;
            GenJnlLine."Posting Date" := ApplicationDate;
            GenJnlLine."Document Date" := GenJnlLine."Posting Date";
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Employee;
            GenJnlLine."Account No." := "Employee No.";
            CalcFields("Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");
            GenJnlLine.Correction :=
              ("Debit Amount" < 0) or ("Credit Amount" < 0) or
              ("Debit Amount (LCY)" < 0) or ("Credit Amount (LCY)" < 0);
            GenJnlLine."Document Type" := "Document Type";
            GenJnlLine.Description := Description;
            GenJnlLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
            GenJnlLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
            GenJnlLine."Dimension Set ID" := "Dimension Set ID";
            GenJnlLine."Posting Group" := "Employee Posting Group";
            GenJnlLine."Source No." := "Employee No.";
            GenJnlLine."Source Type" := GenJnlLine."Source Type"::Employee;
            GenJnlLine."Source Code" := SourceCodeSetup."Employee Entry Application";
            GenJnlLine."System-Created Entry" := true;

            EntryNoBeforeApplication := FindLastApplDtldEmplLedgEntry;

            OnEmplPostApplyEmplLedgEntryOnBeforeGenJnlPostLine(GenJnlLine, EmplLedgEntry);
            GenJnlPostLine.EmplPostApplyEmplLedgEntry(GenJnlLine, EmplLedgEntry);

            EntryNoAfterApplication := FindLastApplDtldEmplLedgEntry;
            if EntryNoAfterApplication = EntryNoBeforeApplication then
                Error(NoEntriesAppliedErr);

            if PreviewMode then
                GenJnlPostPreview.ThrowError;

            Commit();
            Window.Close;
            UpdateAnalysisView.UpdateAll(0, true);
        end;
    end;

    local procedure FindLastApplDtldEmplLedgEntry(): Integer
    var
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        DtldEmplLedgEntry.LockTable();
        exit(DtldEmplLedgEntry.GetLastEntryNo());
    end;

    local procedure FindLastApplEntry(EmplLedgEntryNo: Integer): Integer
    var
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        ApplicationEntryNo: Integer;
    begin
        with DtldEmplLedgEntry do begin
            SetCurrentKey("Employee Ledger Entry No.", "Entry Type");
            SetRange("Employee Ledger Entry No.", EmplLedgEntryNo);
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

    local procedure FindLastTransactionNo(EmplLedgEntryNo: Integer): Integer
    var
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        LastTransactionNo: Integer;
    begin
        with DtldEmplLedgEntry do begin
            SetCurrentKey("Employee Ledger Entry No.", "Entry Type");
            SetRange("Employee Ledger Entry No.", EmplLedgEntryNo);
            SetRange(Unapplied, false);
            LastTransactionNo := 0;
            if FindSet then
                repeat
                    if LastTransactionNo < "Transaction No." then
                        LastTransactionNo := "Transaction No.";
                until Next = 0;
        end;
        exit(LastTransactionNo);
    end;

    procedure UnApplyDtldEmplLedgEntry(DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry")
    var
        ApplicationEntryNo: Integer;
    begin
        DtldEmplLedgEntry.TestField("Entry Type", DtldEmplLedgEntry."Entry Type"::Application);
        DtldEmplLedgEntry.TestField(Unapplied, false);
        ApplicationEntryNo := FindLastApplEntry(DtldEmplLedgEntry."Employee Ledger Entry No.");

        if DtldEmplLedgEntry."Entry No." <> ApplicationEntryNo then
            Error(UnapplyPostedAfterThisEntryErr);
        UnApplyEmployee(DtldEmplLedgEntry);
    end;

    procedure UnApplyEmplLedgEntry(EmplLedgEntryNo: Integer)
    var
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        ApplicationEntryNo: Integer;
    begin
        ApplicationEntryNo := FindLastApplEntry(EmplLedgEntryNo);
        if ApplicationEntryNo = 0 then
            Error(NoApplicationEntryErr, EmplLedgEntryNo);
        DtldEmplLedgEntry.Get(ApplicationEntryNo);
        UnApplyEmployee(DtldEmplLedgEntry);
    end;

    local procedure UnApplyEmployee(DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry")
    var
        UnapplyEmplEntries: Page "Unapply Employee Entries";
    begin
        with DtldEmplLedgEntry do begin
            TestField("Entry Type", "Entry Type"::Application);
            TestField(Unapplied, false);
            UnapplyEmplEntries.SetDtldEmplLedgEntry("Entry No.");
            UnapplyEmplEntries.LookupMode(true);
            UnapplyEmplEntries.RunModal;
        end;
    end;

    procedure PostUnApplyEmployee(DtldEmplLedgEntry2: Record "Detailed Employee Ledger Entry"; DocNo: Code[20]; PostingDate: Date)
    var
        GLEntry: Record "G/L Entry";
        EmplLedgEntry: Record "Employee Ledger Entry";
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        DateComprReg: Record "Date Compr. Register";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        Window: Dialog;
        LastTransactionNo: Integer;
        AddCurrChecked: Boolean;
        MaxPostingDate: Date;
    begin
        MaxPostingDate := 0D;
        GLEntry.LockTable();
        DtldEmplLedgEntry.LockTable();
        EmplLedgEntry.LockTable();
        EmplLedgEntry.Get(DtldEmplLedgEntry2."Employee Ledger Entry No.");
        CheckPostingDate(PostingDate, MaxPostingDate);
        if PostingDate < DtldEmplLedgEntry2."Posting Date" then
            Error(MustNotBeBeforeErr);
        if DtldEmplLedgEntry2."Transaction No." = 0 then begin
            DtldEmplLedgEntry.SetCurrentKey("Application No.", "Employee No.", "Entry Type");
            DtldEmplLedgEntry.SetRange("Application No.", DtldEmplLedgEntry2."Application No.");
        end else begin
            DtldEmplLedgEntry.SetCurrentKey("Transaction No.", "Employee No.", "Entry Type");
            DtldEmplLedgEntry.SetRange("Transaction No.", DtldEmplLedgEntry2."Transaction No.");
        end;
        DtldEmplLedgEntry.SetRange("Employee No.", DtldEmplLedgEntry2."Employee No.");
        DtldEmplLedgEntry.SetFilter("Entry Type", '<>%1', DtldEmplLedgEntry."Entry Type"::"Initial Entry");
        DtldEmplLedgEntry.SetRange(Unapplied, false);
        if DtldEmplLedgEntry.Find('-') then
            repeat
                if not AddCurrChecked then begin
                    CheckAdditionalCurrency(PostingDate, DtldEmplLedgEntry."Posting Date");
                    AddCurrChecked := true;
                end;
                if DtldEmplLedgEntry."Transaction No." <> 0 then begin
                    if DtldEmplLedgEntry."Entry Type" = DtldEmplLedgEntry."Entry Type"::Application then begin
                        LastTransactionNo :=
                          FindLastApplTransactionEntry(DtldEmplLedgEntry."Employee Ledger Entry No.");
                        if (LastTransactionNo <> 0) and (LastTransactionNo <> DtldEmplLedgEntry."Transaction No.") then
                            Error(UnapplyAllPostedAfterThisEntryErr, DtldEmplLedgEntry."Employee Ledger Entry No.");
                    end;
                    LastTransactionNo := FindLastTransactionNo(DtldEmplLedgEntry."Employee Ledger Entry No.");
                    if (LastTransactionNo <> 0) and (LastTransactionNo <> DtldEmplLedgEntry."Transaction No.") then
                        Error(LatestEntryMustBeApplicationErr, DtldEmplLedgEntry."Employee Ledger Entry No.");
                end;
            until DtldEmplLedgEntry.Next = 0;

        DateComprReg.CheckMaxDateCompressed(MaxPostingDate, 0);

        with DtldEmplLedgEntry2 do begin
            SourceCodeSetup.Get();
            EmplLedgEntry.Get("Employee Ledger Entry No.");
            GenJnlLine."Document No." := DocNo;
            GenJnlLine."Posting Date" := PostingDate;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Employee;
            GenJnlLine."Account No." := "Employee No.";
            GenJnlLine.Correction := true;
            GenJnlLine."Document Type" := "Document Type";
            GenJnlLine.Description := EmplLedgEntry.Description;
            GenJnlLine."Dimension Set ID" := EmplLedgEntry."Dimension Set ID";
            GenJnlLine."Shortcut Dimension 1 Code" := EmplLedgEntry."Global Dimension 1 Code";
            GenJnlLine."Shortcut Dimension 2 Code" := EmplLedgEntry."Global Dimension 2 Code";
            GenJnlLine."Source Type" := GenJnlLine."Source Type"::Employee;
            GenJnlLine."Source No." := "Employee No.";
            GenJnlLine."Source Code" := SourceCodeSetup."Unapplied Empl. Entry Appln.";
            GenJnlLine."Posting Group" := EmplLedgEntry."Employee Posting Group";
            GenJnlLine."Source Currency Code" := "Currency Code";
            GenJnlLine."System-Created Entry" := true;
            Window.Open(UnapplyingMsg);
            GenJnlPostLine.UnapplyEmplLedgEntry(GenJnlLine, DtldEmplLedgEntry2);

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

    procedure ApplyEmplEntryFormEntry(var ApplyingEmplLedgEntry: Record "Employee Ledger Entry")
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
        ApplyEmplEntries: Page "Apply Employee Entries";
        EmplEntryApplID: Code[50];
    begin
        if not ApplyingEmplLedgEntry.Open then
            Error(CannotApplyClosedEntriesErr);

        EmplEntryApplID := UserId;
        if EmplEntryApplID = '' then
            EmplEntryApplID := '***';
        if ApplyingEmplLedgEntry."Remaining Amount" = 0 then
            ApplyingEmplLedgEntry.CalcFields("Remaining Amount");

        ApplyingEmplLedgEntry."Applying Entry" := true;
        if ApplyingEmplLedgEntry."Applies-to ID" = '' then
            ApplyingEmplLedgEntry."Applies-to ID" := EmplEntryApplID;
        ApplyingEmplLedgEntry."Amount to Apply" := ApplyingEmplLedgEntry."Remaining Amount";
        CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", ApplyingEmplLedgEntry);
        Commit();

        EmplLedgEntry.SetCurrentKey("Employee No.", Open, Positive);
        EmplLedgEntry.SetRange("Employee No.", ApplyingEmplLedgEntry."Employee No.");
        EmplLedgEntry.SetRange(Open, true);
        if EmplLedgEntry.FindFirst then begin
            ApplyEmplEntries.SetEmplLedgEntry(ApplyingEmplLedgEntry);
            ApplyEmplEntries.SetRecord(EmplLedgEntry);
            ApplyEmplEntries.SetTableView(EmplLedgEntry);
            if ApplyingEmplLedgEntry."Applies-to ID" <> EmplEntryApplID then
                ApplyEmplEntries.SetAppliesToID(ApplyingEmplLedgEntry."Applies-to ID");
            ApplyEmplEntries.RunModal;
            Clear(ApplyEmplEntries);
            ApplyingEmplLedgEntry."Applying Entry" := false;
            ApplyingEmplLedgEntry."Applies-to ID" := '';
            ApplyingEmplLedgEntry."Amount to Apply" := 0;
        end;
    end;

    local procedure FindLastApplTransactionEntry(EmplLedgEntryNo: Integer): Integer
    var
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        LastTransactionNo: Integer;
    begin
        DtldEmplLedgEntry.SetCurrentKey("Employee Ledger Entry No.", "Entry Type");
        DtldEmplLedgEntry.SetRange("Employee Ledger Entry No.", EmplLedgEntryNo);
        DtldEmplLedgEntry.SetRange("Entry Type", DtldEmplLedgEntry."Entry Type"::Application);
        LastTransactionNo := 0;
        if DtldEmplLedgEntry.Find('-') then
            repeat
                if (DtldEmplLedgEntry."Transaction No." > LastTransactionNo) and not DtldEmplLedgEntry.Unapplied then
                    LastTransactionNo := DtldEmplLedgEntry."Transaction No.";
            until DtldEmplLedgEntry.Next = 0;
        exit(LastTransactionNo);
    end;

    procedure PreviewApply(EmployeeLedgerEntry: Record "Employee Ledger Entry"; DocumentNo: Code[20]; ApplicationDate: Date)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
    begin
        BindSubscription(EmplEntryApplyPostedEntries);
        EmplEntryApplyPostedEntries.SetApplyContext(ApplicationDate, DocumentNo);
        GenJnlPostPreview.Preview(EmplEntryApplyPostedEntries, EmployeeLedgerEntry);
    end;

    procedure PreviewUnapply(DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry"; DocumentNo: Code[20]; ApplicationDate: Date)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
    begin
        BindSubscription(EmplEntryApplyPostedEntries);
        EmplEntryApplyPostedEntries.SetUnapplyContext(DetailedEmployeeLedgEntry, ApplicationDate, DocumentNo);
        GenJnlPostPreview.Preview(EmplEntryApplyPostedEntries, EmployeeLedgerEntry);
    end;

    procedure SetApplyContext(ApplicationDate: Date; DocumentNo: Code[20])
    begin
        ApplicationDatePreviewContext := ApplicationDate;
        DocumentNoPreviewContext := DocumentNo;
        RunOptionPreviewContext := RunOptionPreview::Apply;
    end;

    procedure SetUnapplyContext(var DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry"; ApplicationDate: Date; DocumentNo: Code[20])
    begin
        ApplicationDatePreviewContext := ApplicationDate;
        DocumentNoPreviewContext := DocumentNo;
        DetailedEmployeeLedgEntryPreviewContext := DetailedEmployeeLedgEntry;
        RunOptionPreviewContext := RunOptionPreview::Unapply;
    end;

    [EventSubscriber(ObjectType::Codeunit, 19, 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
    begin
        EmplEntryApplyPostedEntries := Subscriber;
        PreviewMode := true;
        Result := EmplEntryApplyPostedEntries.Run(RecVar);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEmplPostApplyEmplLedgEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;
}

