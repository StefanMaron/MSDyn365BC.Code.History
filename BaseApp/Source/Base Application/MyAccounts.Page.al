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
                field(Balance; "Account Balance")
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
                RunPageLink = "No." = FIELD("Account No.");
                RunPageMode = View;
                RunPageView = SORTING("No.");
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
        SetRange("User ID", UserId);
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
        if GLAccount.Get("Account No.") then begin
            GLAccount.CalcFields(Balance);
            if ("Account Balance" <> GLAccount.Balance) or (Name <> GLAccount.Name) then begin
                "Account Balance" := GLAccount.Balance;
                Name := GLAccount.Name;
                if MyAccount.Get("User ID", "Account No.") then
                    Modify();
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSyncFieldsWithGLAccount(var MyAccount: Record "My Account"; var IsHandled: Boolean)
    begin
    end;
}

