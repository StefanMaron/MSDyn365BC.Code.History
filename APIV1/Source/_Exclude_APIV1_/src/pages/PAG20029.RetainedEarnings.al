page 20029 "APIV1 - Retained Earnings"
{
    APIVersion = 'v1.0';
    Caption = 'retainedEarningsStatement', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'retainedEarningsStatement';
    EntitySetName = 'retainedEarningsStatement';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = API;
    SourceTable = "Acc. Schedule Line Entity";
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
                field(netChange; "Net Change")
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    BlankZero = true;
                    Caption = 'netChange', Locked = true;
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
        ReportAPIType: Option "Balance Sheet","Income Statement","Trial Balance","CashFlow Statement","Aged Accounts Payable","Aged Accounts Receivable","Retained Earnings";
    begin
        RecVariant := Rec;
        GraphMgtReports.SetUpAccountScheduleBaseAPIDataWrapper(RecVariant, ReportAPIType::"Retained Earnings");
    end;
}


