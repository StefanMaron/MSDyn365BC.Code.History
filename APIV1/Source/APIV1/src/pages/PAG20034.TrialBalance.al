page 20034 "APIV1 - Trial Balance"
{
    APIVersion = 'v1.0';
    Caption = 'trialBalance', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'trialBalance';
    EntitySetName = 'trialBalance';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = API;
    SourceTable = 5488;
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'number', Locked = true;
                }
                field(accountId; "Account Id")
                {
                    ApplicationArea = All;
                    Caption = 'accountId', Locked = true;
                }
                field(accountType; "Account Type")
                {
                    ApplicationArea = All;
                    Caption = 'accountType', Locked = true;
                }
                field(display; Name)
                {
                    ApplicationArea = All;
                    Caption = 'name', Locked = true;
                }
                field(totalDebit; "Total Debit")
                {
                    ApplicationArea = All;
                    Caption = 'totalDebit', Locked = true;
                }
                field(totalCredit; "Total Credit")
                {
                    ApplicationArea = All;
                    Caption = 'totalCredit', Locked = true;
                }
                field(balanceAtDateDebit; "Balance at Date Debit")
                {
                    ApplicationArea = All;
                    Caption = 'balanceAtDateDebit', Locked = true;
                }
                field(balanceAtDateCredit; "Balance at Date Credit")
                {
                    ApplicationArea = All;
                    Caption = 'balanceAtDateCredit', Locked = true;
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
        GraphMgtReports.SetUpTrialBalanceAPIData(RecVariant);
    end;
}


