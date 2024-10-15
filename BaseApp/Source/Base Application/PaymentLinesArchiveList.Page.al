page 10880 "Payment Lines Archive List"
{
    Caption = 'Payment Lines Archive List';
    Editable = false;
    PageType = List;
    SourceTable = "Payment Line Archive";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the archived payment.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the archived payment line''s entry number.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the archived payment line.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the archived payment line.';
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount (including VAT) of the archived payment line.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount in LCY of the archived payment line.';
                    Visible = false;
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account type of the archived payment line.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number of the archived payment line.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date of the archived payment line.';
                }
                field("Payment Class"; "Payment Class")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment class of the archived payment line.';
                }
                field("Status Name"; "Status Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the archived payment.';
                }
                field("Status No."; "Status No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the archived status line entry number.';
                    Visible = false;
                }
                field("Acceptation Code"; "Acceptation Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the acception code of the archived payment.';
                }
                field("Drawee Reference"; "Drawee Reference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file reference which has been used in the electronic payment (ETEBAC) file.';
                }
                field("Bank Account Name"; "Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank account, as entered in the Bank Account field.';
                    Visible = false;
                }
                field("Bank Branch No."; "Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the branch number of the bank account as entered in the Bank Account field.';
                    Visible = false;
                }
                field("Agency Code"; "Agency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the agency code of the bank account as entered in the Bank Account field.';
                    Visible = false;
                }
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the international bank identification code for the payment slip.';
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the international bank account number (IBAN) for the payment slip.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer or vendor bank account of the archived payment.';
                    Visible = false;
                }
                field("RIB Key"; "RIB Key")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the two digit RIB key associated with the Bank Branch No.';
                    Visible = false;
                }
                field("Payment in Progress"; "Payment in Progress")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the payment line was taken into account for the customer or vendor payments in progress.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Functions)
            {
                Caption = '&Payment';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the card for the entity on the selected line to view more details.';

                    trigger OnAction()
                    var
                        Statement: Record "Payment Header Archive";
                        StatementForm: Page "Payment Slip Archive";
                    begin
                        if Statement.Get("No.") then begin
                            Statement.SetRange("No.", "No.");
                            StatementForm.SetTableView(Statement);
                            StatementForm.Run;
                        end;
                    end;
                }
            }
        }
    }
}

