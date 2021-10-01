page 5499 "Aged AR Entity"
{
    Caption = 'agedAccountsReceivable', Locked = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Aged Report Entity";
#if not CLEAN18
    PageType = API;
    EntityName = 'agedAccountsReceivable';
    EntitySetName = 'agedAccountsReceivable';
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
                field(customerId; AccountId)
                {
                    ApplicationArea = All;
                    Caption = 'CustomerId', Locked = true;
                }
                field(customerNumber; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'CustomerNumber', Locked = true;
                }
                field(name; Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name', Locked = true;
                }
                field(currencyCode; "Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'CurrencyCode', Locked = true;
                }
                field(balanceDue; Balance)
                {
                    ApplicationArea = All;
                    Caption = 'Balance', Locked = true;
                }
                field(currentAmount; Before)
                {
                    ApplicationArea = All;
                    Caption = 'Before', Locked = true;
                }
                field(period1Amount; "Period 1")
                {
                    ApplicationArea = All;
                    Caption = 'Period1', Locked = true;
                }
                field(period2Amount; "Period 2")
                {
                    ApplicationArea = All;
                    Caption = 'Period2', Locked = true;
                }
                field(period3Amount; "Period 3")
                {
                    ApplicationArea = All;
                    Caption = 'Period3', Locked = true;
                }
                field(agedAsOfDate; "Period Start Date")
                {
                    ApplicationArea = All;
                    Caption = 'PeriodStartDate', Locked = true;
                }
                field(periodLengthFilter; "Period Length")
                {
                    ApplicationArea = All;
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