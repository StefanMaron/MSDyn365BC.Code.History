﻿namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Setup;
using System.Environment;
using System.Utilities;

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
                if GuiAllowed() then
                    if (DeprAmount <> 0) or (Custom1Amount <> 0) then
                        Window.Update(1, "No.")
                    else
                        Window.Update(2, "No.");

                Custom1Amount := Round(Custom1Amount, GeneralLedgerSetup."Amount Rounding Precision");
                DeprAmount := Round(DeprAmount, GeneralLedgerSetup."Amount Rounding Precision");

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
            var
                NeedCommit: Boolean;
            begin
                if TempFAJnlLine.Find('-') then begin
                    NeedCommit := true;
                    FAJnlLine.LockTable();
                    FAJnlSetup.FAJnlName(DeprBook, FAJnlLine, FAJnlNextLineNo);
                    NoSeries := FAJnlSetup.GetFANoSeries(FAJnlLine);
                    if DocumentNo = '' then
                        if FAJnlLine.FindLast() then
                            AutoDocumentNo := FAJnlLine."Document No."
                        else
                            AutoDocumentNo := FAJnlSetup.GetFAJnlDocumentNo(FAJnlLine, DeprUntilDate, true)
                    else
                        AutoDocumentNo := DocumentNo;
                end;
                if TempFAJnlLine.Find('-') then
                    repeat
                        FAJnlLine.Init();
                        FAJnlLine."Line No." := 0;
                        FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
                        LineNo := LineNo + 1;
                        if GuiAllowed() then
                            Window.Update(3, LineNo);
                        FAJnlLine."Posting Date" := PostingDate;
                        FAJnlLine."FA Posting Date" := DeprUntilDate;
                        if FAJnlLine."Posting Date" = FAJnlLine."FA Posting Date" then
                            FAJnlLine."Posting Date" := 0D;
                        FAJnlLine."FA Posting Type" := TempFAJnlLine."FA Posting Type";
                        FAJnlLine.Validate("FA No.", TempFAJnlLine."FA No.");
                        FAJnlLine."Document No." := AutoDocumentNo;
                        FAJnlLine."Posting No. Series" := NoSeries;
                        FAJnlLine.Description := PostingDescription;
                        FAJnlLine.Validate("Depreciation Book Code", DeprBookCode);
                        FAJnlLine.Validate(Amount, TempFAJnlLine.Amount);
                        FAJnlLine."No. of Depreciation Days" := TempFAJnlLine."No. of Depreciation Days";
                        FAJnlLine."FA Error Entry No." := TempFAJnlLine."FA Error Entry No.";
                        FAJnlNextLineNo := FAJnlNextLineNo + 10000;
                        FAJnlLine."Line No." := FAJnlNextLineNo;
                        FAJnlLine."Location Code" := TempFAJnlLine."Location Code";
                        FAJnlLine."Employee No." := TempFAJnlLine."Employee No.";
                        FAJnlLine."Depr. Period Starting Date" := TempFAJnlLine."Depr. Period Starting Date";
                        FAJnlLine."Depr. Bonus" := TempFAJnlLine."Depr. Bonus";
                        FAJnlLine."Tax Difference Code" := TempFAJnlLine."Tax Difference Code";
                        OnBeforeFAJnlLineInsert(TempFAJnlLine, FAJnlLine);
                        FAJnlLine.Insert(true);
                        FAJnlLineCreatedCount += 1;
                    until TempFAJnlLine.Next() = 0;

                if TempGenJnlLine.Find('-') then begin
                    NeedCommit := true;
                    GenJnlLine.LockTable();
                    FAJnlSetup.GenJnlName(DeprBook, GenJnlLine, GenJnlNextLineNo);
                    NoSeries := FAJnlSetup.GetGenNoSeries(GenJnlLine);
                    if DocumentNo = '' then
                        if GenJnlLine.FindLast() then
                            AutoDocumentNo := GenJnlLine."Document No."
                        else
                            AutoDocumentNo := FAJnlSetup.GetGenJnlDocumentNo(GenJnlLine, DeprUntilDate, true)
                    else
                        AutoDocumentNo := DocumentNo;
                end;
                if TempGenJnlLine.Find('-') then
                    repeat
                        GenJnlLine.Init();
                        OnBeforeGenJnlLineCreate(TempGenJnlLine, GenJnlLine);
                        GenJnlLine."Line No." := 0;
                        FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
                        LineNo := LineNo + 1;
                        if GuiAllowed() then
                            Window.Update(3, LineNo);
                        GenJnlLine."Posting Date" := PostingDate;
                        GenJnlLine."FA Posting Date" := DeprUntilDate;
                        if GenJnlLine."Posting Date" = GenJnlLine."FA Posting Date" then
                            GenJnlLine."FA Posting Date" := 0D;
                        GenJnlLine."FA Posting Type" := TempGenJnlLine."FA Posting Type";
                        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
                        GenJnlLine.Validate("Account No.", TempGenJnlLine."Account No.");
                        GenJnlLine.Description := PostingDescription;
                        GenJnlLine."Document No." := AutoDocumentNo;
                        GenJnlLine."Posting No. Series" := NoSeries;
                        GenJnlLine.Validate("Depreciation Book Code", DeprBookCode);
                        GenJnlLine.Validate(Amount, TempGenJnlLine.Amount);
                        GenJnlLine."No. of Depreciation Days" := TempGenJnlLine."No. of Depreciation Days";
                        GenJnlLine."FA Error Entry No." := TempGenJnlLine."FA Error Entry No.";
                        GenJnlNextLineNo := GenJnlNextLineNo + 1000;
                        GenJnlLine."Line No." := GenJnlNextLineNo;
                        GenJnlLine."Employee No." := TempGenJnlLine."Employee No.";
                        GenJnlLine."FA Location Code" := TempGenJnlLine."FA Location Code";
                        GenJnlLine."Depr. Period Starting Date" := TempGenJnlLine."Depr. Period Starting Date";
                        GenJnlLine."Depr. Bonus" := TempGenJnlLine."Depr. Bonus";
                        GenJnlLine."Tax Difference Code" := TempGenJnlLine."Tax Difference Code";
                        OnBeforeGenJnlLineInsert(TempGenJnlLine, GenJnlLine);
                        GenJnlLine.Insert(true);
                        GenJnlLineCreatedCount += 1;
                        if BalAccount then
                            FAInsertGLAcc.GetBalAcc(GenJnlLine, GenJnlNextLineNo);
                        OnAfterFAInsertGLAccGetBalAcc(GenJnlLine, GenJnlNextLineNo, BalAccount, TempGenJnlLine);
                    until TempGenJnlLine.Next() = 0;
                OnAfterPostDataItem();
                if NeedCommit then
                    Commit();
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
                            RequestOptionsPage.Update();
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
                            SetProperties();
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
        var
            ClientTypeManagement: Codeunit "Client Type Management";
        begin
            PeriodReportManagement.InitPeriod(CalendarPeriod, 0);
            PeriodReportManagement.SetCaptionPeriodYear(AccountPeriod, CalendarPeriod, ProgressiveTotal);
            DatePeriod.Copy(CalendarPeriod);
            PeriodReportManagement.PeriodSetup(DatePeriod, ProgressiveTotal);

            BalAccount := true;
            if ClientTypeManagement.GetCurrentClientType() <> CLIENTTYPE::Background then begin
                PostingDate := WorkDate();
                DeprUntilDate := WorkDate();
            end;
            if DeprBookCode = '' then begin
                FASetup.Get();
                DeprBookCode := GetDeprBookCode();
            end;

            Period := DatePeriod."Period Start";
            SetProperties();

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
        IsHandled: Boolean;
    begin
        if ErrorMessageHandler.HasErrors() then
            if ErrorMessageHandler.ShowErrors() then
                Error('');
        if GuiAllowed() then
            Window.Close();
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
        ActivateErrorMessageHandling("Fixed Asset");

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
              DeprBook.TableCaption(),
              DeprBook.FieldCaption(Code),
              DeprBook.Code);
        if GuiAllowed() then
            Window.Open(Text003 + Text004 + Text005);
    end;

    var
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
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        Window: Dialog;
        DeprAmount: Decimal;
        Custom1Amount: Decimal;
        NumberOfDays: Integer;
        Custom1NumberOfDays: Integer;
        AutoDocumentNo: Code[20];
        NoSeries: Code[20];
        ErrorNo: Integer;
        Custom1ErrorNo: Integer;
        FAJnlNextLineNo: Integer;
        GenJnlNextLineNo: Integer;
        EntryAmounts: array[4] of Decimal;
        LineNo: Integer;
        FAJnlLineCreatedCount: Integer;
        GenJnlLineCreatedCount: Integer;
        DeprUntilDateModified: Boolean;
        Period: Date;
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        PeriodReportManagement: Codeunit PeriodReportManagement;
        AccountPeriod: Text[30];
        ProgressiveTotal: Boolean;
        DeprBonus: Boolean;

        Text000: Label 'You must specify %1.';
        Text001: Label 'Force No. of Days must be activated.';
        Text002: Label '%1 and %2 must be identical. %3 must be %4 in %5 %6 = %7.';
        Text003: Label 'Depreciating fixed asset      #1##########\';
        Text004: Label 'Not depreciating fixed asset  #2##########\';
        Text005: Label 'Inserting journal lines       #3##########';
        Text006: Label 'Use Force No. of Days must be activated.';
        Details: Boolean;
        Text12411: Label 'DP-';
        Text12410: Label ' FA Depreciation';
        Text12412: Label 'No. of Days in Fiscal Year for Depr. Book %1 = %2 will calculate incorrect depreciation amounts. Continue?';
        CompletionStatsMsg: Label 'The depreciation has been calculated.\\No journal lines were created.';
        CompletionStatsFAJnlMsg: Label 'The depreciation has been calculated.\\%1 fixed asset journal lines were created.', Comment = 'The depreciation has been calculated.\\5 fixed asset journal lines were created.';
        CompletionStatsGenJnlMsg: Label 'The depreciation has been calculated.\\%1 fixed asset G/L journal lines were created.', Comment = 'The depreciation has been calculated.\\2 fixed asset G/L journal lines were created.';

    protected var
        DeprBookCode: Code[10];
        DeprUntilDate: Date;
        UseForceNoOfDays: Boolean;
        DaysInPeriod: Integer;
        PostingDate: Date;
        DocumentNo: Code[20];
        PostingDescription: Text[100];
        BalAccount: Boolean;

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

    local procedure ActivateErrorMessageHandling(var FixedAsset: Record "Fixed Asset")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeActivateErrorMessageHandling(FixedAsset, ErrorMessageMgt, ErrorMessageHandler, ErrorContextElement, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed then
            ErrorMessageMgt.Activate(ErrorMessageHandler);
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest2(NewDeprBookCode: Code[10]; NewPostingDate: Date; NewDeprUntilDate: Date; NewDocumentNo: Code[20]; NewPostingDescription: Text[100]; NewUseForceNoOfDays: Boolean; NewDaysInPeriod: Integer; NewBalAccount: Boolean; ChangeDetails: Boolean; NewDeprBonus: Boolean)
    begin
        ClearAll();
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
    local procedure OnBeforeActivateErrorMessageHandling(varFixedAsset: Record "Fixed Asset"; var ErrorMessageMgt: Codeunit "Error Message Management"; var ErrorMessageHandler: Codeunit "Error Message Handler"; var ErrorContextElement: Codeunit "Error Context Element"; var IsHandled: Boolean)
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineCreate(var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

