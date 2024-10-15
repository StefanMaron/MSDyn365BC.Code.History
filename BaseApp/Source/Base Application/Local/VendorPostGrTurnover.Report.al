report 12443 "Vendor Post. Gr. Turnover"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/VendorPostGrTurnover.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Posting Group Turnover';
    EnableHyperlinks = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(VendorPostingGroup; "Vendor Posting Group")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";
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
            column(ShowChart; ShowChart)
            {
            }
            column(LineText_1__Control1470004; LineText[1])
            {
            }
            column(TotalText_1_; TotalText[1])
            {
            }
            column(LineText_2__Control1470006; LineText[2])
            {
            }
            column(TotalText_2_; TotalText[2])
            {
            }
            column(TotalText_3_; TotalText[3])
            {
            }
            column(LineText_3__Control1470011; LineText[3])
            {
            }
            column(TotalText_4_; TotalText[4])
            {
            }
            column(LineText_4__Control1470014; LineText[4])
            {
            }
            column(LineText_5__Control1470017; LineText[5])
            {
            }
            column(TotalText_5_; TotalText[5])
            {
            }
            column(LineText_6__Control1470020; LineText[6])
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
            column(Vendor_Posting_GroupCaption; Vendor_Posting_GroupCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Turnover_SheetCaption; Turnover_SheetCaptionLbl)
            {
            }
            column(CodeCaption; CodeCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(Begining_period_balanceCaption; Begining_period_balanceCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(Net_Change_for_PeriodCaption; Net_Change_for_PeriodCaptionLbl)
            {
            }
            column(DebitCaption_Control24; DebitCaption_Control24Lbl)
            {
            }
            column(CreditCaption_Control27; CreditCaption_Control27Lbl)
            {
            }
            column(Ending_period_balanceCaption; Ending_period_balanceCaptionLbl)
            {
            }
            column(DebitCaption_Control30; DebitCaption_Control30Lbl)
            {
            }
            column(CreditCaption_Control31; CreditCaption_Control31Lbl)
            {
            }
            column(Total_Caption; Total_CaptionLbl)
            {
            }
            dataitem(Vendor; Vendor)
            {
                DataItemLink = "Vendor Posting Group" = field(Code);
                DataItemTableView = sorting("No.");
                RequestFilterFields = "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Date Filter";

                trigger OnAfterGetRecord()
                begin
                    Clear(LineAmount);
                    if StartDate > 0D then begin
                        SetRange("Date Filter", 0D, CalcDate('<-1D>', StartDate));
                        CalcFields("Net Change (LCY)");
                        RoundedValue := Round(Abs("Net Change (LCY)"), Decimals, '=');
                        if "Net Change (LCY)" > 0 then
                            LineAmount[1] := LineAmount[1] + RoundedValue
                        else
                            LineAmount[2] := LineAmount[2] + RoundedValue;
                    end;
                    SetRange("Date Filter", 0D, EndDate);
                    CalcFields("Net Change (LCY)");
                    RoundedValue := Round(Abs("Net Change (LCY)"), Decimals, '=');
                    if "Net Change (LCY)" > 0 then
                        LineAmount[5] := LineAmount[5] + RoundedValue
                    else
                        LineAmount[6] := LineAmount[6] + RoundedValue;
                    SetRange("Date Filter", StartDate, EndDate);
                    CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                    LineAmount[3] := LineAmount[3] + Round(Abs("Debit Amount (LCY)"), Decimals, '=');
                    LineAmount[4] := LineAmount[4] + Round(Abs("Credit Amount (LCY)"), Decimals, '=');
                end;

                trigger OnPreDataItem()
                begin
                    Clear(LineAmount);
                    Clear(LineText);
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(SkipZeroValues; SkipZeroValues)
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
                column(VendorPostingGroupURL; Format(VendorPostingGroupURL.RecordId, 0, 10))
                {
                }
                column(LineText_6_; LineText[6])
                {
                }
                column(LineText_5_; LineText[5])
                {
                }
                column(LineText_4_; LineText[4])
                {
                }
                column(LineText_3_; LineText[3])
                {
                }
                column(LineText_2_; LineText[2])
                {
                }
                column(LineText_1_; LineText[1])
                {
                }
                column(EmptyString; '')
                {
                }
                column(VendorPostingGroup_Code; VendorPostingGroup.Code)
                {
                }
                column(Integer_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if SkipZeroBalances and (LineAmount[5] = 0) and (LineAmount[6] = 0) then
                        CurrReport.Skip();

                    if SkipZeroNetChanges and (LineAmount[3] = 0) and (LineAmount[4] = 0) then
                        CurrReport.Skip();

                    if SkipZeroLines and
                      (LineAmount[1] = 0) and (LineAmount[2] = 0) and
                      (LineAmount[3] = 0) and (LineAmount[4] = 0) and
                      (LineAmount[5] = 0) and (LineAmount[6] = 0) then
                        CurrReport.Skip();

                    for I := 1 to 6 do
                        TotalAmount[I] += LineAmount[I];

                    TextLineValues(SkipZeroValues);
                end;
            }

            trigger OnAfterGetRecord()
            var
            begin
                VendorPostingGroupURL.SetPosition(GetPosition());
            end;

            trigger OnPreDataItem()
            begin
                VendorPostingGroupURL.Open(DATABASE::"Vendor Posting Group");
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
                        field("Replace zero values by blanks"; SkipZeroValues)
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
                        field(ShowChartControl; ShowChart)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Show Chart';
                            Visible = true;
                        }
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CurrentDate := LocMgt.Date2Text(Today()) + Format(Time(), 0, '(<Hours24>:<Minutes>)');
        RequestFilter := VendorPostingGroup.GetFilters();
        TotalPrinted := false;
        if Vendor.GetRangeMin("Date Filter") > 0D then
            StartDate := Vendor.GetRangeMin("Date Filter");
        EndDate := Vendor.GetRangeMax("Date Filter");
        FillReportParameters();
    end;

    var
        LocMgt: Codeunit "Localisation Management";
        LineAmount: array[10] of Decimal;
        TotalAmount: array[10] of Decimal;
        TotalText: array[10] of Text[30];
        LineText: array[10] of Text[30];
        RoundedValue: Decimal;
        StartDate: Date;
        EndDate: Date;
        RoundingPrecision: Option "0.01","1.00","1000";
        Decimals: Decimal;
        SkipZeroNetChanges: Boolean;
        SkipZeroValues: Boolean;
        SkipZeroLines: Boolean;
        SkipZeroBalances: Boolean;
        TotalPrinted: Boolean;
        PrintParameters: Boolean;
        CurrentDate: Text[30];
        RequestFilter: Text;
        AmountUnit: Text[30];
        ValueFormat: Text[50];
        ReportParameters: array[4] of Text[80];
        PeriodText: Text[100];
        Counter: Integer;
        I: Integer;
        VendorPostingGroupURL: RecordRef;
        ShowChart: Boolean;
        Vendor_Posting_GroupCaptionLbl: Label 'Vendor Posting Group';
        PageCaptionLbl: Label 'Page';
        Turnover_SheetCaptionLbl: Label 'Turnover Sheet';
        CodeCaptionLbl: Label 'Code';
        NameCaptionLbl: Label 'Name';
        Begining_period_balanceCaptionLbl: Label 'Begining period balance';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        Net_Change_for_PeriodCaptionLbl: Label 'Net Change for Period';
        DebitCaption_Control24Lbl: Label 'Debit';
        CreditCaption_Control27Lbl: Label 'Credit';
        Ending_period_balanceCaptionLbl: Label 'Ending period balance';
        DebitCaption_Control30Lbl: Label 'Debit';
        CreditCaption_Control31Lbl: Label 'Credit';
        Total_CaptionLbl: Label 'Total:';

    local procedure TextLineValues(ZeroBySpaces: Boolean)
    begin
        Clear(LineText);
        for I := 1 to 6 do
            LineText[I] := Value2Text(LineAmount[I], ZeroBySpaces);
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

