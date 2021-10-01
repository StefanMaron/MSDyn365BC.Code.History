page 5503 "Income Statement Entity"
{
    Caption = 'incomeStatement', Locked = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Acc. Schedule Line Entity";
#if not CLEAN18
    EntityName = 'incomeStatement';
    EntitySetName = 'incomeStatement';
    PageType = API;
    DelayedInsert = true;
#else
    ObsoleteState = Pending;
    ObsoleteReason = 'API version beta will be deprecated. This page will be changed to List type.';
    ObsoleteTag = '18.0';
    PageType = List;
#endif
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
