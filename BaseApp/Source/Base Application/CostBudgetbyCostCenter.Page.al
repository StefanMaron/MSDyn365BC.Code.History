page 1118 "Cost Budget by Cost Center"
{
    Caption = 'Cost Budget by Cost Center';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SourceTable = "Cost Type";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Rounding Factor';
                    OptionCaption = 'None,1,1000,1000000';
                    ToolTip = 'Specifies the factor that is used to round the amounts in the columns.';

                    trigger OnValidate()
                    begin
                        UpdateMatrixSubform;
                    end;
                }
                field(BudgetFilter; BudgetFilter)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Budget Filter';
                    TableRelation = "Cost Budget Name";
                    ToolTip = 'Specifies the budget name that you want to work on.';

                    trigger OnValidate()
                    begin
                        UpdateMatrixSubform;
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'View by';
                    OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        UpdateMatrixSubform;
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'View as';
                    OptionCaption = 'Balance at Date,Net Change';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        UpdateMatrixSubform;
                    end;
                }
            }
            part(MatrixForm; "Cost Bdgt. per Center Matrix")
            {
                ApplicationArea = CostAccounting;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Budge&t")
            {
                Caption = 'Budge&t';
                Image = LedgerBudget;
                action("By &Period")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'By &Period';
                    Image = Calendar;
                    RunObject = Page "Cost Budget per Period";
                    RunPageOnRec = true;
                    ToolTip = 'View a summary of the amount budgeted in different time periods.';
                }
                action("By Cost &Object")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'By Cost &Object';
                    Image = Cost;
                    RunObject = Page "Cost Budget by Cost Object";
                    RunPageOnRec = true;
                    ToolTip = 'View a summary of the amount budgeted for each cost object in different time periods.';
                }
                separator(Action5)
                {
                }
                action("&Budget / Movement")
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Budget / Movement';
                    Image = CostBudget;
                    RunObject = Page "Cost Type Balance/Budget";
                    RunPageOnRec = true;
                    ToolTip = 'View a summary of the net changes and the budgeted amounts for different time periods for the cost type that you select in the chart of cost types.';
                }
            }
        }
        area(processing)
        {
            action(PreviousSet)
            {
                ApplicationArea = CostAccounting;
                Caption = 'Previous Set';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Previous);
                    UpdateMatrixSubform;
                end;
            }
            action(PreviousColumn)
            {
                ApplicationArea = CostAccounting;
                Caption = 'Previous Column';
                Image = PreviousRecord;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Go to the previous column.';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::PreviousColumn);
                    UpdateMatrixSubform;
                end;
            }
            action(NextColumn)
            {
                ApplicationArea = CostAccounting;
                Caption = 'Next Column';
                Image = NextRecord;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Go to the next column.';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::NextColumn);
                    UpdateMatrixSubform;
                end;
            }
            action(NextSet)
            {
                ApplicationArea = CostAccounting;
                Caption = 'Next Set';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Next);
                    UpdateMatrixSubform;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        FindPeriod('');
        CostCenterMatrixRecord.SetCurrentKey("Sorting Order");
        MATRIX_CaptionFieldNo := 1;
        BudgetFilter := GetFilter("Budget Filter");
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
        UpdateMatrixSubform;
    end;

    var
        CostCenterMatrixRecords: array[12] of Record "Cost Center";
        CostCenterMatrixRecord: Record "Cost Center";
        MatrixMgt: Codeunit "Matrix Management";
        MatrixRecordRef: RecordRef;
        MATRIX_CaptionSet: array[12] of Text[80];
        MATRIX_CaptionRange: Text;
        MATRIX_PKFirstRecInCurrSet: Text;
        MATRIX_SetWanted: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        RoundingFactor: Option "None","1","1000","1000000";
        AmountType: Option "Balance at Date","Net Change";
        MATRIX_CaptionFieldNo: Integer;
        CurrentMatrixRecordOrdinal: Integer;
        MATRIX_CurrSetLength: Integer;
        BudgetFilter: Text;

    local procedure MATRIX_GenerateColumnCaptions(MATRIX_NewSetWanted: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn)
    begin
        Clear(MATRIX_CaptionSet);
        Clear(CostCenterMatrixRecords);
        CurrentMatrixRecordOrdinal := 1;

        CostCenterMatrixRecord.SetRange("Line Type", CostCenterMatrixRecord."Line Type"::"Cost Center");
        if CostCenterMatrixRecord.Find('-') then;

        MatrixRecordRef.GetTable(CostCenterMatrixRecord);
        MatrixRecordRef.SetTable(CostCenterMatrixRecord);

        MatrixMgt.GenerateMatrixData(MatrixRecordRef, MATRIX_NewSetWanted, ArrayLen(CostCenterMatrixRecords), MATRIX_CaptionFieldNo,
          MATRIX_PKFirstRecInCurrSet, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrSetLength);

        if MATRIX_CurrSetLength > 0 then begin
            CostCenterMatrixRecord.SetPosition(MATRIX_PKFirstRecInCurrSet);
            CostCenterMatrixRecord.Get(CostCenterMatrixRecord.Code);
            repeat
                CostCenterMatrixRecords[CurrentMatrixRecordOrdinal].Copy(CostCenterMatrixRecord);
                CurrentMatrixRecordOrdinal := CurrentMatrixRecordOrdinal + 1;
            until (CurrentMatrixRecordOrdinal > MATRIX_CurrSetLength) or (CostCenterMatrixRecord.Next <> 1);
        end;
    end;

    local procedure FindPeriod(FindTxt: Code[3])
    var
        Calendar: Record Date;
        PeriodFormMgt: Codeunit PeriodFormManagement;
    begin
        if GetFilter("Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", GetFilter("Date Filter"));
            if not PeriodFormMgt.FindDate('+', Calendar, PeriodType) then
                PeriodFormMgt.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodFormMgt.FindDate(FindTxt, Calendar, PeriodType);
        if AmountType = AmountType::"Net Change" then begin
            SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
            if GetRangeMin("Date Filter") = GetRangeMax("Date Filter") then
                SetRange("Date Filter", GetRangeMin("Date Filter"));
        end else
            SetRange("Date Filter", 0D, Calendar."Period End");
    end;

    local procedure UpdateMatrixSubform()
    begin
        CurrPage.MatrixForm.PAGE.Load(
          MATRIX_CaptionSet, CostCenterMatrixRecords, MATRIX_CurrSetLength, GetFilter("Date Filter"), BudgetFilter, RoundingFactor);
    end;
}

