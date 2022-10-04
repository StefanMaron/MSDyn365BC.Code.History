page 5501 "Balance Sheet Entity"
{
    Caption = 'balanceSheet', Locked = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Balance Sheet Buffer";
    PageType = List;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(lineNumber; "Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Line No..';
                    Caption = 'LineNumber', Locked = true;
                }
                field(display; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Description.';
                    Caption = 'Description', Locked = true;
                }
                field(balance; Balance)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Balance.';
                    AutoFormatType = 0;
                    BlankZero = true;
                    Caption = 'Balance', Locked = true;
                }
                field(lineType; "Line Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Line Type.';
                    Caption = 'LineType', Locked = true;
                }
                field(indentation; Indentation)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Indentation';
                    Caption = 'Indentation', Locked = true;
                }
                field(dateFilter; "Date Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Date Filter.';
                    Caption = 'DateFilter', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        GraphMgtReports: Codeunit "Graph Mgt - Reports";
        RecVariant: Variant;
    begin
        RecVariant := Rec;
        GraphMgtReports.SetUpBalanceSheetAPIData(RecVariant);
    end;
}