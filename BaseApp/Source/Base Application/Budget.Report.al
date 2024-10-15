report 8 Budget
{
    DefaultLayout = RDLC;
    RDLCLayout = './Budget.rdlc';
    ApplicationArea = Suite;
    Caption = 'Budget';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Account Type", "Budget Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(GLBudgetFilter; GLBudgetFilter)
            {
            }
            column(NoOfBlankLines_GLAcc; "No. of Blank Lines")
            {
            }
            column(AmtsInThousands; InThousands)
            {
            }
            column(GLFilterTableCaption_GLAcc; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(Type_GLAcc; "Account Type")
            {
            }
            column(AccountTypePosting; GLAccountTypePosting)
            {
            }
            column(PeriodStartDate1; PeriodStartDateCaption[1])
            {
            }
            column(PeriodStartDate2; PeriodStartDateCaption[2])
            {
            }
            column(PeriodStartDate3; PeriodStartDateCaption[3])
            {
            }
            column(PeriodStartDate4; PeriodStartDateCaption[4])
            {
            }
            column(PeriodStartDate5; PeriodStartDateCaption[5])
            {
            }
            column(PeriodStartDate6; PeriodStartDateCaption[6])
            {
            }
            column(PeriodStartDate7; PeriodStartDateCaption[7])
            {
            }
            column(PeriodStartDate8; PeriodStartDateCaption[8])
            {
            }
            column(PeriodStartDate9; PeriodStartDateCaption[9])
            {
            }
            column(PeriodStartDate10; PeriodStartDateCaption[10])
            {
            }
            column(PeriodStartDate11; PeriodStartDateCaption[11])
            {
            }
            column(PeriodStartDate12; PeriodStartDateCaption[12])
            {
            }
            column(PeriodStartDate21; PeriodStartDateCaption[13])
            {
            }
            column(PeriodStartDate31; PeriodStartDateCaption[14])
            {
            }
            column(PeriodStartDate41; PeriodStartDateCaption[15])
            {
            }
            column(PeriodStartDate51; PeriodStartDateCaption[16])
            {
            }
            column(PeriodStartDate61; PeriodStartDateCaption[17])
            {
            }
            column(PeriodStartDate71; PeriodStartDateCaption[18])
            {
            }
            column(PeriodStartDate81; PeriodStartDateCaption[19])
            {
            }
            column(PeriodStartDate91; PeriodStartDateCaption[20])
            {
            }
            column(PeriodStartDate101; PeriodStartDateCaption[21])
            {
            }
            column(PeriodStartDate111; PeriodStartDateCaption[22])
            {
            }
            column(PeriodStartDate121; PeriodStartDateCaption[23])
            {
            }
            column(PeriodStartDate131; PeriodStartDateCaption[24])
            {
            }
            column(No_GLAcc; "No.")
            {
                IncludeCaption = true;
            }
            column(BudgetCaption; BudgetCaptionTxt)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(BudgetFilterCaption; BudgetFilterCaptionLbl)
            {
            }
            column(AmtsAreInwhole1000sCaptn; AmtsAreInwhole1000sCaptnLbl)
            {
            }
            column(GLAccNameCaption; GLAccNameCaptionLbl)
            {
            }
            column(TotalCaption; TotalLbl)
            {
            }
            column(RowNumber; RowNumber)
            {
            }
            column(StartingDateAsText; StartingDateAsText)
            {
            }
            dataitem(BlankLineCounter; "Integer")
            {
                DataItemTableView = SORTING(Number);

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, "G/L Account"."No. of Blank Lines");
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(GLAccNo_BlankLineCounter; "G/L Account"."No.")
                {
                    IncludeCaption = true;
                }
                column(PADSTRIndentName_GLAcc; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(GLBudgetedAmount1; GLBudgetedAmount[1])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLBudgetedAmount2; GLBudgetedAmount[2])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLBudgetedAmount3; GLBudgetedAmount[3])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLBudgetedAmount4; GLBudgetedAmount[4])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLBudgetedAmount5; GLBudgetedAmount[5])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLBudgetedAmount6; GLBudgetedAmount[6])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLBudgetedAmount7; GLBudgetedAmount[7])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLBudgetedAmount8; GLBudgetedAmount[8])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLBudgetedAmount9; GLBudgetedAmount[9])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLBudgetedAmount10; GLBudgetedAmount[10])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLBudgetedAmount11; GLBudgetedAmount[11])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLBudgetedAmount12; GLBudgetedAmount[12])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(TotalBudgetAmount; TotalBudgetAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
            }

            trigger OnAfterGetRecord()
            begin
                TotalBudgetAmount := 0;
                for i := 1 to ArrayLen(GLBudgetedAmount) do begin
                    SetRange("Date Filter", PeriodStartDate[i], PeriodStartDate[i + 1] - 1);
                    CalcFields("Budgeted Amount");
                    if InThousands then
                        "Budgeted Amount" := "Budgeted Amount" / 1000;
                    GLBudgetedAmount[i] := MatrixMgt.RoundAmount("Budgeted Amount", RndFactor);
                    TotalBudgetAmount += GLBudgetedAmount[i];
                end;
                SetRange("Date Filter", PeriodStartDate[1], PeriodStartDate[ArrayLen(PeriodStartDate)] - 1);

                GLAccountTypePosting := "Account Type" = "Account Type"::Posting;
                RowNumber += 1;
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
                    field(StartingDate; PeriodStartDate[1])
                    {
                        ApplicationArea = Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Period Length';
                        Editable = false;
                        Enabled = false;
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(InThousands; InThousands)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Amounts in whole 1000s';
                        ToolTip = 'Specifies if the amounts in the report are shown in whole 1000s.';
                    }
                    field(RoundingFactor; RndFactor)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Rounding Factor';
                        ToolTip = 'Specifies the factor that is used to round the amounts.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartDate[1] = 0D then
                PeriodStartDate[1] := CalcDate('<-CY+1D>', WorkDate);
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GLFilter := "G/L Account".GetFilters;
        GLBudgetFilter := "G/L Account".GetFilter("Budget Filter");
        if PeriodStartDate[1] = 0D then
            PeriodStartDate[1] := WorkDate;
        for i := 2 to ArrayLen(PeriodStartDate) do
            PeriodStartDate[i] := CalcDate(PeriodLength, PeriodStartDate[i - 1]);

        // NAVCZ
        for i := 1 to ArrayLen(PeriodStartDate) - 1 do begin
            PeriodStartDateCaption[i] := CreatePeriodFormat(PeriodStartDate[i]);
            PeriodStartDateCaption[i + 12] := CreatePeriodFormat(PeriodStartDate[i + 1] - 1);
        end;
        // NAVCZ

        BudgetCaptionTxt := StrSubstNo(BudgetCaptionTok, Format(PeriodStartDate[1], 0, '<Year4>'));
        StartingDateAsText := StrSubstNo(StartingDateTok, PeriodStartDate[1]);
    end;

    var
        MatrixMgt: Codeunit "Matrix Management";
        InThousands: Boolean;
        GLFilter: Text;
        GLBudgetFilter: Text[250];
        BudgetCaptionTxt: Text;
        PeriodStartDateCaption: array[24] of Text;
        GlobalLanguageCode: Code[10];
        PeriodLength: DateFormula;
        GLBudgetedAmount: array[12] of Decimal;
        TotalBudgetAmount: Decimal;
        PeriodStartDate: array[13] of Date;
        i: Integer;
        BudgetCaptionTok: Label 'Budget for %1', Comment = '%1 - year';
        PageCaptionLbl: Label 'Page';
        BudgetFilterCaptionLbl: Label 'Budget Filter';
        AmtsAreInwhole1000sCaptnLbl: Label 'Amounts are in whole 1000s.';
        GLAccNameCaptionLbl: Label 'Name';
        RowNumber: Integer;
        GLAccountTypePosting: Boolean;
        RndFactor: Enum "Analysis Rounding Factor";
        TotalLbl: Label 'Total';
        StartingDateAsText: Text;
        StartingDateTok: Label 'Starting Date: %1', Comment = '%1 - date';

    procedure InitializeRequest(NewPeriodStartDate: Date; NewPeriodLength: Text[30]; NewInThousands: Boolean)
    begin
        PeriodStartDate[1] := NewPeriodStartDate;
        Evaluate(PeriodLength, NewPeriodLength);
        InThousands := NewInThousands;
    end;

    local procedure CreatePeriodFormat(Date: Date): Text[10]
    begin
        // NAVCZ
        if GetGlobalLanguageCode = 'CSY' then
            case Date2DMY(Date, 2) of
                6:
                    exit('©vn');
                7:
                    exit('©vc');
            end;

        exit(Format(Date, 0, '<Month Text,3>'));
    end;

    local procedure GetGlobalLanguageCode(): Code[10]
    var
        Language: Codeunit Language;
    begin
        // NAVCZ
        if GlobalLanguageCode = '' then
            GlobalLanguageCode := Language.GetLanguageCode(GlobalLanguage);

        exit(GlobalLanguageCode);
    end;

#if not CLEAN19
    [Obsolete('Replaced by SetRoundingFactor().', '19.0')]
    procedure SetParameters(NewRoundingFactor: Option "None","1","1000","1000000")
    begin
        RndFactor := "Analysis Rounding Factor".FromInteger(NewRoundingFactor);
    end;
#endif

    procedure SetRoundingFactor(NewRoundingFactor: Enum "Analysis Rounding Factor")
    begin
        RndFactor := NewRoundingFactor;
    end;
}

