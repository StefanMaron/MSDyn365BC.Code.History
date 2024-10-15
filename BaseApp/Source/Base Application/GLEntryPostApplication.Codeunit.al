codeunit 11766 "G/L Entry -Post Application"
{
    Permissions = TableData "G/L Entry" = rm,
                  TableData "Detailed G/L Entry" = rim;

    trigger OnRun()
    begin
    end;

    var
        Text11701: Label '%1 No. %2 does not have an application entry.';
        GLEntry: Record "G/L Entry";
        Text11702: Label 'The entered %1 must not precede the latest %2 on %3.';
        Text11703: Label 'There is nothing to apply.';
        Text11704: Label 'An entered %1 must not precede the %1 of application.';
        Text11705: Label 'To unapply this entry, you must first unapply all application entries in %1 No. %2 that were posted after this entry.';
        Text11706: Label 'Posting application...';
        Text11707: Label 'The application has been successfully posted.';
        Text11708: Label 'To unapply these entries, the program will post correcting entries. Do you want to unapply the entries?';
        Text11709: Label 'The entries have been successfully unapplied.';
        ApplyingAmount: Decimal;
        NotUseDialog: Boolean;
        SignAmtMustBediffErr: Label 'Sign amounts of entries must be different.';
        ClosedEntryErr: Label 'One or more of the entries that you selected is closed.\You cannot apply closed entries.';

    [Scope('OnPrem')]
    procedure PostApplyGLEntry(var ApplyingEntry: Record "G/L Entry")
    var
        DtldGLEntry: Record "Detailed G/L Entry";
        PostApplication: Page "Post Application";
        Window: Dialog;
        DocumentNo: Code[20];
        PostingDate: Date;
        ApplicationDate: Date;
        TransactionNo: Integer;
        lboIsZero: Boolean;
    begin
        with GLEntry do begin
            CalcFields("Applied Amount");
            SetCurrentKey("Entry No.");
            SetRange("Applies-to ID", ApplyingEntry."Applies-to ID");
            SetRange("G/L Account No.", ApplyingEntry."G/L Account No.");

            if FindSet then
                repeat
                    if ApplyingEntry."Entry No." <> "Entry No." then
                        if "Amount to Apply" <> 0 then
                            if (Amount * ApplyingEntry.Amount) > 0 then
                                Error(SignAmtMustBediffErr);
                    if "Posting Date" > PostingDate then
                        PostingDate := "Posting Date"
                until Next = 0;

            DocumentNo := ApplyingEntry."Document No.";
            if not NotUseDialog then begin
                PostApplication.SetValues(DocumentNo, PostingDate);
                PostApplication.LookupMode(true);
                Commit();
                if ACTION::LookupOK = PostApplication.RunModal then begin
                    PostApplication.GetValues(DocumentNo, ApplicationDate);
                    if ApplicationDate < PostingDate then
                        Error(
                          Text11702,
                          FieldCaption("Posting Date"), FieldCaption("Posting Date"), TableCaption);
                end else
                    exit;

                Window.Open(Text11706);
            end else
                ApplicationDate := PostingDate;

            ApplyingAmount := 0;
            if FindSet then
                repeat
                    ApplyingAmount := ApplyingAmount + "Amount to Apply";
                    if Amount = 0 then begin
                        lboIsZero := true;
                        "Closed at Date" := ApplicationDate;
                        Closed := true;
                        "Applying Entry" := false;
                        "Amount to Apply" := 0;
                        "Applies-to ID" := '';
                        Modify;
                    end;
                until Next = 0;

            if ApplyingAmount <> 0 then begin
                if ApplyingAmount > 0 then
                    SetFilter(Amount, '>0')
                else
                    SetFilter(Amount, '<0');
                SetRange("Applying Entry", false);
                if Find('+') then
                    repeat
                        if (ApplyingAmount <> 0) and
                           (Amount = "Amount to Apply" + "Applied Amount")
                        then begin
                            SetAmountToApply;
                            Modify;
                        end;
                    until Next(-1) = 0;

                if ApplyingAmount <> 0 then begin
                    SetFilter("Amount to Apply", '<>0');
                    if Find('+') then
                        repeat
                            SetAmountToApply;
                            Modify;
                        until Next(-1) = 0;
                end;

                if ApplyingAmount <> 0 then begin
                    SetRange("Applying Entry", true);
                    if FindFirst then begin
                        "Amount to Apply" := "Amount to Apply" - ApplyingAmount;
                        ApplyingAmount := 0;
                        Modify;
                    end;
                end;
            end;

            Reset;
            SetRange("Applies-to ID", ApplyingEntry."Applies-to ID");
            SetRange("G/L Account No.", ApplyingEntry."G/L Account No.");
            SetRange("Amount to Apply", 0);
            ModifyAll("Applies-to ID", '');

            TransactionNo := FindLastTransactionNo + 1;

            Reset;
            SetRange("Applies-to ID", ApplyingEntry."Applies-to ID");
            SetRange("G/L Account No.", ApplyingEntry."G/L Account No.");
            if FindSet(true, false) then begin
                repeat
                    DtldGLEntry.Init();
                    DtldGLEntry."Entry No." := FindLastDtldGLEntryNo + 1;
                    DtldGLEntry."G/L Entry No." := "Entry No.";
                    DtldGLEntry."Applied G/L Entry No." := ApplyingEntry."Entry No.";
                    DtldGLEntry."G/L Account No." := "G/L Account No.";
                    DtldGLEntry."Posting Date" := ApplicationDate;
                    DtldGLEntry."Document No." := DocumentNo;
                    DtldGLEntry."Transaction No." := TransactionNo;
                    DtldGLEntry.Amount := -"Amount to Apply";
                    if NotUseDialog then
                        DtldGLEntry."User ID" := UserId
                    else
                        DtldGLEntry."User ID" := "Applies-to ID";
                    DtldGLEntry.Insert();
                    CalcFields("Applied Amount");
                    if "Applied Amount" = Amount then begin
                        "Closed at Date" := ApplicationDate;
                        Closed := true;
                    end;
                    "Applying Entry" := false;
                    "Amount to Apply" := 0;
                    "Applies-to ID" := '';
                    Modify;
                until Next = 0;
            end else
                if not NotUseDialog then
                    if not lboIsZero then begin
                        Window.Close;
                        Error(Text11703);
                    end;
            if not NotUseDialog then begin
                Commit();
                Window.Close;
                Message(Text11707);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure PostUnApplyGLEntry(var DtldGLEntry: Record "Detailed G/L Entry"; DocumentNo: Code[20]; PostingDate: Date)
    var
        DtldGLEntry2: Record "Detailed G/L Entry";
        DtldGLEntry3: Record "Detailed G/L Entry";
        Window: Dialog;
        ApplicationEntryNo: Integer;
        TransactionNo: Integer;
        UnapplidedByEntryNo: Integer;
    begin
        with DtldGLEntry2 do begin
            SetCurrentKey("Entry No.");
            SetRange("Transaction No.", DtldGLEntry."Transaction No.");
            SetRange("G/L Account No.", DtldGLEntry."G/L Account No.");

            if PostingDate < DtldGLEntry."Posting Date" then
                Error(Text11704, FieldCaption("Posting Date"));

            if FindSet then
                repeat
                    ApplicationEntryNo := FindLastApplEntry("G/L Entry No.");
                    if (ApplicationEntryNo <> 0) and (ApplicationEntryNo <> "Entry No.") then
                        Error(Text11705, GLEntry.TableCaption, "G/L Entry No.");
                until Next = 0;

            if not NotUseDialog then begin
                if Confirm(Text11708) then
                    Window.Open(Text11706)
                else
                    Error('');
            end;

            TransactionNo := FindLastTransactionNo + 1;
            if FindSet then
                repeat
                    DtldGLEntry3.Init();
                    DtldGLEntry3."Entry No." := FindLastDtldGLEntryNo + 1;
                    UnapplidedByEntryNo := DtldGLEntry3."Entry No.";
                    DtldGLEntry3."G/L Entry No." := "G/L Entry No.";
                    DtldGLEntry3."Applied G/L Entry No." := "Applied G/L Entry No.";
                    DtldGLEntry3."G/L Account No." := "G/L Account No.";
                    DtldGLEntry3."Posting Date" := PostingDate;
                    DtldGLEntry3."Document No." := DocumentNo;
                    DtldGLEntry3."Transaction No." := TransactionNo;
                    DtldGLEntry3.Unapplied := true;
                    DtldGLEntry3."Unapplied by Entry No." := "Entry No.";
                    DtldGLEntry3.Amount := -Amount;
                    if UserId = '' then
                        DtldGLEntry3."User ID" := '***'
                    else
                        DtldGLEntry3."User ID" := UserId;
                    DtldGLEntry3.Insert();
                    DtldGLEntry3.Get("Entry No.");
                    DtldGLEntry3.Unapplied := true;
                    DtldGLEntry3."Unapplied by Entry No." := UnapplidedByEntryNo;
                    DtldGLEntry3.Modify();
                    GLEntry.Get("G/L Entry No.");
                    GLEntry."Closed at Date" := 0D;
                    GLEntry.Closed := false;
                    GLEntry.Modify();
                until Next = 0;
            if not NotUseDialog then begin
                Commit();
                Window.Close;
                Message(Text11709);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UnApplyGLEntry(GLEntryNo: Integer)
    var
        DtldGLEntry: Record "Detailed G/L Entry";
        ApplicationEntryNo: Integer;
    begin
        GLEntry.Get(GLEntryNo);
        if (GLEntry.Amount = 0) and GLEntry.Closed then begin
            if Confirm(Text11708) then begin
                GLEntry."Closed at Date" := 0D;
                GLEntry.Closed := false;
                GLEntry.Modify();
            end;
            exit;
        end;

        ApplicationEntryNo := FindLastApplEntry(GLEntryNo);
        if ApplicationEntryNo = 0 then
            Error(Text11701, GLEntry.TableCaption, GLEntryNo);
        DtldGLEntry.Get(ApplicationEntryNo);
        UnApplyGL(DtldGLEntry);
    end;

    local procedure FindLastApplEntry(GLEntryNo: Integer): Integer
    var
        DtldGLEntry: Record "Detailed G/L Entry";
        ApplicationEntryNo: Integer;
    begin
        DtldGLEntry.SetCurrentKey("Entry No.");
        DtldGLEntry.SetRange("G/L Entry No.", GLEntryNo);
        ApplicationEntryNo := 0;
        if DtldGLEntry.FindSet then
            repeat
                if (DtldGLEntry."Entry No." > ApplicationEntryNo) and not DtldGLEntry.Unapplied then
                    ApplicationEntryNo := DtldGLEntry."Entry No.";
            until DtldGLEntry.Next = 0;
        exit(ApplicationEntryNo);
    end;

    local procedure UnApplyGL(DtldGLEntry: Record "Detailed G/L Entry")
    var
        UnapplyGLEntries: Page "Unapply General Ledger Entries";
    begin
        with DtldGLEntry do begin
            TestField(Unapplied, false);
            UnapplyGLEntries.SetDtldGLEntry("Entry No.");
            UnapplyGLEntries.LookupMode(true);
            UnapplyGLEntries.RunModal;
        end;
    end;

    local procedure FindLastTransactionNo() TransactionNo: Integer
    var
        DtldGLEntry: Record "Detailed G/L Entry";
    begin
        if DtldGLEntry.FindLast then
            TransactionNo := DtldGLEntry."Transaction No."
        else
            TransactionNo := 0;
    end;

    local procedure FindLastDtldGLEntryNo() DtldGLEntryNo: Integer
    var
        DtldGLEntry: Record "Detailed G/L Entry";
    begin
        if DtldGLEntry.FindLast then
            DtldGLEntryNo := DtldGLEntry."Entry No."
        else
            DtldGLEntryNo := 0;
    end;

    [Scope('OnPrem')]
    procedure SetAmountToApply()
    begin
        with GLEntry do
            if Abs("Amount to Apply") - Abs(ApplyingAmount) <= 0 then begin
                ApplyingAmount := ApplyingAmount - "Amount to Apply";
                "Amount to Apply" := 0;
            end else begin
                "Amount to Apply" := "Amount to Apply" - ApplyingAmount;
                ApplyingAmount := 0;
            end;
    end;

    [Scope('OnPrem')]
    procedure SetApplyingGLEntry(var GLEntry: Record "G/L Entry"; Set: Boolean; GLApplID: Code[50])
    begin
        with GLEntry do begin
            "Applying Entry" := Set;
            if Set or (("Applies-to ID" = '') and not Set) then begin
                CalcFields("Applied Amount");
                "Applies-to ID" := GLApplID;
                "Amount to Apply" := Amount - "Applied Amount";
            end else begin
                "Applies-to ID" := '';
                "Amount to Apply" := 0;
            end;
            Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure NotUseRequestForm()
    begin
        NotUseDialog := true;
    end;

    [Scope('OnPrem')]
    procedure xApplyEntryformEntry(var ApplGLEntry: Record "G/L Entry")
    var
        ApplGenLedgEntries: Page "Apply General Ledger Entries";
        GLEntries: Record "G/L Entry";
        EntryApplID: Code[50];
    begin
        if ApplGLEntry.Closed then
            Error(ClosedEntryErr);

        EntryApplID := UserId;
        if EntryApplID = '' then
            EntryApplID := '***';

        GLEntries.SetCurrentKey("G/L Account No.");
        GLEntries.SetRange("G/L Account No.", ApplGLEntry."G/L Account No.");
        GLEntries.SetRange(Closed, false);
        ApplGenLedgEntries.SetAplEntry(ApplGLEntry."Entry No.");
        ApplGenLedgEntries.SetTableView(GLEntries);
        if ApplGenLedgEntries.RunModal = ACTION::LookupOK then;
        Clear(ApplGenLedgEntries);
    end;
}

