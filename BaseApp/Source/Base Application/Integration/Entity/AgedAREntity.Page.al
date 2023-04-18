page 5499 "Aged AR Entity"
{
    Caption = 'agedAccountsReceivable', Locked = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Aged Report Entity";
    PageType = List;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(customerId; AccountId)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Account Id.';
                    Caption = 'CustomerId', Locked = true;
                }
                field(customerNumber; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Customer No..';
                    Caption = 'CustomerNumber', Locked = true;
                }
                field(name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Customer Name.';
                    Caption = 'Name', Locked = true;
                }
                field(currencyCode; "Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Currency Code.';
                    Caption = 'CurrencyCode', Locked = true;
                }
                field(balanceDue; Balance)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Balance Due.';
                    Caption = 'Balance', Locked = true;
                }
                field(currentAmount; Before)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the period Before.';
                    Caption = 'Before', Locked = true;
                }
                field(period1Amount; "Period 1")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies Period 1.';
                    Caption = 'Period1', Locked = true;
                }
                field(period2Amount; "Period 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies Period 2.';
                    Caption = 'Period2', Locked = true;
                }
                field(period3Amount; "Period 3")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies Period 3.';
                    Caption = 'Period3', Locked = true;
                }
                field(agedAsOfDate; "Period Start Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Period Start Date.';
                    Caption = 'PeriodStartDate', Locked = true;
                }
                field(periodLengthFilter; "Period Length")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Period Length.';
                    Caption = 'PeriodLength', Locked = true;
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