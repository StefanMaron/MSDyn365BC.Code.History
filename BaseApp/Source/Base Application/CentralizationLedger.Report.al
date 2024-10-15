report 11303 "Centralization Ledger"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CentralizationLedger.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Centralization Ledger';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(PeriodLoop; "Integer")
        {
            DataItemTableView = SORTING(Number);
            column(Startpage; Startpage)
            {
            }
            dataitem(PrintHeader; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(ReportFilter; ReportFilter)
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName)
                {
                }
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(PageCount; PageCount)
                {
                }
                column(PageNoCaption; PageNoCaptionLbl)
                {
                }
                column(CentralizationLedgCaption; CentralizationLedgCaptionLbl)
                {
                }
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemTableView = SORTING("Journal Template Name", "Posting Date", "Document No.");
                column(ReportFilter_GLEntry; ReportFilter)
                {
                }
                column(Printed; Printed)
                {
                }
                column(PrintDetail; PrintDetail)
                {
                }
                column(JnlTempName; StrSubstNo(Text11302, FieldCaption("Journal Template Name"), "Journal Template Name"))
                {
                }
                column(TotalDebit; TotalDebit)
                {
                    AutoFormatType = 1;
                }
                column(TotalCredit; TotalCredit)
                {
                    AutoFormatType = 1;
                }
                column(TotalAddCurrCredit; TotalAddCurrCredit)
                {
                    AutoFormatExpression = GetCurrencyCode;
                    AutoFormatType = 1;
                }
                column(TotalAddCurrDebit; TotalAddCurrDebit)
                {
                    AutoFormatExpression = GetCurrencyCode;
                    AutoFormatType = 1;
                }
                column(TotalMessage; TotalMessage)
                {
                }
                column(PeriodLength; PeriodLength)
                {
                }
                column(GrTotalCredit; GrTotalCredit)
                {
                    AutoFormatType = 1;
                }
                column(GrTotalDebit; GrTotalDebit)
                {
                    AutoFormatType = 1;
                }
                column(GrTotalAddCurrCredit; GrTotalAddCurrCredit)
                {
                    AutoFormatExpression = GetCurrencyCode;
                    AutoFormatType = 1;
                }
                column(GrTotalAddCurrDebit; GrTotalAddCurrDebit)
                {
                    AutoFormatExpression = GetCurrencyCode;
                    AutoFormatType = 1;
                }
                column(GLEntry2GLAccNo; "G/L Entry2".FieldCaption("G/L Account No."))
                {
                }
                column(GLEntry2DescCaption; "G/L Entry2".FieldCaption(Description))
                {
                }
                column(GLEntry2DebitAmtCaption; "G/L Entry2".FieldCaption("Debit Amount"))
                {
                }
                column(GLEntry2CreditAmtCaption; "G/L Entry2".FieldCaption("Credit Amount"))
                {
                }
                column(GLEntry2AddCurrDebitAmtCaption; "G/L Entry2".FieldCaption("Add.-Currency Debit Amount"))
                {
                }
                column(GLEntry2AddCurrCreditAmtCaption; "G/L Entry2".FieldCaption("Add.-Currency Credit Amount"))
                {
                }
                column(AddCurrDebitAmtCaptionLbl; AddCurrDebitAmtCaptionLbl)
                {
                }
                column(AddCurrCreditAmtCaptionLbl; AddCurrCreditAmtCaptionLbl)
                {
                }
                column(CreditAmtCaption; CreditAmtCaptionLbl)
                {
                }
                column(DebitAmtCaption; DebitAmtCaptionLbl)
                {
                }
                column(JnlTempNameCaption; JnlTempNameCaptionLbl)
                {
                }
                column(GeneralTotalCaption; GeneralTotalCaptionLbl)
                {
                }
                column(EntryNo_GLEntry; "Entry No.")
                {
                }
                column(JnlTempName_GLEntry; "Journal Template Name")
                {
                }
                dataitem("G/L Entry2"; "G/L Entry")
                {
                    DataItemLink = "Journal Template Name" = FIELD("Journal Template Name");
                    DataItemLinkReference = "G/L Entry";
                    DataItemTableView = SORTING("Journal Template Name", "G/L Account No.", "Posting Date", "Document Type");
                    column(AddCurrCreditAmt_GLEntry2; "Add.-Currency Credit Amount")
                    {
                        AutoFormatExpression = GetCurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(AddCurrDebitAmt_GLEntry2; "Add.-Currency Debit Amount")
                    {
                        AutoFormatExpression = GetCurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(CreditAmt_GLEntry2; "Credit Amount")
                    {
                    }
                    column(DebitAmt_GLEntry2; "Debit Amount")
                    {
                    }
                    column(Desc_GLEntry2; Description)
                    {
                    }
                    column(GLAccNo_GLEntry2; "G/L Account No.")
                    {
                    }
                    column(EntryNo_GLEntry2; "Entry No.")
                    {
                    }
                    column(JnlTempName_GLEntry2; "Journal Template Name")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not GLAccount.Get("G/L Account No.") then
                            Description := StrSubstNo(Text11303, GLAccount.TableCaption)
                        else
                            Description := GLAccount.Name;

                        if PrintDetail then
                            TotalMessage := 'Total'
                        else
                            TotalMessage := "Journal Template Name";

                        GrTotalDebit := GrTotalDebit + "Debit Amount";
                        GrTotalCredit := GrTotalCredit + "Credit Amount";
                        GrTotalAddCurrDebit := GrTotalAddCurrDebit + "Add.-Currency Debit Amount";
                        GrTotalAddCurrCredit := GrTotalAddCurrCredit + "Add.-Currency Credit Amount";
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Posting Date", PeriodStartDate, PeriodEndDate);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if OldName <> "Journal Template Name" then begin
                        TotalDebit := 0;
                        TotalCredit := 0;
                        TotalAddCurrDebit := 0;
                        TotalAddCurrCredit := 0;
                    end;

                    TotalDebit := TotalDebit + "Debit Amount";
                    TotalCredit := TotalCredit + "Credit Amount";
                    TotalAddCurrDebit := TotalAddCurrDebit + "Add.-Currency Debit Amount";
                    TotalAddCurrCredit := TotalAddCurrCredit + "Add.-Currency Credit Amount";

                    if OldName = "Journal Template Name" then
                        CurrReport.Skip();

                    OldName := "Journal Template Name";
                end;

                trigger OnPreDataItem()
                begin
                    "G/L Entry".SetRange("Posting Date", PeriodStartDate, PeriodEndDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                PeriodStartDate := NormalDate(PeriodEndDate) + 1;
                PeriodEndDate := ClosingDate(CalcDate(PeriodLength, PeriodStartDate) - 1);
                ReportFilter := Text11300 + Format(PeriodStartDate) + ' ... ' + Format(PeriodEndDate);

                GrTotalDebit := 0;
                GrTotalCredit := 0;
                GrTotalAddCurrDebit := 0;
                GrTotalAddCurrCredit := 0;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, NoOfPeriods);
                PeriodEndDate := StartDate - 1;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(NoOfPeriods; NoOfPeriods)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Periods';
                        ToolTip = 'Specifies the number of periods to be included in the report. The length of the periods is determined by the length of the periods in the Accounting Period table.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(Startpage; Startpage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Page Number';
                        ToolTip = 'Specifies the first page number of the report.';
                    }
                    field(PrintDetail; PrintDetail)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print G/L Account Details';
                        ToolTip = 'Specifies if you want the general ledger account details to be included in the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if StartDate = 0D then
                StartDate := WorkDate;
            if NoOfPeriods = 0 then
                NoOfPeriods := 1;
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
            Startpage := 1;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ReportFilter := "G/L Entry".GetFilter("Posting Date");
        if ReportFilter <> '' then
            ReportFilter := Text11300 + ReportFilter
        else
            ReportFilter := Text11301;
    end;

    var
        Text11300: Label 'Date Filter: ';
        Text11301: Label 'Date Filter: None';
        Text11302: Label '%1 : %2';
        GLAccount: Record "G/L Account";
        OldName: Code[10];
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        GrTotalDebit: Decimal;
        GrTotalCredit: Decimal;
        ReportFilter: Text[80];
        Text11303: Label 'Unknown %1';
        StartDate: Date;
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        NoOfPeriods: Integer;
        PeriodLength: DateFormula;
        Startpage: Integer;
        PrintDetail: Boolean;
        Printed: Boolean;
        TotalAddCurrDebit: Decimal;
        TotalAddCurrCredit: Decimal;
        GrTotalAddCurrDebit: Decimal;
        GrTotalAddCurrCredit: Decimal;
        TotalMessage: Text[100];
        PageCount: Integer;
        PageNoCaptionLbl: Label 'Page';
        CentralizationLedgCaptionLbl: Label 'Centralization Ledger';
        AddCurrDebitAmtCaptionLbl: Label 'Add.-Currency Debit Amount';
        AddCurrCreditAmtCaptionLbl: Label 'Add.-Currency Credit Amount';
        CreditAmtCaptionLbl: Label 'Credit Amount';
        DebitAmtCaptionLbl: Label 'Debit Amount';
        JnlTempNameCaptionLbl: Label 'Journal Template Name';
        GeneralTotalCaptionLbl: Label 'General Total';
}

