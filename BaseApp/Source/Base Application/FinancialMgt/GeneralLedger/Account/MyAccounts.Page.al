namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Finance.GeneralLedger.Ledger;

page 9153 "My Accounts"
{
    Caption = 'My Accounts';
    PageType = ListPart;
    SourceTable = "My Account";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L account number.';

                    trigger OnValidate()
                    begin
                        SyncFieldsWithGLAccount();
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the name of the cash account.';
                }
                field(Balance; Rec."Account Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    ToolTip = 'Specifies the balance on the bank account.';

                    trigger OnDrillDown()
                    var
                        [SecurityFiltering(SecurityFilter::Filtered)]
                        GLEntry: Record "G/L Entry";
                        GLAccountsFilterText: Text;
                    begin
                        SyncFieldsWithGLAccount();
                        GLAccountsFilterText := GLAccount."No.";
                        if GLAccount.IsTotaling() then
                            GLAccountsFilterText := GLAccount.Totaling;
                        GLEntry.SetFilter("G/L Account No.", GLAccountsFilterText);
                        PAGE.Run(0, GLEntry);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open';
                Image = ViewDetails;
                RunObject = Page "G/L Account Card";
                RunPageLink = "No." = field("Account No.");
                RunPageMode = View;
                RunPageView = sorting("No.");
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SyncFieldsWithGLAccount();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(GLAccount);
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("User ID", UserId);
    end;

    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GLAccount: Record "G/L Account";

    local procedure SyncFieldsWithGLAccount()
    var
        MyAccount: Record "My Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSyncFieldsWithGLAccount(Rec, IsHandled);
        if IsHandled then
            exit;

        Clear(GLAccount);
        if GLAccount.Get(Rec."Account No.") then begin
            GLAccount.CalcFields(Balance);
            if (Rec."Account Balance" <> GLAccount.Balance) or (Rec.Name <> GLAccount.Name) then begin
                Rec."Account Balance" := GLAccount.Balance;
                Rec.Name := GLAccount.Name;
                if MyAccount.Get(Rec."User ID", Rec."Account No.") then
                    Rec.Modify();
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSyncFieldsWithGLAccount(var MyAccount: Record "My Account"; var IsHandled: Boolean)
    begin
    end;
}

