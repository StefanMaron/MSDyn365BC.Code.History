page 5502 "Trial Balance Entity"
{
    Caption = 'trialBalance', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'trialBalance';
    EntitySetName = 'trialBalance';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = API;
    SourceTable = "Trial Balance Entity Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Number', Locked = true;
                }
                field(accountId; "Account Id")
                {
                    ApplicationArea = All;
                    Caption = 'AccountId', Locked = true;
                }
                field(accountType; "Account Type")
                {
                    ApplicationArea = All;
                    Caption = 'AccountType', Locked = true;
                }
                field(display; Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name', Locked = true;
                }
                field(totalDebit; "Total Debit")
                {
                    ApplicationArea = All;
                    Caption = 'TotalDebit', Locked = true;
                }
                field(totalCredit; "Total Credit")
                {
                    ApplicationArea = All;
                    Caption = 'TotalCredit', Locked = true;
                }
                field(balanceAtDateDebit; "Balance at Date Debit")
                {
                    ApplicationArea = All;
                    Caption = 'BalanceAtDateDebit', Locked = true;
                }
                field(balanceAtDateCredit; "Balance at Date Credit")
                {
                    ApplicationArea = All;
                    Caption = 'BalanceAtDateCredit', Locked = true;
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
        GraphMgtReports.SetUpTrialBalanceAPIData(RecVariant);
    end;
}

