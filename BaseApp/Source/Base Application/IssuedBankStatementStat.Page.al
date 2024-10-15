#if not CLEAN19
page 11715 "Issued Bank Statement Stat."
{
    Caption = 'Issued Bank Statement Stat. (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Issued Bank Statement Header";
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
                    ToolTip = 'Specifies the beginig balance of bank statement.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount for bank statement lines. The program calculates this amount from the sum of line amount fields on bank statement lines.';
                }
                field(EndBalance; EndBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Balance';
                    Editable = false;
                    ToolTip = 'Specifies the ending balance of bank statement.';
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
        EndBalance := BegBalance + Amount;
    end;

    var
        EndBalance: Decimal;
        BegBalance: Decimal;
}
#endif
