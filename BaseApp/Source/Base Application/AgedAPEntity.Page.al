page 5500 "Aged AP Entity"
{
    Caption = 'agedAccountsPayable', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'agedAccountsPayable';
    EntitySetName = 'agedAccountsPayable';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = API;
    SourceTable = "Aged Report Entity";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(vendorId; AccountId)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                }
                field(vendorNumber; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'VendorNumber', Locked = true;
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
        GraphMgtReports.SetUpAgedReportAPIData(RecVariant, ReportAPIType::"Aged Accounts Payable");
    end;
}

