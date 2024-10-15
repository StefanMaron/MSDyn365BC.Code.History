page 5503 "Income Statement Entity"
{
    Caption = 'incomeStatement', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'incomeStatement';
    EntitySetName = 'incomeStatement';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = API;
    SourceTable = "Acc. Schedule Line Entity";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'API version beta will be deprecated.';
    ObsoleteTag = '18.0';

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
                field(netChange; "Net Change")
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    BlankZero = true;
                    Caption = 'NetChange', Locked = true;
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
        ReportAPIType: Option "Balance Sheet","Income Statement","Trial Balance","CashFlow Statement","Aged Accounts Payable","Aged Accounts Receivable","Retained Earnings";
    begin
        RecVariant := Rec;
        GraphMgtReports.SetUpAccountScheduleBaseAPIDataWrapper(RecVariant, ReportAPIType::"Income Statement");
    end;
}

