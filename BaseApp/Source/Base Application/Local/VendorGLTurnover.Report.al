report 12451 "Vendor G/L Turnover"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/VendorGLTurnover.rdlc';
    Caption = 'Vendor G/L Turnover';

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Vendor Posting Group", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Date Filter";
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
            column(PrintAgreements; PrintAgreements)
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(Vendor__G_L_Starting_Balance_; "G/L Starting Balance")
            {
            }
            column(G_L_Starting_Balance_; -"G/L Starting Balance")
            {
            }
            column(Vendor__G_L_Debit_Amount_; "G/L Debit Amount")
            {
            }
            column(Vendor__G_L_Credit_Amount_; "G/L Credit Amount")
            {
            }
            column(Vendor__G_L_Balance_to_Date_; "G/L Balance to Date")
            {
            }
            column(G_L_Balance_to_Date_; -"G/L Balance to Date")
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(Vendor__G_L_Starting_Balance__Control1210049; "G/L Starting Balance")
            {
            }
            column(G_L_Starting_Balance__Control1210052; -"G/L Starting Balance")
            {
            }
            column(G_L_Debit_Amount_____G_L_Credit_Amount_; "G/L Debit Amount" - "G/L Credit Amount")
            {
            }
            column(G_L_Credit_Amount_____G_L_Debit_Amount_; "G/L Credit Amount" - "G/L Debit Amount")
            {
            }
            column(Vendor__G_L_Balance_to_Date__Control1210058; "G/L Balance to Date")
            {
            }
            column(G_L_Balance_to_Date__Control1210059; -"G/L Balance to Date")
            {
            }
            column(Vendor__G_L_Debit_Amount__Control1210061; "G/L Debit Amount")
            {
            }
            column(Vendor__G_L_Credit_Amount__Control1210062; "G/L Credit Amount")
            {
            }
            column(StartBalanceDebit; StartBalanceDebit)
            {
            }
            column(StartBalanceCredit; StartBalanceCredit)
            {
            }
            column(EndBalanceDebit; EndBalanceDebit)
            {
            }
            column(EndBalanceCredit; EndBalanceCredit)
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
            column(VendorCaption; VendorCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(G_L_Turnover_SheetCaption; G_L_Turnover_SheetCaptionLbl)
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
            column(SourceCaption; SourceCaptionLbl)
            {
            }
            column(G_L_EntriesCaption; G_L_EntriesCaptionLbl)
            {
            }
            column(Detailed_Total_Caption; Detailed_Total_CaptionLbl)
            {
            }
            column(Total_Caption; Total_CaptionLbl)
            {
            }
            column(Vendor_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Vendor_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Vendor_G_L_Account_Filter; "G/L Account Filter")
            {
            }
            column(Vendor_Date_Filter; "Date Filter")
            {
            }
            column(TotalStartBalanceDebit; TotalStartBalanceDebit)
            {
            }
            column(TotalStartBalanceCredit; TotalStartBalanceCredit)
            {
            }
            column(TotalEndBalanceDebit; TotalEndBalanceDebit)
            {
            }
            column(TotalEndBalanceCredit; TotalEndBalanceCredit)
            {
            }
            column(TotalGLDebitAmount; TotalGLDebitAmount)
            {
            }
            column(TotalGLCreditAmount; TotalGLCreditAmount)
            {
            }
            column(TotalGLDebitCreditDiff; TotalGLDebitCreditDiff)
            {
            }
            column(TotalGLCreditDebitDiff; TotalGLCreditDebitDiff)
            {
            }
            dataitem("Vendor Agreement"; "Vendor Agreement")
            {
                DataItemLink = "Vendor No." = FIELD("No."), "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"), "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"), "G/L Account Filter" = FIELD("G/L Account Filter"), "Date Filter" = FIELD("Date Filter");
                DataItemTableView = SORTING("Vendor No.", "No.");
                column(Vendor_Agreement__No__; "No.")
                {
                }
                column(Vendor_Agreement_Description; Description)
                {
                }
                column(Vendor_Agreement__G_L_Starting_Balance_; "G/L Starting Balance")
                {
                }
                column(G_L_Starting_Balance__Control1210037; -"G/L Starting Balance")
                {
                }
                column(Vendor_Agreement__G_L_Debit_Amount_; "G/L Debit Amount")
                {
                }
                column(Vendor_Agreement__G_L_Credit_Amount_; "G/L Credit Amount")
                {
                }
                column(Vendor_Agreement__G_L_Balance_to_Date_; "G/L Balance to Date")
                {
                }
                column(G_L_Balance_to_Date__Control1210045; -"G/L Balance to Date")
                {
                }
                column(G_L_EntriesCaption_Control1210070; G_L_EntriesCaption_Control1210070Lbl)
                {
                }
                column(Vendor_Agreement_Vendor_No_; "Vendor No.")
                {
                }
                column(Vendor_Agreement_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
                {
                }
                column(Vendor_Agreement_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
                {
                }
                column(Vendor_Agreement_G_L_Account_Filter; "G/L Account Filter")
                {
                }
                column(Vendor_Agreement_Date_Filter; "Date Filter")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if StartDate > 0D then begin
                        SetRange("G/L Starting Date Filter", StartDate - 1);
                        CalcFields("G/L Starting Balance");
                        SetRange("Date Filter", 0D, StartDate - 1);
                        CalcFields("Net Change (LCY)");
                        VendStartBalance := "Net Change (LCY)";
                    end;

                    SetRange("Date Filter", StartDate, EndDate);
                    CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)", "G/L Debit Amount", "G/L Credit Amount", "G/L Balance to Date");

                    SetRange("Date Filter", 0D, EndDate);
                    CalcFields("Net Change (LCY)");

                    "G/L Starting Balance" := RoundAmount("G/L Starting Balance");
                    "G/L Debit Amount" := RoundAmount("G/L Debit Amount");
                    "G/L Credit Amount" := RoundAmount("G/L Credit Amount");
                    "G/L Balance to Date" := RoundAmount("G/L Balance to Date");

                    if SkipZeroLines and
                      ("G/L Starting Balance" = 0) and ("G/L Balance to Date" = 0) and
                      ("G/L Debit Amount" = 0) and ("G/L Credit Amount" = 0)
                    then
                        CurrReport.Skip();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if GLAccFilter = '' then begin
                    if not VendPostingGr.Get("Vendor Posting Group") then
                        CurrReport.Skip();
                    SetFilter("G/L Account Filter", '%1|%2', VendPostingGr."Payables Account", VendPostingGr."Prepayment Account");
                end;

                if StartDate > 0D then begin
                    SetRange("G/L Starting Date Filter", StartDate - 1);
                    CalcFields("G/L Starting Balance");
                    SetRange("Date Filter", 0D, StartDate - 1);
                    CalcFields("Net Change (LCY)");
                    VendStartBalance := "Net Change (LCY)";
                end;

                SetRange("Date Filter", StartDate, EndDate);
                CalcFields("G/L Debit Amount", "G/L Credit Amount", "G/L Balance to Date");

                SetRange("Date Filter", 0D, EndDate);
                CalcFields("Net Change (LCY)");

                "G/L Starting Balance" := RoundAmount("G/L Starting Balance");
                "G/L Debit Amount" := RoundAmount("G/L Debit Amount");
                "G/L Credit Amount" := RoundAmount("G/L Credit Amount");
                "G/L Balance to Date" := RoundAmount("G/L Balance to Date");
                VendStartBalance := RoundAmount(VendStartBalance);
                "Net Change (LCY)" := RoundAmount("Net Change (LCY)");

                TotalGLDebitAmount += "G/L Debit Amount";
                TotalGLCreditAmount += "G/L Credit Amount";

                TotalGLDebitCreditDiff += "G/L Debit Amount" - "G/L Credit Amount";
                TotalGLCreditDebitDiff += "G/L Credit Amount" - "G/L Debit Amount";

                UpdateBalance("G/L Starting Balance", StartBalanceDebit, StartBalanceCredit);
                UpdateBalance("G/L Balance to Date", EndBalanceDebit, EndBalanceCredit);

                TotalStartBalance += "G/L Starting Balance";
                UpdateBalanceTotal(TotalStartBalance, TotalStartBalanceDebit, TotalStartBalanceCredit);

                TotalEndBalance += "G/L Balance to Date";
                UpdateBalanceTotal(TotalEndBalance, TotalEndBalanceDebit, TotalEndBalanceCredit);

                if SkipZeroLines and
                  ("G/L Starting Balance" = 0) and ("G/L Balance to Date" = 0) and
                  ("G/L Debit Amount" = 0) and ("G/L Credit Amount" = 0)
                then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                GLAccFilter := GetFilter("G/L Account Filter");
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
                        }
                        field("Print Agreements"; PrintAgreements)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Print Agreements';
                        }
                        field("Skip zero lines"; SkipZeroLines)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip zero lines';
                        }
                        field("Blank zero values"; SkipZeroValues)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Blank zero values';
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
        RequestFilter := Vendor.GetFilters();
        if Vendor.GetRangeMin("Date Filter") > 0D then
            StartDate := Vendor.GetRangeMin("Date Filter");
        EndDate := Vendor.GetRangeMax("Date Filter");
        FillReportParameters();
    end;

    var
        Text003: Label 'Zero values are replaced by spacebar';
        Text005: Label 'for period from ';
        Text006: Label ' to ';
        GLSetup: Record "General Ledger Setup";
        VendPostingGr: Record "Vendor Posting Group";
        LocMgt: Codeunit "Localisation Management";
        GLAccFilter: Text;
        StartDate: Date;
        EndDate: Date;
        RoundingPrecision: Option "0.01","1.00","1000";
        Decimals: Decimal;
        SkipZeroValues: Boolean;
        SkipZeroLines: Boolean;
        TotalPrinted: Boolean;
        PrintParameters: Boolean;
        PrintTotals: Boolean;
        PrintAgreements: Boolean;
        CurrentDate: Text[30];
        RequestFilter: Text;
        AmountUnit: Text[30];
        ValueFormat: Text[50];
        ReportParameters: array[4] of Text[80];
        PeriodText: Text[100];
        Counter: Integer;
        I: Integer;
        StartBalanceDebit: Decimal;
        StartBalanceCredit: Decimal;
        EndBalanceDebit: Decimal;
        EndBalanceCredit: Decimal;
        VendStartBalance: Decimal;
        VendorCaptionLbl: Label 'Vendor';
        PageCaptionLbl: Label 'Page';
        G_L_Turnover_SheetCaptionLbl: Label 'G/L Turnover Sheet';
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
        SourceCaptionLbl: Label 'Source';
        G_L_EntriesCaptionLbl: Label 'G/L Entries';
        Detailed_Total_CaptionLbl: Label 'Detailed Total:';
        Total_CaptionLbl: Label 'Total:';
        G_L_EntriesCaption_Control1210070Lbl: Label 'G/L Entries';
        TotalStartBalance: Decimal;
        TotalStartBalanceDebit: Decimal;
        TotalStartBalanceCredit: Decimal;
        TotalEndBalance: Decimal;
        TotalEndBalanceDebit: Decimal;
        TotalEndBalanceCredit: Decimal;
        TotalGLDebitAmount: Decimal;
        TotalGLCreditAmount: Decimal;
        TotalGLDebitCreditDiff: Decimal;
        TotalGLCreditDebitDiff: Decimal;

    [Scope('OnPrem')]
    procedure FillReportParameters()
    var
        Text001: Label 'for period from %1 to %2';
        Text006: Label 'Skip lines with zero values';
        Text007: Label '(in currency units)';
        Text008: Label '(in thousands)';
    begin
        case RoundingPrecision of
            RoundingPrecision::"0.01":
                begin
                    Decimals := 0.01;
                    AmountUnit := '';
                end;
            RoundingPrecision::"1.00":
                begin
                    Decimals := 1;
                    AmountUnit := Text007;
                end;
            RoundingPrecision::"1000":
                begin
                    Decimals := 1000;
                    AmountUnit := Text008;
                end;
        end;
        Counter := 0;
        if SkipZeroValues then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text003;
        end;
        if SkipZeroLines then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text006;
        end;

        PeriodText := StrSubstNo(Text001, StartDate, EndDate);
        PrintParameters := Counter > 0;
    end;

    [Scope('OnPrem')]
    procedure RoundAmount(Amount: Decimal): Decimal
    begin
        Amount := Round(Amount, Decimals, '=');
        if Decimals > 1 then
            Amount := Amount / Decimals;
        exit(Amount)
    end;

    local procedure UpdateBalance(Amount: Decimal; var AmountDebit: Decimal; var AmountCredit: Decimal)
    begin
        if Amount > 0 then
            AmountDebit += Amount
        else
            AmountCredit += Abs(Amount);
    end;

    local procedure UpdateBalanceTotal(Amount: Decimal; var AmountDebit: Decimal; var AmountCredit: Decimal)
    begin
        if Amount > 0 then begin
            AmountDebit := Amount;
            AmountCredit := 0;
        end else begin
            AmountDebit := 0;
            AmountCredit := Abs(Amount);
        end;
    end;
}

