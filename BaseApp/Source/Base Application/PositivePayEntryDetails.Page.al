page 1232 "Positive Pay Entry Details"
{
    Caption = 'Positive Pay Entry Details';
    Editable = false;
    PageType = List;
    SourceTable = "Positive Pay Entry Detail";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the bank account number. If you select Balance at Date, the balance as of the last day in the relevant time interval is displayed.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Check No."; "Check No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number on the check.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code for the amount on the line.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the type of the document on the line.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the payment amount.';
                }
                field(Payee; Payee)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the recipient of the payment.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field("Update Date"; "Update Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when the Positive Pay export was updated.';
                }
            }
        }
    }

    actions
    {
    }
}

