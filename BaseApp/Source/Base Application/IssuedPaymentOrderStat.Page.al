#if not CLEAN19
page 11725 "Issued Payment Order Stat."
{
    Caption = 'Issued Payment Order Stat. (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Issued Payment Order Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(BegBalance; BegBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Beginig Balance';
                    Editable = false;
                    ToolTip = 'Specifies the beginig balance of payment order.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount for payment order lines. The program calculates this amount from the sum of line amount fields on payment order lines.';
                }
                field(EndBalance; EndBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Balance';
                    Editable = false;
                    ToolTip = 'Specifies the ending balance of payment order.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get("Bank Account No.");
        BankAccount.SetFilter("Date Filter", '..%1', CalcDate('<-1D>', "Document Date"));
        BankAccount.CalcFields("Balance at Date");
        CalcFields(Amount);
        BegBalance := BankAccount."Balance at Date";
        EndBalance := BegBalance - Amount;
    end;

    var
        EndBalance: Decimal;
        BegBalance: Decimal;
}
#endif
