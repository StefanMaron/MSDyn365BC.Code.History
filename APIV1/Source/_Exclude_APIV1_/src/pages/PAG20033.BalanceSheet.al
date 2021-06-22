page 20033 "APIV1 - Balance Sheet"
{
    APIVersion = 'v1.0';
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
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(lineNumber; "Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'lineNumber', Locked = true;
                }
                field(display; Description)
                {
                    ApplicationArea = All;
                    Caption = 'description', Locked = true;
                }
                field(balance; Balance)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    BlankZero = true;
                    Caption = 'balance', Locked = true;
                }
                field(lineType; "Line Type")
                {
                    ApplicationArea = All;
                    Caption = 'lineType', Locked = true;
                }
                field(indentation; Indentation)
                {
                    ApplicationArea = All;
                    Caption = 'indentation', Locked = true;
                }
                field(dateFilter; "Date Filter")
                {
                    ApplicationArea = All;
                    Caption = 'dateFilter', Locked = true;
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


