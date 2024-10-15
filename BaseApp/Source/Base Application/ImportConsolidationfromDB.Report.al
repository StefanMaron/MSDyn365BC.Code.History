report 90 "Import Consolidation from DB"
{
    Caption = 'Consolidation Report';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Business Unit"; "Business Unit")
        {
            DataItemTableView = SORTING(Code) WHERE(Consolidate = CONST(true));
            RequestFilterFields = "Code";
            dataitem("G/L Account"; "G/L Account")
            {
                DataItemTableView = SORTING("No.") WHERE("Account Type" = CONST(Posting));
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLink = "G/L Account No." = FIELD("No.");
                    DataItemTableView = SORTING("G/L Account No.", "Posting Date");
                    dataitem("Dimension Set Entry"; "Dimension Set Entry")
                    {
                        DataItemLink = "Dimension Set ID" = FIELD("Dimension Set ID");
                        DataItemTableView = SORTING("Dimension Set ID", "Dimension Code");

                        trigger OnAfterGetRecord()
                        var
                            TempDimBuf: Record "Dimension Buffer" temporary;
                        begin
                            TempDimBuf.Init;
                            TempDimBuf."Table ID" := DATABASE::"G/L Entry";
                            TempDimBuf."Entry No." := GLEntryNo;
                            if TempDim.Get("Dimension Code") and
                               (TempDim."Consolidation Code" <> '')
                            then
                                TempDimBuf."Dimension Code" := TempDim."Consolidation Code"
                            else
                                TempDimBuf."Dimension Code" := "Dimension Code";
                            if TempDimVal.Get("Dimension Code", "Dimension Value Code") and
                               (TempDimVal."Consolidation Code" <> '')
                            then
                                TempDimBuf."Dimension Value Code" := TempDimVal."Consolidation Code"
                            else
                                TempDimBuf."Dimension Value Code" := "Dimension Value Code";
                            BusUnitConsolidate.InsertEntryDim(TempDimBuf, TempDimBuf."Entry No.");
                        end;

                        trigger OnPreDataItem()
                        var
                            BusUnitDim: Record Dimension;
                            DimMgt: Codeunit DimensionManagement;
                            ColumnDimFilter: Text;
                        begin
                            if ColumnDim <> '' then begin
                                ColumnDimFilter := ConvertStr(ColumnDim, ';', '|');
                                BusUnitDim.ChangeCompany("Business Unit"."Company Name");
                                SetFilter("Dimension Code", DimMgt.GetConsolidatedDimFilterByDimFilter(BusUnitDim, ColumnDimFilter));
                            end;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        GLEntryNo := BusUnitConsolidate.InsertGLEntry("G/L Entry");
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Posting Date", ConsolidStartDate, ConsolidEndDate);

                        if GetRangeMin("Posting Date") = NormalDate(GetRangeMin("Posting Date")) then
                            CheckClosingPostings("G/L Account"."No.", GetRangeMin("Posting Date"), GetRangeMax("Posting Date"));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, "No.");
                    Window.Update(3, '');

                    BusUnitConsolidate.InsertGLAccount("G/L Account");
                end;
            }
            dataitem("Currency Exchange Rate"; "Currency Exchange Rate")
            {
                DataItemTableView = SORTING("Currency Code", "Starting Date");

                trigger OnAfterGetRecord()
                begin
                    BusUnitConsolidate.InsertExchRate("Currency Exchange Rate");
                end;

                trigger OnPreDataItem()
                var
                    SubsidGLSetup: Record "General Ledger Setup";
                begin
                    if "Business Unit"."Currency Code" = '' then
                        CurrReport.Break;

                    SubsidGLSetup.ChangeCompany("Business Unit"."Company Name");
                    SubsidGLSetup.Get;
                    AdditionalCurrencyCode := SubsidGLSetup."Additional Reporting Currency";
                    if SubsidGLSetup."LCY Code" <> '' then
                        SubsidCurrencyCode := SubsidGLSetup."LCY Code"
                    else
                        SubsidCurrencyCode := "Business Unit"."Currency Code";

                    if (ParentCurrencyCode = '') and (AdditionalCurrencyCode = '') then
                        CurrReport.Break;

                    SetFilter("Currency Code", '%1|%2', ParentCurrencyCode, AdditionalCurrencyCode);
                    SetRange("Starting Date", 0D, ConsolidEndDate);
                end;
            }
            dataitem(DoTheConsolidation; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));

                trigger OnAfterGetRecord()
                begin
                    BusUnitConsolidate.SetGlobals(
                      '', '', "Business Unit"."Company Name",
                      SubsidCurrencyCode, AdditionalCurrencyCode, ParentCurrencyCode,
                      0, ConsolidStartDate, ConsolidEndDate);
                    BusUnitConsolidate.UpdateGLEntryDimSetID;
                    BusUnitConsolidate.Run("Business Unit");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, Code);
                Window.Update(2, '');

                Clear(BusUnitConsolidate);
                BusUnitConsolidate.SetDocNo(GLDocNo, SelectJnlLine."Journal Template Name", SelectJnlLine."Journal Batch Name");

                TestField("Company Name");
                "G/L Entry".ChangeCompany("Company Name");
                "Dimension Set Entry".ChangeCompany("Company Name");
                "G/L Account".ChangeCompany("Company Name");
                "Currency Exchange Rate".ChangeCompany("Company Name");
                Dim.ChangeCompany("Company Name");
                DimVal.ChangeCompany("Company Name");

                SelectedDim.SetRange("User ID", UserId);
                SelectedDim.SetRange("Object Type", 3);
                SelectedDim.SetRange("Object ID", REPORT::"Import Consolidation from DB");
                BusUnitConsolidate.SetSelectedDim(SelectedDim);

                TempDim.Reset;
                TempDim.DeleteAll;
                if Dim.Find('-') then begin
                    repeat
                        TempDim.Init;
                        TempDim := Dim;
                        TempDim.Insert;
                    until Dim.Next = 0;
                end;
                TempDim.Reset;
                TempDimVal.Reset;
                TempDimVal.DeleteAll;
                if DimVal.Find('-') then begin
                    repeat
                        TempDimVal.Init;
                        TempDimVal := DimVal;
                        TempDimVal.Insert;
                    until DimVal.Next = 0;
                end;

                AdditionalCurrencyCode := '';
                SubsidCurrencyCode := '';
            end;

            trigger OnPreDataItem()
            begin
                CheckConsolidDates(ConsolidStartDate, ConsolidEndDate);

                if GLDocNo = '' then
                    Error(Text000);

                Window.Open(
                  Text001 +
                  Text002 +
                  Text003 +
                  Text004);
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
                    group("Consolidation Period")
                    {
                        Caption = 'Consolidation Period';
                        field(StartingDate; ConsolidStartDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Starting Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the date from which the report or batch job processes information.';
                        }
                        field(EndingDate; ConsolidEndDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Ending Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the ending date.';
                        }
                    }
                    group("Copy Field Contents")
                    {
                        Caption = 'Copy Field Contents';
                        field(ColumnDim; ColumnDim)
                        {
                            ApplicationArea = Dimensions;
                            Caption = 'Copy Dimensions';
                            Editable = false;
                            ToolTip = 'Specifies if you want the entries to be classified by dimensions when they are transferred.';

                            trigger OnAssistEdit()
                            begin
                                DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Import Consolidation from DB", ColumnDim);
                            end;
                        }
                    }
                    field(DocumentNo; GLDocNo)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the G/L document number.';
                    }
                    field(ParentCurrencyCode; ParentCurrencyCode)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Parent Currency Code';
                        ToolTip = 'Specifies the parent currency code.';
                    }
                    field("SelectJnlLine.""Journal Template Name"""; SelectJnlLine."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';

                        trigger OnValidate()
                        begin
                            SelectJnlLine."Journal Batch Name" := '';
                        end;
                    }
                    field("SelectJnlLine.""Journal Batch Name"""; SelectJnlLine."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch Name';
                        Lookup = true;
                        ToolTip = 'Specifies the name of the journal batch that is used for the posting.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            SelectJnlLine.TestField("Journal Template Name");
                            GenJournalTempl.Get(SelectJnlLine."Journal Template Name");
                            GenJnlBatch.SetRange("Journal Template Name", SelectJnlLine."Journal Template Name");
                            GenJnlBatch."Journal Template Name" := SelectJnlLine."Journal Template Name";
                            GenJnlBatch.Name := SelectJnlLine."Journal Batch Name";
                            if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then
                                SelectJnlLine."Journal Batch Name" := GenJnlBatch.Name;
                        end;

                        trigger OnValidate()
                        begin
                            if SelectJnlLine."Journal Batch Name" <> '' then begin
                                SelectJnlLine.TestField("Journal Template Name");
                                GenJnlBatch.Get(SelectJnlLine."Journal Template Name", SelectJnlLine."Journal Batch Name");
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if ConsolidStartDate = 0D then
                ConsolidStartDate := WorkDate;
            if ConsolidEndDate = 0D then
                ConsolidEndDate := WorkDate;

            if ParentCurrencyCode = '' then begin
                GLSetup.Get;
                ParentCurrencyCode := GLSetup."LCY Code";
            end;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Commit;
        REPORT.Run(REPORT::"Consolidated Trial Balance");
    end;

    trigger OnPreReport()
    begin
        DimSelectionBuf.CompareDimText(
          3, REPORT::"Import Consolidation from DB", '', ColumnDim, Text020);
        if SelectJnlLine."Journal Template Name" = '' then
            Error(Text11300);
        if SelectJnlLine."Journal Batch Name" = '' then
            Error(Text11301);
        Clear(NoSeriesMgt);
        Clear(GLDocNo);
        GenJnlBatch.Get(SelectJnlLine."Journal Template Name", SelectJnlLine."Journal Batch Name");
        GenJnlBatch.TestField("No. Series");
        GLDocNo := NoSeriesMgt.GetNextNo(GenJnlBatch."No. Series", WorkDate, true);
    end;

    var
        Text000: Label 'Enter a document number.';
        Text001: Label 'Importing Subsidiary Data...\\';
        Text002: Label 'Business Unit Code   #1##########\';
        Text003: Label 'G/L Account No.      #2##########\';
        Text004: Label 'Date                 #3######';
        Text006: Label 'Enter the starting date for the consolidation period.';
        Text007: Label 'Enter the ending date for the consolidation period.';
        Text020: Label 'Copy Dimensions';
        Text022: Label 'A %1 with %2 on a closing date (%3) was found while consolidating nonclosing entries (%4 %5).';
        Text023: Label 'Do you want to consolidate in the period from %1 to %2?';
        Text024: Label 'There is no %1 to consolidate.';
        Text028: Label 'You must create a new fiscal year in the consolidated company.';
        Text030: Label 'When using closing dates, the starting and ending dates must be the same.';
        SelectedDim: Record "Selected Dimension";
        Dim: Record Dimension;
        DimVal: Record "Dimension Value";
        TempDim: Record Dimension temporary;
        TempDimVal: Record "Dimension Value" temporary;
        GLSetup: Record "General Ledger Setup";
        DimSelectionBuf: Record "Dimension Selection Buffer";
        SelectJnlLine: Record "Gen. Journal Line";
        GenJournalTempl: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        BusUnitConsolidate: Codeunit Consolidate;
        Window: Dialog;
        ConsolidStartDate: Date;
        ConsolidEndDate: Date;
        GLDocNo: Code[20];
        ColumnDim: Text[250];
        ParentCurrencyCode: Code[10];
        SubsidCurrencyCode: Code[10];
        AdditionalCurrencyCode: Code[10];
        Text032: Label 'The %1 is later than the %2 in company %3.';
        GLEntryNo: Integer;
        ConsPeriodSubsidiaryQst: Label 'The consolidation period %1 .. %2 is not within the fiscal year of one or more of the subsidiaries.\Do you want to proceed with the consolidation?', Comment = '%1 and %2 - request page values';
        ConsPeriodCompanyQst: Label 'The consolidation period %1 .. %2 is not within the fiscal year %3 .. %4 of the consolidated company %5.\Do you want to proceed with the consolidation?', Comment = '%1, %2, %3, %4 - request page values, %5 - company name';
        Text11300: Label 'Please enter a Journal Template Name.';
        Text11301: Label 'Please enter a Journal Batch Name.';

    local procedure CheckClosingPostings(GLAccNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        GLEntry: Record "G/L Entry";
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.ChangeCompany("Business Unit"."Company Name");
        AccountingPeriod.SetCurrentKey("New Fiscal Year", "Date Locked");
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange("Date Locked", true);
        AccountingPeriod.SetRange("Starting Date", StartDate + 1, EndDate);
        if AccountingPeriod.Find('-') then begin
            GLEntry.ChangeCompany("Business Unit"."Company Name");
            GLEntry.SetRange("G/L Account No.", GLAccNo);
            repeat
                GLEntry.SetRange("Posting Date", ClosingDate(AccountingPeriod."Starting Date" - 1));
                if not GLEntry.IsEmpty then
                    Error(
                      Text022,
                      GLEntry.TableCaption,
                      GLEntry.FieldCaption("Posting Date"),
                      GLEntry.GetFilter("Posting Date"),
                      GLEntry.FieldCaption("G/L Account No."),
                      GLAccNo);
            until AccountingPeriod.Next = 0;
        end;
    end;

    local procedure CheckConsolidDates(StartDate: Date; EndDate: Date)
    var
        BusUnit: Record "Business Unit";
        ConfirmManagement: Codeunit "Confirm Management";
        ConsolPeriodInclInFiscalYears: Boolean;
    begin
        if StartDate = 0D then
            Error(Text006);
        if EndDate = 0D then
            Error(Text007);

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text023, StartDate, EndDate), true) then
            CurrReport.Break;

        CheckClosingDates(StartDate, EndDate);

        BusUnit.CopyFilters("Business Unit");
        BusUnit.SetRange(Consolidate, true);
        if not BusUnit.Find('-') then
            Error(Text024, BusUnit.TableCaption);

        ConsolPeriodInclInFiscalYears := true;
        repeat
            if (StartDate = NormalDate(StartDate)) or (EndDate = NormalDate(EndDate)) then
                if (BusUnit."Starting Date" <> 0D) or (BusUnit."Ending Date" <> 0D) then begin
                    CheckBusUnitsDatesToFiscalYear(BusUnit);
                    ConsolPeriodInclInFiscalYears :=
                      ConsolPeriodInclInFiscalYears and CheckDatesToBusUnitDates(StartDate, EndDate, BusUnit);
                end;
        until BusUnit.Next = 0;

        if not ConsolPeriodInclInFiscalYears then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(ConsPeriodSubsidiaryQst, StartDate, EndDate), true)
            then
                CurrReport.Break;

        CheckDatesToFiscalYear(StartDate, EndDate);
    end;

    local procedure CheckDatesToFiscalYear(StartDate: Date; EndDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
        ConfirmManagement: Codeunit "Confirm Management";
        FiscalYearStartDate: Date;
        FiscalYearEndDate: Date;
        ConsolPeriodInclInFiscalYear: Boolean;
    begin
        ConsolPeriodInclInFiscalYear := true;

        AccountingPeriod.Reset;
        AccountingPeriod.SetRange(Closed, false);
        AccountingPeriod.SetRange("New Fiscal Year", true);
        if AccountingPeriod.Find('-') then begin
            FiscalYearStartDate := AccountingPeriod."Starting Date";
            if AccountingPeriod.Find('>') then
                FiscalYearEndDate := CalcDate('<-1D>', AccountingPeriod."Starting Date")
            else
                Error(Text028);

            ConsolPeriodInclInFiscalYear := (StartDate >= FiscalYearStartDate) and (EndDate <= FiscalYearEndDate);

            if not ConsolPeriodInclInFiscalYear then
                if not ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(
                       ConsPeriodCompanyQst, StartDate, EndDate, FiscalYearStartDate,
                       FiscalYearEndDate, CompanyName), true)
                then
                    CurrReport.Break;
        end;
    end;

    local procedure CheckDatesToBusUnitDates(StartDate: Date; EndDate: Date; BusUnit: Record "Business Unit"): Boolean
    var
        ConsolPeriodInclInFiscalYear: Boolean;
    begin
        ConsolPeriodInclInFiscalYear := (StartDate >= BusUnit."Starting Date") and (EndDate <= BusUnit."Ending Date");
        exit(ConsolPeriodInclInFiscalYear);
    end;

    local procedure CheckClosingDates(StartDate: Date; EndDate: Date)
    begin
        if (StartDate = ClosingDate(StartDate)) or
           (EndDate = ClosingDate(EndDate))
        then begin
            if StartDate <> EndDate then
                Error(Text030);
        end;
    end;

    local procedure CheckBusUnitsDatesToFiscalYear(var BusUnit: Record "Business Unit")
    begin
        with BusUnit do
            if ("Starting Date" <> 0D) or ("Ending Date" <> 0D) then begin
                TestField("Starting Date");
                TestField("Ending Date");
                if "Starting Date" > "Ending Date" then
                    Error(
                      Text032, FieldCaption("Starting Date"),
                      FieldCaption("Ending Date"), "Company Name");
            end;
    end;
}

