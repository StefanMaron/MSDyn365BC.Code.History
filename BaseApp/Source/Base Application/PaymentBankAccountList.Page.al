#if not CLEAN17
page 1282 "Payment Bank Account List"
{
    Caption = 'Payment Bank Account List';
    CardPageID = "Payment Bank Account Card";
    Editable = false;
    PageType = List;
    SourceTable = "Bank Account";
    SourceTableView = WHERE("Account Type" = CONST("Bank Account"));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank where you have the bank account.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';
                }
                field(Balance; Balance)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account''s current balance denominated in the applicable foreign currency.';
                }
                field(Linked; Linked)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Linked';
                    ToolTip = 'Specifies that the bank account is linked to its related online bank account.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Linked := IsLinkedToBankStatementServiceProvider;
    end;

    var
        Linked: Boolean;
}
#endif