report 5692 "Calculate Depreciation"
{
    AdditionalSearchTerms = 'write down fixed asset';
    ApplicationArea = FixedAssets;
    Caption = 'Calculate Depreciation';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "Budgeted Asset";

            trigger OnAfterGetRecord()
            begin
                if Inactive or Blocked or "Undepreciable FA" then
                    CurrReport.Skip();

                CalculateDepr.DepreciationBonus(DeprBonus);

                OnBeforeCalculateDepreciation(
                    "No.", TempGenJnlLine, TempFAJnlLine, DeprAmount, NumberOfDays, DeprBookCode, DeprUntilDate, EntryAmounts, DaysInPeriod);

                CalculateDepr.Calculate(
                    DeprAmount, Custom1Amount, NumberOfDays, Custom1NumberOfDays, "No.", DeprBookCode, DeprUntilDate, EntryAmounts, 0D, DaysInPeriod);

                if (DeprAmount <> 0) or (Custom1Amount <> 0) then
                    Window.Update(1, "No.")
                else
                    Window.Update(2, "No.");

                Custom1Amount := round(Custom1Amount, GeneralLedgerSetup."Amount Rounding Precision");
                DeprAmount := round(DeprAmount, GeneralLedgerSetup."Amount Rounding Precision");

                OnAfterCalculateDepreciation(
                    "No.", TempGenJnlLine, TempFAJnlLine, DeprAmount, NumberOfDays, DeprBookCode, DeprUntilDate, EntryAmounts, DaysInPeriod);

                if Custom1Amount <> 0 then
                    if not DeprBook."G/L Integration - Custom 1" or "Budgeted Asset" then begin
                        TempFAJnlLine."FA No." := "No.";
                        TempFAJnlLine."FA Posting Type" := TempFAJnlLine."FA Posting Type"::"Custom 1";
                        TempFAJnlLine.Amount := Custom1Amount;
                        TempFAJnlLine."No. of Depreciation Days" := Custom1NumberOfDays;
                        TempFAJnlLine."FA Error Entry No." := Custom1ErrorNo;
                        TempFAJnlLine."Line No." := TempFAJnlLine."Line No." + 1;
                        TempFAJnlLine."Location Code" := "FA Location Code";
                        TempFAJnlLine."Employee No." := "Responsible Employee";
                        TempFAJnlLine."Depr. Period Starting Date" := Period;
                        TempFAJnlLine."Tax Difference Code" := "Tax Difference Code";
                        TempFAJnlLine.Insert();
                    end else begin
                        TempGenJnlLine."Account No." := "No.";
                        TempGenJnlLine."FA Posting Type" := TempGenJnlLine."FA Posting Type"::"Custom 1";
                        TempGenJnlLine.Amount := Custom1Amount;
                        TempGenJnlLine."No. of Depreciation Days" := Custom1NumberOfDays;
                        TempGenJnlLine."FA Error Entry No." := Custom1ErrorNo;
                        TempGenJnlLine."Line No." := TempGenJnlLine."Line No." + 1;
                        TempGenJnlLine."FA Location Code" := "FA Location Code";
                        TempGenJnlLine."Employee No." := "Responsible Employee";
                        TempGenJnlLine."Depr. Period Starting Date" := Period;
                        TempGenJnlLine."Tax Difference Code" := "Tax Difference Code";
                        TempGenJnlLine.Insert();
                    end;

                if DeprAmount <> 0 then
                    if not DeprBook."G/L Integration - Depreciation" or "Budgeted Asset" then begin
                        TempFAJnlLine."FA No." := "No.";
                        TempFAJnlLine."FA Posting Type" := TempFAJnlLine."FA Posting Type"::Depreciation;
                        TempFAJnlLine.Amount := DeprAmount;
                        TempFAJnlLine."No. of Depreciation Days" := NumberOfDays;
                        TempFAJnlLine."FA Error Entry No." := ErrorNo;
                        TempFAJnlLine."Line No." := TempFAJnlLine."Line No." + 1;
                        TempFAJnlLine."Depr. Period Starting Date" := Period;
                        TempFAJnlLine."Location Code" := "FA Location Code";
                        TempFAJnlLine."Employee No." := "Responsible Employee";
                        TempFAJnlLine."Depr. Bonus" := DeprBonus;
                        TempFAJnlLine."Tax Difference Code" := "Tax Difference Code";
                        TempFAJnlLine.Insert();
                    end else begin
                        TempGenJnlLine."Account No." := "No.";
                        TempGenJnlLine."FA Posting Type" := TempGenJnlLine."FA Posting Type"::Depreciation;
                        TempGenJnlLine.Amount := DeprAmount;
                        TempGenJnlLine."No. of Depreciation Days" := NumberOfDays;
                        TempGenJnlLine."FA Error Entry No." := ErrorNo;
                        TempGenJnlLine."Line No." := TempGenJnlLine."Line No." + 1;
                        TempGenJnlLine."FA Location Code" := "FA Location Code";
                        TempGenJnlLine."Employee No." := "Responsible Employee";
                        TempGenJnlLine."Depr. Period Starting Date" := Period;
                        TempGenJnlLine."Depr. Bonus" := DeprBonus;
                        TempGenJnlLine."Tax Difference Code" := "Tax Difference Code";
                        TempGenJnlLine.Insert();
                    end;
            end;

            trigger OnPostDataItem()
            begin
                with FAJnlLine do begin
                    if TempFAJnlLine.Find('-') then begin
                        LockTable();
                        FAJnlSetup.FAJnlName(DeprBook, FAJnlLine, FAJnlNextLineNo);
                        NoSeries := FAJnlSetup.GetFANoSeries(FAJnlLine);
                        if DocumentNo = '' then
                            if FindLast() then
                                DocumentNo2 := "Document No."
                            else
                                DocumentNo2 := FAJnlSetup.GetFAJnlDocumentNo(FAJnlLine, DeprUntilDate, true)
                        else
                            DocumentNo2 := DocumentNo;
                    end;
                    if TempFAJnlLine.Find('-') then
                        repeat
                            Init;
                            "Line No." := 0;
                            FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
                            LineNo := LineNo + 1;
                            Window.Update(3, LineNo);
                            "Posting Date" := PostingDate;
                            "FA Posting Date" := DeprUntilDate;
                            if "Posting Date" = "FA Posting Date" then
                                "Posting Date" := 0D;
                            "FA Posting Type" := TempFAJnlLine."FA Posting Type";
                            Validate("FA No.", TempFAJnlLine."FA No.");
                            "Document No." := DocumentNo2;
                            "Posting No. Series" := NoSeries;
                            Description := PostingDescription;
                            Validate("Depreciation Book Code", DeprBookCode);
                            Validate(Amount, TempFAJnlLine.Amount);
                            "No. of Depreciation Days" := TempFAJnlLine."No. of Depreciation Days";
                            "FA Error Entry No." := TempFAJnlLine."FA Error Entry No.";
                            FAJnlNextLineNo := FAJnlNextLineNo + 10000;
                            "Line No." := FAJnlNextLineNo;
                            "Location Code" := TempFAJnlLine."Location Code";
                            "Employee No." := TempFAJnlLine."Employee No.";
                            "Depr. Period Starting Date" := TempFAJnlLine."Depr. Period Starting Date";
                            "Depr. Bonus" := TempFAJnlLine."Depr. Bonus";
                            "Tax Difference Code" := TempFAJnlLine."Tax Difference Code";
                            OnBeforeFAJnlLineInsert(TempFAJnlLine, FAJnlLine);
                            Insert(true);
                            FAJnlLineCreatedCount += 1;
                        until TempFAJnlLine.Next() = 0;
                end;

                with GenJnlLine do begin
                    if TempGenJnlLine.Find('-') then begin
                        LockTable();
                        FAJnlSetup.GenJnlName(DeprBook, GenJnlLine, GenJnlNextLineNo);
                        NoSeries := FAJnlSetup.GetGenNoSeries(GenJnlLine);
                        if DocumentNo = '' then
                            if FindLast() then
                                DocumentNo2 := "Document No."
                            else
                                DocumentNo2 := FAJnlSetup.GetGenJnlDocumentNo(GenJnlLine, DeprUntilDate, true)
                        else
                            DocumentNo2 := DocumentNo;
                    end;
                    if TempGenJnlLine.Find('-') then
                        repeat
                            Init;
                            "Line No." := 0;
                            FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
                            LineNo := LineNo + 1;
                            Window.Update(3, LineNo);
                            "Posting Date" := PostingDate;
                            "FA Posting Date" := DeprUntilDate;
                            if "Posting Date" = "FA Posting Date" then
                                "FA Posting Date" := 0D;
                            "FA Posting Type" := TempGenJnlLine."FA Posting Type";
                            "Account Type" := "Account Type"::"Fixed Asset";
                            Validate("Account No.", TempGenJnlLine."Account No.");
                            Description := PostingDescription;
                            "Document No." := DocumentNo2;
                            "Posting No. Series" := NoSeries;
                            Validate("Depreciation Book Code", DeprBookCode);
                            Validate(Amount, TempGenJnlLine.Amount);
                            "No. of Depreciation Days" := TempGenJnlLine."No. of Depreciation Days";
                            "FA Error Entry No." := TempGenJnlLine."FA Error Entry No.";
                            GenJnlNextLineNo := GenJnlNextLineNo + 1000;
                            "Line No." := GenJnlNextLineNo;
                            "Employee No." := TempGenJnlLine."Employee No.";
                            "FA Location Code" := TempGenJnlLine."FA Location Code";
                            "Depr. Period Starting Date" := TempGenJnlLine."Depr. Period Starting Date";
                            "Depr. Bonus" := TempGenJnlLine."Depr. Bonus";
                            "Tax Difference Code" := TempGenJnlLine."Tax Difference Code";
                            OnBeforeGenJnlLineInsert(TempGenJnlLine, GenJnlLine);
                            Insert(true);
                            GenJnlLineCreatedCount += 1;
                            if BalAccount then
                                FAInsertGLAcc.GetBalAcc(GenJnlLine, GenJnlNextLineNo);
                            OnAfterFAInsertGLAccGetBalAcc(GenJnlLine, GenJnlNextLineNo, BalAccount, TempGenJnlLine);
                        until TempGenJnlLine.Next() = 0;
                end;
                OnAfterPostDataItem();
            end;

            trigger OnPreDataItem()
            begin
                DeprBook.Get(DeprBookCode);
                if not (DeprBook."No. of Days in Fiscal Year" in [0, 360]) then
                    if not Confirm(Text12412, false, DeprBookCode, DeprBook."No. of Days in Fiscal Year") then
                        CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DepreciationBook; DeprBookCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the code for the depreciation book to be included in the report or batch job.';
                    }
                    field(AccountPeriod; AccountPeriod)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Accounting Period';
                        ToolTip = 'Specifies the accounting period to include data for.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            PeriodReportManagement.SelectPeriod(Text, CalendarPeriod, ProgressiveTotal);
                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, ProgressiveTotal);
                            RequestOptionsPage.Update;
                            exit(true);
                        end;

                        trigger OnValidate()
                        begin
                            if not PeriodReportManagement.ParseCaptionPeriodName(AccountPeriod, CalendarPeriod, ProgressiveTotal) then begin
                                PeriodReportManagement.InitPeriod(CalendarPeriod, 0);
                                PeriodReportManagement.SetCaptionPeriodYear(AccountPeriod, CalendarPeriod, ProgressiveTotal);
                            end;

                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, ProgressiveTotal);

                            Period := DatePeriod."Period Start";
                            SetProperties;
                        end;
                    }
                    field(From; DatePeriod."Period Start")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'From';
                        ToolTip = 'Specifies the starting point.';
                    }
                    field("To"; DatePeriod."Period End")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'To';
                        ToolTip = 'Specifies the ending point.';
                    }
                    field(Details; Details)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Change Details';
                    }
                    field(FAPostingDate; DeprUntilDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Posting Date';
                        Editable = Details;
                        Importance = Additional;
                        ToolTip = 'Specifies the fixed asset posting date to be used by the batch job. The batch job includes ledger entries up to this date. This date appears in the FA Posting Date field in the resulting journal lines. If the Use Same FA+G/L Posting Dates field has been activated in the depreciation book that is used in the batch job, then this date must be the same as the posting date entered in the Posting Date field.';

                        trigger OnValidate()
                        begin
                            DeprUntilDateModified := true;
                        end;
                    }
                    field(UseForceNoOfDays; UseForceNoOfDays)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Use Force No. of Days';
                        Editable = Details;
                        Importance = Additional;
                        ToolTip = 'Specifies if you want the program to use the number of days, as specified in the field below, in the depreciation calculation.';

                        trigger OnValidate()
                        begin
                            if not UseForceNoOfDays then
                                DaysInPeriod := 0;
                        end;
                    }
                    field(ForceNoOfDays; DaysInPeriod)
                    {
                        ApplicationArea = FixedAssets;
                        BlankZero = true;
                        Caption = 'Force No. of Days';
                        Editable = Details;
                        Importance = Additional;
                        MinValue = 0;
                        ToolTip = 'Specifies if you want the program to use the number of days, as specified in the field below, in the depreciation calculation.';

                        trigger OnValidate()
                        begin
                            if not UseForceNoOfDays and (DaysInPeriod <> 0) then
                                Error(Text006);
                        end;
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Posting Date';
                        Editable = Details;
                        ToolTip = 'Specifies the posting date to be used by the batch job.';

                        trigger OnValidate()
                        begin
                            if not DeprUntilDateModified then
                                DeprUntilDate := PostingDate;
                        end;
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Document No.';
                        Editable = Details;
                        ToolTip = 'Specifies, if you leave the field empty, the next available number on the resulting journal line. If a number series is not set up, enter the document number that you want assigned to the resulting journal line.';
                    }
                    field(PostingDescription; PostingDescription)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Posting Description';
                        Editable = Details;
                        ToolTip = 'Specifies the posting date to be used by the batch job as a filter.';
                    }
                    field(InsertBalAccount; BalAccount)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insert Bal. Account';
                        Editable = Details;
                        Importance = Additional;
                        ToolTip = 'Specifies if you want the batch job to automatically insert fixed asset entries with balancing accounts.';
                    }
                    field(DeprBonus; DeprBonus)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Calc. Depr. Bonus';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PeriodReportManagement.InitPeriod(CalendarPeriod, 0);
            PeriodReportManagement.SetCaptionPeriodYear(AccountPeriod, CalendarPeriod, ProgressiveTotal);
            DatePeriod.Copy(CalendarPeriod);
            PeriodReportManagement.PeriodSetup(DatePeriod, ProgressiveTotal);

            BalAccount := true;
            PostingDate := WorkDate;
            DeprUntilDate := WorkDate;
            if DeprBookCode = '' then begin
                FASetup.Get();
                DeprBookCode := GetDeprBookCode;
            end;

            Period := DatePeriod."Period Start";
            SetProperties;

            UseForceNoOfDays := true;
            DaysInPeriod := 30;
            Details := false;

            if not UseForceNoOfDays then
                DaysInPeriod := 0;

            DeprBonus := false;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        OnBeforeOnInitReport(DeprBookCode);
    end;

    trigger OnPostReport()
    var
        PageGenJnlLine: Record "Gen. Journal Line";
        PageFAJnlLine: Record "FA Journal Line";
        IsHandled: Boolean;
    begin
        Window.Close;
        if (FAJnlLineCreatedCount = 0) and (GenJnlLineCreatedCount = 0) then begin
            Message(CompletionStatsMsg);
            exit;
        end;

        if FAJnlLineCreatedCount > 0 then begin
            IsHandled := false;
            OnPostReportOnBeforeConfirmShowFAJournalLines(DeprBook, FAJnlLine, FAJnlLineCreatedCount, IsHandled);
            if not IsHandled then
                Message(CompletionStatsFAJnlMsg, FAJnlLineCreatedCount);
        end;

        if GenJnlLineCreatedCount > 0 then begin
            IsHandled := false;
            OnPostReportOnBeforeConfirmShowGenJournalLines(DeprBook, GenJnlLine, GenJnlLineCreatedCount, IsHandled);
            if not IsHandled then
                Message(CompletionStatsGenJnlMsg, GenJnlLineCreatedCount);
        end;

        OnAfterOnPostReport();
    end;

    trigger OnPreReport()
    begin
        DeprBook.Get(DeprBookCode);
        if DeprUntilDate = 0D then
            Error(Text000, FAJnlLine.FieldCaption("FA Posting Date"));
        if PostingDate = 0D then
            PostingDate := DeprUntilDate;
        if UseForceNoOfDays and (DaysInPeriod = 0) then
            Error(Text001);

        if DeprBook."Use Same FA+G/L Posting Dates" and (DeprUntilDate <> PostingDate) then
            Error(
              Text002,
              FAJnlLine.FieldCaption("FA Posting Date"),
              FAJnlLine.FieldCaption("Posting Date"),
              DeprBook.FieldCaption("Use Same FA+G/L Posting Dates"),
              false,
              DeprBook.TableCaption,
              DeprBook.FieldCaption(Code),
              DeprBook.Code);

        Window.Open(
          Text003 +
          Text004 +
          Text005);
    end;

    var
        Text000: Label 'You must specify %1.';
        Text001: Label 'Force No. of Days must be activated.';
        Text002: Label '%1 and %2 must be identical. %3 must be %4 in %5 %6 = %7.';
        Text003: Label 'Depreciating fixed asset      #1##########\';
        Text004: Label 'Not depreciating fixed asset  #2##########\';
        Text005: Label 'Inserting journal lines       #3##########';
        Text006: Label 'Use Force No. of Days must be activated.';
        GenJnlLine: Record "Gen. Journal Line";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        FASetup: Record "FA Setup";
        FAJnlLine: Record "FA Journal Line";
        TempFAJnlLine: Record "FA Journal Line" temporary;
        DeprBook: Record "Depreciation Book";
        FAJnlSetup: Record "FA Journal Setup";
        GLSetup: Record "General Ledger Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CalculateDepr: Codeunit "Calculate Depreciation";
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";
        Window: Dialog;
        DeprAmount: Decimal;
        Custom1Amount: Decimal;
        NumberOfDays: Integer;
        Custom1NumberOfDays: Integer;
        DeprUntilDate: Date;
        UseForceNoOfDays: Boolean;
        DaysInPeriod: Integer;
        PostingDate: Date;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        NoSeries: Code[20];
        PostingDescription: Text[100];
        DeprBookCode: Code[10];
        BalAccount: Boolean;
        ErrorNo: Integer;
        Custom1ErrorNo: Integer;
        FAJnlNextLineNo: Integer;
        GenJnlNextLineNo: Integer;
        EntryAmounts: array[4] of Decimal;
        LineNo: Integer;
        Period: Date;
        Text12407: Label 'FA Posting Date must be into Accounting Period';
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        ChangeDate: Page "Select Reporting Period";
        PeriodReportManagement: Codeunit PeriodReportManagement;
        StdRepManagement: Codeunit "Localisation Management";
        AccountPeriod: Text[30];
        ProgressiveTotal: Boolean;
        Text12408: Label 'You must create Accounting Period when Starting Date is %1 ';
        Text12409: Label 'Posting Date must be into Accounting Period';
        Details: Boolean;
        Text12411: Label 'DP-';
        Text12410: Label ' FA Depreciation';
        Text12412: Label 'No. of Days in Fiscal Year for Depr. Book %1 = %2 will calculate incorrect depreciation amounts. Continue?';
        DeprBonus: Boolean;
        CompletionStatsMsg: Label 'The depreciation has been calculated.\\No journal lines were created.';
        FAJnlLineCreatedCount: Integer;
        GenJnlLineCreatedCount: Integer;
        CompletionStatsFAJnlMsg: Label 'The depreciation has been calculated.\\%1 fixed asset journal lines were created.', Comment = 'The depreciation has been calculated.\\5 fixed asset journal lines were created.';
        CompletionStatsGenJnlMsg: Label 'The depreciation has been calculated.\\%1 fixed asset G/L journal lines were created.', Comment = 'The depreciation has been calculated.\\2 fixed asset G/L journal lines were created.';
        DeprUntilDateModified: Boolean;

    [Scope('OnPrem')]
    procedure SetProperties()
    begin
        PostingDate := DatePeriod."Period End";
        DeprUntilDate := DatePeriod."Period End";
        PostingDescription :=
          Format(DatePeriod."Period Start", 0, '<Month Text> ') +
          Format(Date2DMY(DatePeriod."Period Start", 3)) +
          Text12410;
        if Date2DMY(DatePeriod."Period Start", 2) > 9 then
            DocumentNo := Text12411 + Format(DatePeriod."Period Start", 0, '<Year>-<Month>')
        else
            DocumentNo := Text12411 + Format(DatePeriod."Period Start", 2, '<Year>') + '-0' + Format(DatePeriod."Period Start", 0, '<Month>');
    end;

    procedure InitializeRequest(DeprBookCodeFrom: Code[10]; DeprUntilDateFrom: Date; UseForceNoOfDaysFrom: Boolean; DaysInPeriodFrom: Integer; PostingDateFrom: Date; DocumentNoFrom: Code[20]; PostingDescriptionFrom: Text[100]; BalAccountFrom: Boolean)
    begin
        DeprBookCode := DeprBookCodeFrom;
        DeprUntilDate := DeprUntilDateFrom;
        UseForceNoOfDays := UseForceNoOfDaysFrom;
        DaysInPeriod := DaysInPeriodFrom;
        PostingDate := PostingDateFrom;
        DocumentNo := DocumentNoFrom;
        PostingDescription := PostingDescriptionFrom;
        BalAccount := BalAccountFrom;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest2(NewDeprBookCode: Code[10]; NewPostingDate: Date; NewDeprUntilDate: Date; NewDocumentNo: Code[20]; NewPostingDescription: Text[100]; NewUseForceNoOfDays: Boolean; NewDaysInPeriod: Integer; NewBalAccount: Boolean; ChangeDetails: Boolean; NewDeprBonus: Boolean)
    begin
        ClearAll;
        DeprBookCode := NewDeprBookCode;
        PostingDate := NewPostingDate;
        DocumentNo := NewDocumentNo;
        PostingDescription := NewPostingDescription;
        DeprBonus := NewDeprBonus;

        if ChangeDetails then begin
            DeprUntilDate := NewDeprUntilDate;
            UseForceNoOfDays := NewUseForceNoOfDays;
            DaysInPeriod := NewDaysInPeriod;
            BalAccount := NewBalAccount;
        end else begin
            DeprUntilDate := NewPostingDate;
            UseForceNoOfDays := true;
            DaysInPeriod := 30;
            BalAccount := true;
        end;
    end;

    local procedure GetDeprBookCode(): Code[10]
    begin
        GLSetup.Get();
        if GLSetup."Enable Russian Accounting" then
            exit(FASetup."Release Depr. Book");
        exit(FASetup."Default Depr. Book");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateDepreciation(FANo: Code[20]; var TempGenJournalLine: Record "Gen. Journal Line" temporary; var TempFAJournalLine: Record "FA Journal Line" temporary; var DeprAmount: Decimal; var NumberOfDays: Integer; DeprBookCode: Code[10]; DeprUntilDate: Date; EntryAmounts: array[4] of Decimal; DaysInPeriod: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFAInsertGLAccGetBalAcc(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlNextLineNo: Integer; var BalAccount: Boolean; var TempGenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostDataItem()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPostReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateDepreciation(FANo: Code[20]; var TempGenJournalLine: Record "Gen. Journal Line" temporary; var TempFAJournalLine: Record "FA Journal Line" temporary; var DeprAmount: Decimal; var NumberOfDays: Integer; DeprBookCode: Code[10]; DeprUntilDate: Date; EntryAmounts: array[4] of Decimal; DaysInPeriod: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFAJnlLineInsert(var TempFAJournalLine: Record "FA Journal Line" temporary; var FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInitReport(var DeprBookCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReportOnBeforeConfirmShowFAJournalLines(DeprBook: Record "Depreciation Book"; FAJnlLine: Record "FA Journal Line"; FAJnlLineCreatedCount: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReportOnBeforeConfirmShowGenJournalLines(DeprBook: Record "Depreciation Book"; GenJnlLine: Record "Gen. Journal Line"; GenJnlLineCreatedCount: Integer; var IsHandled: Boolean)
    begin
    end;
}

