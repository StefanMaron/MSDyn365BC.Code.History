page 18930 "Journal Voucher Posting Setup"
{
    Caption = 'Voucher Posting Setup';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Journal Voucher Posting Setup";
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field("Type"; "Type")
                {
                    Caption = 'Type';
                    ApplicationArea = Basic, Suite;
                }
                field("Posting No. Series"; "Posting No. Series")
                {
                    Caption = 'Posting No. Series';
                    ApplicationArea = Basic, Suite;
                }
                field("Transaction Direction"; "Transaction Direction")
                {
                    Caption = 'Transaction Direction';
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        SetActionEditable();
                        CurrPage.Update(true);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Debit Account")
            {
                PromotedOnly = true;
                ApplicationArea = Basic, Suite;
                Caption = 'Debit Account';
                Image = ChartOfAccounts;
                Enabled = DebitActionEditable;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = page "Voucher Posting Debit Accounts";
                RunPageLink = "Location code" = field("Location Code"), Type = field(Type);
            }
            action("Credit Account")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Credit Account';
                Image = ChartOfAccounts;
                Enabled = CreditActionEditable;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = page "Voucher Posting Credit Account";
                RunPageLink = "Location code" = field("Location Code"), Type = field(Type);
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetActionEditable();
    end;

    var
        DebitActionEditable: Boolean;
        CreditActionEditable: Boolean;

    local procedure SetActionEditable()
    begin
        DebitActionEditable := false;
        CreditActionEditable := false;
        case "Transaction Direction" of
            "Transaction Direction"::Both:
                begin
                    DebitActionEditable := true;
                    CreditActionEditable := true;
                end;
            "Transaction Direction"::Credit:
                CreditActionEditable := true;
            "Transaction Direction"::Debit:
                DebitActionEditable := true;
        end;
    end;
}