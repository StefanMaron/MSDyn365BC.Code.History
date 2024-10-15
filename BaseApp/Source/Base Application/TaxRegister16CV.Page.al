page 17223 "Tax Register (1.6) CV"
{
    Caption = 'Tax Register (1.6) CV';
    DataCaptionExpression = FormTitle();
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Tax Register CV Entry";
    SourceTableView = SORTING("Section Code", "Register Type")
                      WHERE("Register Type" = CONST("Debit Balance"),
                            "CV Debit Balance Amnt 2-4" = FILTER(<> 0));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("C/V No."; "C/V No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No.';
                    ToolTip = 'Specifies the creditor or debtor number associated with the tax register debtor or creditor entry.';
                }
                field(ObjectName; ObjectName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the related record.';
                }
                field("CV Debit Balance Amnt 2-4"; "CV Debit Balance Amnt 2-4")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the creditor or debtor debit balance amount associated with the tax register debtor or creditor entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDownCVLedgerAmount(FilterDueDateTotal45Days, true, true);
                    end;
                }
                field("CV Debit Balance Amnt 2"; "CV Debit Balance Amnt 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the creditor or debtor debit balance amount associated with the tax register debtor or creditor entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDownCVLedgerAmount(FilterDueDate45Days, true, true);
                    end;
                }
                field("CV Debit Balance Amnt 3"; "CV Debit Balance Amnt 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the creditor or debtor debit balance amount associated with the tax register debtor or creditor entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDownCVLedgerAmount(FilterDueDate90Days, true, true);
                    end;
                }
                field("CV Debit Balance Amnt 4"; "CV Debit Balance Amnt 4")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the creditor or debtor debit balance amount associated with the tax register debtor or creditor entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDownCVLedgerAmount(FilterDueDate3Years, true, true);
                    end;
                }
            }
            field(PeriodType; PeriodType)
            {
                ApplicationArea = Basic, Suite;
                OptionCaption = ',,Month,Quarter,Year';
                ToolTip = 'Month';

                trigger OnValidate()
                begin
                    FindPeriod('');
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Previous Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Previous Period';

                trigger OnAction()
                begin
                    FindPeriod('<=');
                end;
            }
            action("Next Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Image = NextRecord;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Next Period';

                trigger OnAction()
                begin
                    FindPeriod('>=');
                end;
            }
            action("Create Closing Entries")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Closing Entries';
                Image = CreateDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    CreateGenJnlLine;
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if DateFilterText <> GetFilter("Date Filter") then
            ShowNewData;

        exit(Find(Which));
    end;

    trigger OnOpenPage()
    begin
        CopyFilter("Date Filter", Calendar."Period End");
        TaxRegMgt.SetPeriodAmountType(Calendar, DateFilterText, PeriodType, AmountType);
        Calendar.Reset();
        FilterGroup(2);
        SectionCode := GetRangeMin("Section Code");
        FilterGroup(0);
        ShowNewData;
    end;

    var
        Calendar: Record Date;
        TaxRegMgt: Codeunit "Tax Register Mgt.";
        FilterDueDateTotal45Days: Text[30];
        FilterDueDate45Days: Text[30];
        FilterDueDate90Days: Text[30];
        FilterDueDate3Years: Text[30];
        DateFilterText: Text;
        AmountType: Option "Current Period","Tax Period";
        PeriodType: Option ,,Month,Quarter,Year;
        SectionCode: Code[10];

    [Scope('OnPrem')]
    procedure ShowNewData()
    var
        UsingDate: Date;
    begin
        if GetFilter("Date Filter") = '' then
            UsingDate := CalcDate('<CM-1M>', WorkDate)
        else
            UsingDate := GetRangeMax("Date Filter");

        SetRange("Ending Date", UsingDate);
        SetFilter("Date Filter", '..%1', UsingDate);
        DateFilterText := GetFilter("Date Filter");

        TaxRegMgt.CalcDebitBalancePointDate(SectionCode, GetRangeMax("Date Filter"),
          FilterDueDateTotal45Days, FilterDueDate45Days, FilterDueDate90Days, FilterDueDate3Years);
    end;

    local procedure FindPeriod(SearchText: Code[10])
    begin
        if GetFilter("Date Filter") <> '' then begin
            Calendar."Period End" := GetRangeMax("Date Filter");
            if not TaxRegMgt.FindDate('', Calendar, PeriodType, AmountType::"Tax Period") then
                TaxRegMgt.FindDate('', Calendar, PeriodType::Month, AmountType::"Tax Period");
        end;
        TaxRegMgt.FindDate(SearchText, Calendar, PeriodType, AmountType::"Tax Period");

        SetFilter("Date Filter", '..%1', Calendar."Period End");
    end;

    [Scope('OnPrem')]
    procedure CreateGenJnlLine()
    var
        CreateClosingGenJnlLine: Report "Create Closing Gen. Jnl. Line";
    begin
        CreateClosingGenJnlLine.SetSearching("Section Code", "Ending Date", true, FilterDueDate3Years);
        CreateClosingGenJnlLine.RunModal();
    end;
}

