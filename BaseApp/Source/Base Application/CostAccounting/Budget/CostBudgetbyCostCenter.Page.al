namespace Microsoft.CostAccounting.Budget;

using Microsoft.CostAccounting.Account;
using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

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
                    ToolTip = 'Specifies the factor that is used to round the amounts in the columns.';

                    trigger OnValidate()
                    begin
                        UpdateMatrixSubform();
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
                        UpdateMatrixSubform();
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        UpdateMatrixSubform();
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        UpdateMatrixSubform();
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
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions("Matrix Page Step Type"::Previous);
                    UpdateMatrixSubform();
                end;
            }
            action(PreviousColumn)
            {
                ApplicationArea = CostAccounting;
                Caption = 'Previous Column';
                Image = PreviousRecord;
                ToolTip = 'Go to the previous column.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions("Matrix Page Step Type"::PreviousColumn);
                    UpdateMatrixSubform();
                end;
            }
            action(NextColumn)
            {
                ApplicationArea = CostAccounting;
                Caption = 'Next Column';
                Image = NextRecord;
                ToolTip = 'Go to the next column.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions("Matrix Page Step Type"::NextColumn);
                    UpdateMatrixSubform();
                end;
            }
            action(NextSet)
            {
                ApplicationArea = CostAccounting;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    GenerateColumnCaptions("Matrix Page Step Type"::Next);
                    UpdateMatrixSubform();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(PreviousSet_Promoted; PreviousSet)
                {
                }
                actionref(PreviousColumn_Promoted; PreviousColumn)
                {
                }
                actionref(NextColumn_Promoted; NextColumn)
                {
                }
                actionref(NextSet_Promoted; NextSet)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        FindPeriod('');
        CostCenterMatrixRecord.SetCurrentKey("Sorting Order");
        MATRIX_CaptionFieldNo := 1;
        BudgetFilter := Rec.GetFilter("Budget Filter");
        GenerateColumnCaptions("Matrix Page Step Type"::Initial);
        UpdateMatrixSubform();
    end;

    var
        CostCenterMatrixRecords: array[12] of Record "Cost Center";
        CostCenterMatrixRecord: Record "Cost Center";
        MatrixMgt: Codeunit "Matrix Management";
        MatrixRecordRef: RecordRef;
        MATRIX_CaptionSet: array[12] of Text[80];
        MATRIX_CaptionRange: Text;
        MATRIX_PKFirstRecInCurrSet: Text;
        PeriodType: Enum "Analysis Period Type";
        RoundingFactor: Enum "Analysis Rounding Factor";
        AmountType: Enum "Analysis Amount Type";
        MATRIX_CaptionFieldNo: Integer;
        CurrentMatrixRecordOrdinal: Integer;
        MATRIX_CurrSetLength: Integer;
        BudgetFilter: Text;

    local procedure GenerateColumnCaptions(StepType: Enum "Matrix Page Step Type")
    begin
        Clear(MATRIX_CaptionSet);
        Clear(CostCenterMatrixRecords);
        CurrentMatrixRecordOrdinal := 1;

        CostCenterMatrixRecord.SetRange("Line Type", CostCenterMatrixRecord."Line Type"::"Cost Center");
        if CostCenterMatrixRecord.Find('-') then;

        MatrixRecordRef.GetTable(CostCenterMatrixRecord);
        MatrixRecordRef.SetTable(CostCenterMatrixRecord);

        MatrixMgt.GenerateMatrixData(MatrixRecordRef, StepType.AsInteger(), ArrayLen(CostCenterMatrixRecords), MATRIX_CaptionFieldNo,
          MATRIX_PKFirstRecInCurrSet, MATRIX_CaptionSet, MATRIX_CaptionRange, MATRIX_CurrSetLength);

        if MATRIX_CurrSetLength > 0 then begin
            CostCenterMatrixRecord.SetPosition(MATRIX_PKFirstRecInCurrSet);
            CostCenterMatrixRecord.Get(CostCenterMatrixRecord.Code);
            repeat
                CostCenterMatrixRecords[CurrentMatrixRecordOrdinal].Copy(CostCenterMatrixRecord);
                CurrentMatrixRecordOrdinal := CurrentMatrixRecordOrdinal + 1;
            until (CurrentMatrixRecordOrdinal > MATRIX_CurrSetLength) or (CostCenterMatrixRecord.Next() <> 1);
        end;
    end;

    local procedure FindPeriod(FindTxt: Code[3])
    var
        Calendar: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        if Rec.GetFilter("Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", Rec.GetFilter("Date Filter"));
            if not PeriodPageMgt.FindDate('+', Calendar, PeriodType) then
                PeriodPageMgt.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageMgt.FindDate(FindTxt, Calendar, PeriodType);
        if AmountType = AmountType::"Net Change" then begin
            Rec.SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
            if Rec.GetRangeMin("Date Filter") = Rec.GetRangeMax("Date Filter") then
                Rec.SetRange("Date Filter", Rec.GetRangeMin("Date Filter"));
        end else
            Rec.SetRange("Date Filter", 0D, Calendar."Period End");
    end;

    local procedure UpdateMatrixSubform()
    begin
        CurrPage.MatrixForm.PAGE.LoadMatrix(
          MATRIX_CaptionSet, CostCenterMatrixRecords, MATRIX_CurrSetLength, Rec.GetFilter("Date Filter"), BudgetFilter, RoundingFactor);
    end;
}

