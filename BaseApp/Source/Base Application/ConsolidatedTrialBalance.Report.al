report 17 "Consolidated Trial Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ConsolidatedTrialBalance.rdlc';
    ApplicationArea = Suite;
    Caption = 'Consolidated Trial Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "G/L Entry Type Filter";
            column(PeriodText; StrSubstNo(Text002, PeriodText))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(GLAccountGLFilter; "G/L Account".TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(InclSimulationEntries; InclSimulationEntriesLbl)
            {
            }
            column(GLEntryTypeFilter_GLAcc; "G/L Account".GetFilter("G/L Entry Type Filter"))
            {
            }
            column(No_GLAcc; "No.")
            {
                IncludeCaption = true;
            }
            column(AccType_GLAcc; "G/L Account"."Account Type")
            {
            }
            column(AccountTypePosting; GLAccountTypePosting)
            {
            }
            column(ConsolidatedTrialBalanceCaption; ConsolidatedTrialBalanceCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(AmtsInwhole1000sCaption; AmtsInwhole1000sCaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(AmtInclEliminationsCaption; AmtInclEliminationsCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(NetChangeCaption; NetChangeCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(EliminationsCaption; EliminationsCaptionLbl)
            {
            }
            column(NetChangeCaption1; NetChangeCaption1Lbl)
            {
            }
            column(AccountType; AccountTypeLbl)
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
                column(No1_GLAcc; "G/L Account"."No.")
                {
                    IncludeCaption = true;
                }
                column(Indentation2Name_GLAcc; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
            }
            dataitem("Business Unit"; "Business Unit")
            {
                DataItemTableView = SORTING(Code) WHERE(Consolidate = CONST(true));
                column(Indentation22Code_GLAcc; PadStr('', "G/L Account".Indentation * 2 + 2) + Code)
                {
                }
                column(Balance_GLAcc; GLBalance)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(GLAccNetChange; GLAccNetChange)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }

                trigger OnAfterGetRecord()
                begin
                    "G/L Account".SetRange("Business Unit Filter", Code);
                    if ("Starting Date" <> 0D) or ("Ending Date" <> 0D) then
                        "G/L Account".SetRange("Date Filter", "Starting Date", "Ending Date")
                    else
                        "G/L Account".SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);

                    "G/L Account".CalcFields("Net Change", "Balance at Date");
                    GLAccNetChange := "G/L Account"."Net Change";
                    GLBalance := "G/L Account"."Balance at Date";

                    if (GLAccNetChange = 0) and (GLBalance = 0) then
                        CurrReport.Skip();

                    if InThousands then begin
                        GLAccNetChange := GLAccNetChange / 1000;
                        GLBalance := GLBalance / 1000;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(GLAccNetChange);
                    Clear(GLBalance);
                end;
            }
            dataitem(ConsolidCounter; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(Indentation2Name2_GLAcc; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(GLAccNetChange1; GLAccNetChange)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(EliminationAmount; EliminationAmount)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(NetChange_GLAcc_ElmnAmt; GLAccNetChange + EliminationAmount)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(Balance_GLAcc_ElmnAmt; GLBalance + EliminationAmount)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(InThousands; InThousands)
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(GLAcc_NewPage; "G/L Account"."New Page")
                {
                }
                column(GLAcc_NoOfBlankLines; "G/L Account"."No. of Blank Lines")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    "G/L Account".SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);
                    "G/L Account".SetRange("Business Unit Filter", '');
                    "G/L Account".CalcFields("Net Change");
                    EliminationAmount := "G/L Account"."Net Change";
                    if InThousands then
                        EliminationAmount := EliminationAmount / 1000;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                PageGroupNo := NextPageGroupNo;
                if "New Page" then
                    NextPageGroupNo := PageGroupNo + 1;

                GLAccountTypePosting := "Account Type" = "Account Type"::Posting;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                NextPageGroupNo := 1;
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
                        field(StartingDt; ConsolidStartDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Starting Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the first date in the period from which posted entries in the consolidated company will be shown.';
                        }
                        field(EndingDt; ConsolidEndDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Ending Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the end date for the period to process. If a business unit has a different fiscal year than the group, enter the end date for this company in the Business Unit window.';
                        }
                    }
                    field(InThousands; InThousands)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Amounts in whole 1000s';
                        ToolTip = 'Specifies if the amounts in the report are shown in whole 1000s.';
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
        if ConsolidStartDate = 0D then
            Error(Text000);
        if ConsolidEndDate = 0D then
            Error(Text001);
        GLFilter := "G/L Account".GetFilters();
        "G/L Account".SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);
        PeriodText := "G/L Account".GetFilter("Date Filter");
    end;

    var
        Text000: Label 'Enter the starting date for the consolidation period.';
        Text001: Label 'Enter the ending date for the consolidation period.';
        Text002: Label 'Period: %1';
        InThousands: Boolean;
        ConsolidStartDate: Date;
        ConsolidEndDate: Date;
        GLAccNetChange: Decimal;
        GLBalance: Decimal;
        EliminationAmount: Decimal;
        PeriodText: Text;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        InclSimulationEntriesLbl: Label 'This report includes simulation entries.';
        ConsolidatedTrialBalanceCaptionLbl: Label 'Consolidated Trial Balance';
        PageNoCaptionLbl: Label 'Page';
        AmtsInwhole1000sCaptionLbl: Label 'Amounts are in whole 1000s.';
        AmountCaptionLbl: Label 'Amount';
        AmtInclEliminationsCaptionLbl: Label 'Amount Incl. Eliminations';
        NameCaptionLbl: Label 'Name';
        NetChangeCaptionLbl: Label 'Net Change';
        BalanceCaptionLbl: Label 'Balance';
        EliminationsCaptionLbl: Label 'Eliminations';
        NetChangeCaption1Lbl: Label 'Net Change';
        AccountTypeLbl: Label 'Posting';
        GLAccountTypePosting: Boolean;

    protected var
        GLFilter: Text;
}

