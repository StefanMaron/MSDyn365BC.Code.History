report 12439 "Customer Turnover"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/CustomerTurnover.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Turnover';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Customer Posting Group", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Date Filter";
            column(CurrentDate; CurrentDate)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(RequestFilter; RequestFilter)
            {
            }
            column(AmountUnit; AmountUnit)
            {
            }
            column(Customer__No__; "No.")
            {
            }
            column(Customer_Name; Name)
            {
            }
            column(LineText_1_; LineText[1])
            {
            }
            column(LineText_2_; LineText[2])
            {
            }
            column(LineText_3_; LineText[3])
            {
            }
            column(LineText_4_; LineText[4])
            {
            }
            column(LineText_5_; LineText[5])
            {
            }
            column(LineText_6_; LineText[6])
            {
            }
            column(LineAmount_6_; LineAmount[6])
            {
            }
            column(LineAmount_5_; LineAmount[5])
            {
            }
            column(LineAmount_4_; LineAmount[4])
            {
            }
            column(LineAmount_3_; LineAmount[3])
            {
            }
            column(LineAmount_2_; LineAmount[2])
            {
            }
            column(LineAmount_1_; LineAmount[1])
            {
            }
            column(LineText_1__Control61; LineText[1])
            {
            }
            column(TotalText_1_; TotalText[1])
            {
            }
            column(LineText_2__Control63; LineText[2])
            {
            }
            column(TotalText_2_; TotalText[2])
            {
            }
            column(TotalText_3_; TotalText[3])
            {
            }
            column(LineText_3__Control68; LineText[3])
            {
            }
            column(TotalText_4_; TotalText[4])
            {
            }
            column(LineText_4__Control76; LineText[4])
            {
            }
            column(LineText_5__Control78; LineText[5])
            {
            }
            column(TotalText_5_; TotalText[5])
            {
            }
            column(LineText_6__Control81; LineText[6])
            {
            }
            column(TotalText_6_; TotalText[6])
            {
            }
            column(ReportParameters_1_; ReportParameters[1])
            {
            }
            column(ReportParameters_2_; ReportParameters[2])
            {
            }
            column(ReportParameters_3_; ReportParameters[3])
            {
            }
            column(ReportParameters_4_; ReportParameters[4])
            {
            }
            column(CustomerCaption; CustomerCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Turnover_SheetCaption; Turnover_SheetCaptionLbl)
            {
            }
            column(No_Caption; No_CaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(Beginning_period_balanceCaption; Beginning_period_balanceCaptionLbl)
            {
            }
            column(Net_Change_for_PeriodCaption; Net_Change_for_PeriodCaptionLbl)
            {
            }
            column(Ending_period_balanceCaption; Ending_period_balanceCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(DebitCaption_Control18; DebitCaption_Control18Lbl)
            {
            }
            column(CreditCaption_Control19; CreditCaption_Control19Lbl)
            {
            }
            column(DebitCaption_Control20; DebitCaption_Control20Lbl)
            {
            }
            column(CreditCaption_Control21; CreditCaption_Control21Lbl)
            {
            }
            column(Total_Caption; Total_CaptionLbl)
            {
            }
            dataitem("Customer Agreement"; "Customer Agreement")
            {
                DataItemLink = "Customer No." = field("No.");
                column(Customer_Agreement__No__; "No.")
                {
                }
                column(Customer_Agreement_Description; Description)
                {
                }
                column(LineAgrText1; LineAgrText[1])
                {
                }
                column(LineAgrText2; LineAgrText[2])
                {
                }
                column(LineAgrText3; LineAgrText[3])
                {
                }
                column(LineAgrText4; LineAgrText[4])
                {
                }
                column(LineAgrText5; LineAgrText[5])
                {
                }
                column(LineAgrText6; LineAgrText[6])
                {
                }
                column(Customer_Agreement_Customer_No_; "Customer No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(LineAmountAgr);

                    if StartDate > 0D then begin
                        SetRange("Date Filter", 0D, CalcDate('<-1D>', StartDate));
                        CalcFields("Net Change (LCY)");
                        RoundedValue := Round(Abs("Net Change (LCY)"), Decimals, '=');
                        if "Net Change (LCY)" > 0 then
                            LineAmountAgr[1] := RoundedValue
                        else
                            LineAmountAgr[2] := RoundedValue;
                    end;
                    SetRange("Date Filter", 0D, EndDate);
                    CalcFields("Net Change (LCY)");
                    RoundedValue := Round(Abs("Net Change (LCY)"), Decimals, '=');
                    if "Net Change (LCY)" > 0 then
                        LineAmountAgr[5] := RoundedValue
                    else
                        LineAmountAgr[6] := RoundedValue;
                    SetRange("Date Filter", StartDate, EndDate);
                    CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                    LineAmountAgr[3] := Round(Abs("Debit Amount (LCY)"), Decimals, '=');
                    LineAmountAgr[4] := Round(Abs("Credit Amount (LCY)"), Decimals, '=');

                    if SkipZeroBalances and (LineAmountAgr[1] = 0) and (LineAmountAgr[2] = 0) then
                        CurrReport.Skip();
                    if SkipZeroNetChanges and (LineAmountAgr[3] = 0) and (LineAmountAgr[4] = 0) then
                        CurrReport.Skip();
                    if SkipZeroLines and
                      (LineAmountAgr[1] = 0) and (LineAmountAgr[2] = 0) and
                      (LineAmountAgr[3] = 0) and (LineAmountAgr[4] = 0) and
                      (LineAmountAgr[5] = 0) and (LineAmountAgr[6] = 0) then
                        CurrReport.Skip();

                    TextLineValues(SkipZeroValues, LineAmountAgr, LineAgrText);
                end;

                trigger OnPreDataItem()
                begin
                    if not PrintAgreements then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Clear(LineAmount);
                if StartDate > 0D then begin
                    SetRange("Date Filter", 0D, CalcDate('<-1D>', StartDate));
                    CalcFields("Net Change (LCY)");
                    RoundedValue := Round(Abs("Net Change (LCY)"), Decimals, '=');
                    if "Net Change (LCY)" > 0 then
                        LineAmount[1] := RoundedValue
                    else
                        LineAmount[2] := RoundedValue;
                end;
                SetRange("Date Filter", 0D, EndDate);
                CalcFields("Net Change (LCY)");
                RoundedValue := Round(Abs("Net Change (LCY)"), Decimals, '=');
                if "Net Change (LCY)" > 0 then
                    LineAmount[5] := RoundedValue
                else
                    LineAmount[6] := RoundedValue;
                SetRange("Date Filter", StartDate, EndDate);
                CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                LineAmount[3] := Round(Abs("Debit Amount (LCY)"), Decimals, '=');
                LineAmount[4] := Round(Abs("Credit Amount (LCY)"), Decimals, '=');

                if SkipZeroBalances and (LineAmount[1] = 0) and (LineAmount[2] = 0) then
                    CurrReport.Skip();
                if SkipZeroNetChanges and (LineAmount[3] = 0) and (LineAmount[4] = 0) then
                    CurrReport.Skip();
                if SkipZeroLines and
                  (LineAmount[1] = 0) and (LineAmount[2] = 0) and
                  (LineAmount[3] = 0) and (LineAmount[4] = 0) and
                  (LineAmount[5] = 0) and (LineAmount[6] = 0) then
                    CurrReport.Skip();

                TextLineValues(SkipZeroValues, LineAmount, LineText);
            end;

            trigger OnPreDataItem()
            begin
                Clear(LineAmount);
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
                    group(Printout)
                    {
                        Caption = 'Printout';
                        field("Rounding Precision"; RoundingPrecision)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Rounding Precision';
                            ToolTip = 'Specifies the size of the interval to be used when rounding amounts in the specified currency. You can specify invoice rounding for each currency in the Currency table.';
                        }
                        field("Replace zero values"; SkipZeroValues)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Replace zero values by blanks';
                            ToolTip = 'Specifies if you want all zero values on the report to be displayed as blank entries.';
                        }
                        field("Skip accounts without net changes"; SkipZeroNetChanges)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip accounts without net changes';
                            ToolTip = 'Specifies that you want the report to exclude accounts with zero turnovers for the given period.';
                        }
                        field("Skip accounts with zero ending balance"; SkipZeroBalances)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip accounts with zero ending balance';
                            ToolTip = 'Specifies that you want the report to exclude accounts with zero ending balance at the end of the period.';
                        }
                        field("Skip zero lines"; SkipZeroLines)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip zero lines';
                            ToolTip = 'Specifies if lines with zero amount are not be included.';
                        }
                        field("Print by Agreements"; PrintAgreements)
                        {
                            ApplicationArea = All;
                            Caption = 'Print by Agreements';
                            Visible = "Print by AgreementsVisible";
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            "Print by AgreementsVisible" := true;
        end;

        trigger OnOpenPage()
        begin
            SalesSetup.Get();
            if SalesSetup."Customer Agreement Dim. Code" = '' then
                "Print by AgreementsVisible" := false;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CurrentDate := LocMgt.Date2Text(Today()) + Format(Time(), 0, '(<Hours24>:<Minutes>)');
        RequestFilter := Customer.GetFilters();
        if Customer.GetRangeMin("Date Filter") > 0D then
            StartDate := Customer.GetRangeMin("Date Filter");
        EndDate := Customer.GetRangeMax("Date Filter");
        FillReportParameters();
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        LocMgt: Codeunit "Localisation Management";
        LineAmount: array[10] of Decimal;
        LineText: array[10] of Text[30];
        LineAgrText: array[10] of Text[30];
        TotalText: array[10] of Text[30];
        RoundedValue: Decimal;
        StartDate: Date;
        EndDate: Date;
        RoundingPrecision: Option "0.01","1.00","1000";
        Decimals: Decimal;
        SkipZeroNetChanges: Boolean;
        SkipZeroValues: Boolean;
        SkipZeroLines: Boolean;
        SkipZeroBalances: Boolean;
        PrintParameters: Boolean;
        PrintAgreements: Boolean;
        CurrentDate: Text[30];
        RequestFilter: Text;
        AmountUnit: Text[30];
        ValueFormat: Text[50];
        ReportParameters: array[4] of Text[80];
        PeriodText: Text[100];
        Counter: Integer;
        I: Integer;
        LineAmountAgr: array[10] of Decimal;
        "Print by AgreementsVisible": Boolean;
        CustomerCaptionLbl: Label 'Customer';
        PageCaptionLbl: Label 'Page';
        Turnover_SheetCaptionLbl: Label 'Turnover Sheet';
        No_CaptionLbl: Label 'No.';
        NameCaptionLbl: Label 'Name';
        Beginning_period_balanceCaptionLbl: Label 'Beginning period balance';
        Net_Change_for_PeriodCaptionLbl: Label 'Net Change for Period';
        Ending_period_balanceCaptionLbl: Label 'Ending period balance';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        DebitCaption_Control18Lbl: Label 'Debit';
        CreditCaption_Control19Lbl: Label 'Credit';
        DebitCaption_Control20Lbl: Label 'Debit';
        CreditCaption_Control21Lbl: Label 'Credit';
        Total_CaptionLbl: Label 'Total:';

    local procedure TextLineValues(ZeroBySpaces: Boolean; Amounts: array[10] of Decimal; var TextValues: array[10] of Text)
    begin
        Clear(TextValues);
        for I := 1 to 6 do
            TextValues[I] := Value2Text(Amounts[I], ZeroBySpaces);
    end;

    local procedure Value2Text(Value: Decimal; ZeroBySpaces: Boolean): Text[30]
    begin
        if ZeroBySpaces and (Value = 0) then
            exit('');
        Value := Round(Value, Decimals);
        if Decimals > 1 then
            Value := Value / Decimals;
        exit(Format(Value, 0, ValueFormat));
    end;

    [Scope('OnPrem')]
    procedure FillReportParameters()
    var
        Text001: Label 'for period from %1 to %2';
        Text003: Label 'Replace zero values by blanks';
        Text004: Label 'Skip accounts without net change  ';
        Text005: Label 'Skip accounts without ending balance';
        Text006: Label 'Skip lines with zero values';
        Text007: Label '(in currency units)';
        Text008: Label '(in thousands)';
    begin
        case RoundingPrecision of
            RoundingPrecision::"0.01":
                begin
                    ValueFormat := '<Sign><Integer Thousand><Decimals,3>';
                    Decimals := 0.01;
                    AmountUnit := '';
                end;
            RoundingPrecision::"1.00":
                begin
                    ValueFormat := '<Sign><Integer Thousand>';
                    Decimals := 1;
                    AmountUnit := Text007;
                end;
            RoundingPrecision::"1000":
                begin
                    ValueFormat := '<Sign><Integer Thousand>';
                    Decimals := 1000;
                    AmountUnit := Text008;
                end;
        end;
        Counter := 0;
        if SkipZeroValues then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text003;
        end;
        if SkipZeroNetChanges then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text004;
        end;
        if SkipZeroBalances then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text005;
        end;
        if SkipZeroLines then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text006;
        end;

        PeriodText := StrSubstNo(Text001, StartDate, EndDate);
        PrintParameters := Counter > 0;
    end;
}

