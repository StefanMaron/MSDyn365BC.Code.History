page 12425 "Posted Payment Order List"
{
    Caption = 'Posted Payment Order List';
    Editable = false;
    PageType = Worksheet;
    SourceTable = "Check Ledger Entry";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account that the posted payment was processed for.';
                }
                field("Bank Account Ledger Entry No."; "Bank Account Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number of the bank account ledger entry from which the check ledger entry was created.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';
                }
                field("Check Date"; "Check Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the check date if a check is printed.';
                }
                field("Check No."; "Check No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the check number if a check is printed.';
                }
                field("Check Type"; "Check Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type check, such as Manual.';
                }
                field("Bank Payment Type"; "Bank Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the payment type to be used for the entry on the journal line.';
                }
                field("Entry Status"; "Entry Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the printing (and posting) status of the check ledger entry.';
                }
                field("Original Entry Status"; "Original Entry Status")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';
                }
                field(Open; Open)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Statement Status"; "Statement Status")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Statement No."; "Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Statement Line No."; "Statement Line No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Payment Method"; "Payment Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
                field("Payment Before Date"; "Payment Before Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment before date associated with the check ledger entry.';
                }
                field("Payment Subsequence"; "Payment Subsequence")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment subsequence associated with the check ledger entry.';
                }
                field("Payment Code"; "Payment Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment code associated with the check ledger entry.';
                }
                field("Payment Assignment"; "Payment Assignment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment assignment associated with the check ledger entry.';
                }
                field("Payment Type"; "Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment type associated with the check ledger entry.';
                }
                field("Cashier Report Printed"; "Cashier Report Printed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the casher report will be printed for the check ledger entry.';
                }
                field("Cashier Report No."; "Cashier Report No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cashier report number associated with the check ledger entry.';
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                }
                field(Positive; Positive)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the check ledger entry is positive.';
                }
            }
            group(Recipient)
            {
                Caption = 'Recipient';
                field("Beneficiary Bank Code"; "Beneficiary Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the beneficiary bank code associated with the check ledger entry.';
                }
                field("Beneficiary VAT Reg No."; "Beneficiary VAT Reg No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the beneficiary VAT registration number associated with the check ledger entry.';
                }
                field("Beneficiary Name"; "Beneficiary Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the beneficiary name associated with the check ledger entry.';
                }
                field("Beneficiary BIC"; "Beneficiary BIC")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the beneficiary bank identifier code associated with the check ledger entry.';
                }
                field("Beneficiary Corr. Acc. No."; "Beneficiary Corr. Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the beneficiary corresponding account number associated with the check ledger entry.';
                }
                field("Beneficiary Bank Acc. No."; "Beneficiary Bank Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the beneficiary bank account number associated with the check ledger entry.';
                }
            }
            group(Payer)
            {
                Caption = 'Payer';
                field("Payer VAT Reg. No."; "Payer VAT Reg. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payer VAT registration number associated with the check ledger entry.';
                }
                field("Payer Name"; "Payer Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payer name associated with the check ledger entry.';
                }
                field("Payer BIC"; "Payer BIC")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank identifier code associated with the check ledger entry.';
                }
                field("Payer Bank"; "Payer Bank")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank of the payer associated with the check ledger entry.';
                }
                field("Payer Corr. Account No."; "Payer Corr. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payer corresponding account number associated with the check ledger entry.';
                }
                field("Payer Bank Account No."; "Payer Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payer bank account number associated with the check ledger entry.';
                }
            }
            group("Payment's Details")
            {
                Caption = 'Payment''s Details';
                field("Payment Purpose"; "Payment Purpose")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the payment associated with the check ledger entry.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

