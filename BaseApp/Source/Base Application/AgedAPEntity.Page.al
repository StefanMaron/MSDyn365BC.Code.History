page 5500 "Aged AP Entity"
{
    Caption = 'agedAccountsPayable', Locked = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Aged Report Entity";
#if not CLEAN18
    PageType = API;
    EntityName = 'agedAccountsPayable';
    EntitySetName = 'agedAccountsPayable';
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
                field(vendorId; Rec.AccountId)
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies the Account ID.';
                    Caption = 'Id', Locked = true;
                }
                field(vendorNumber; Rec."No.")
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies the Vendor No.';
                    Caption = 'VendorNumber', Locked = true;
                }
                field(name; Rec.Name)
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies the Vendor Name';
                    Caption = 'Name', Locked = true;
                }
                field(currencyCode; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies the Currency Code';
                    Caption = 'CurrencyCode', Locked = true;
                }
                field(balanceDue; Rec.Balance)
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies the Vendor Balance';
                    Caption = 'Balance', Locked = true;
                }
                field(currentAmount; Rec.Before)
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies Before';
                    Caption = 'Before', Locked = true;
                }
                field(period1Amount; Rec."Period 1")
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies Period 1';
                    Caption = 'Period1', Locked = true;
                }
                field(period2Amount; Rec."Period 2")
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies Period 2';
                    Caption = 'Period2', Locked = true;
                }
                field(period3Amount; Rec."Period 3")
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies Period 3';
                    Caption = 'Period3', Locked = true;
                }
                field(agedAsOfDate; Rec."Period Start Date")
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies the Period Start Date';
                    Caption = 'PeriodStartDate', Locked = true;
                }
                field(periodLengthFilter; Rec."Period Length")
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies the Period Length';
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