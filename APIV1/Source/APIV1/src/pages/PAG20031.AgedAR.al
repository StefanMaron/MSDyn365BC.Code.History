page 20031 "APIV1 - Aged AR"
{
    APIVersion = 'v1.0';
    Caption = 'agedAccountsReceivable', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'agedAccountsReceivable';
    EntitySetName = 'agedAccountsReceivable';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = API;
    SourceTable = 5499;
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(customerId; AccountId)
                {
                    ApplicationArea = All;
                    Caption = 'customerId', Locked = true;
                }
                field(customerNumber; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'customerNumber', Locked = true;
                }
                field(name; Name)
                {
                    ApplicationArea = All;
                    Caption = 'name', Locked = true;
                }
                field(currencyCode; "Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'currencyCode', Locked = true;
                }
                field(balanceDue; Balance)
                {
                    ApplicationArea = All;
                    Caption = 'balance', Locked = true;
                }
                field(currentAmount; Before)
                {
                    ApplicationArea = All;
                    Caption = 'before', Locked = true;
                }
                field(period1Amount; "Period 1")
                {
                    ApplicationArea = All;
                    Caption = 'period1', Locked = true;
                }
                field(period2Amount; "Period 2")
                {
                    ApplicationArea = All;
                    Caption = 'period2', Locked = true;
                }
                field(period3Amount; "Period 3")
                {
                    ApplicationArea = All;
                    Caption = 'period3', Locked = true;
                }
                field(agedAsOfDate; "Period Start Date")
                {
                    ApplicationArea = All;
                    Caption = 'periodStartDate', Locked = true;
                }
                field(periodLengthFilter; "Period Length")
                {
                    ApplicationArea = All;
                    Caption = 'periodLength', Locked = true;
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
        GraphMgtReports.SetUpAgedReportAPIData(RecVariant, ReportAPIType::"Aged Accounts Receivable");
    end;
}


