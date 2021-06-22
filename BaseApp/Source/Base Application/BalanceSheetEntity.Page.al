page 5501 "Balance Sheet Entity"
{
    Caption = 'balanceSheet', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'balanceSheet';
    EntitySetName = 'balanceSheet';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = API;
    SourceTable = "Balance Sheet Buffer";
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
                    Caption = 'LineNumber', Locked = true;
                }
                field(display; Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;
                }
                field(balance; Balance)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    BlankZero = true;
                    Caption = 'Balance', Locked = true;
                }
                field(lineType; "Line Type")
                {
                    ApplicationArea = All;
                    Caption = 'LineType', Locked = true;
                }
                field(indentation; Indentation)
                {
                    ApplicationArea = All;
                    Caption = 'Indentation', Locked = true;
                }
                field(dateFilter; "Date Filter")
                {
                    ApplicationArea = All;
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

    var
        Balance: Decimal;
}

