#pragma warning disable AS0074
#if not CLEAN21
page 10133 "Bank Rec. Lines"
{
    Caption = 'Bank Rec. Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Bank Rec. Line";
    ObsoleteReason = 'Deprecated in favor of W1 Bank Reconciliation';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#pragma warning restore AS0074

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ToolTip = 'Specifies the bank account number from the Bank Rec. Header Table that this line applies to.';
                    Visible = false;
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ToolTip = 'Specifies the statement number from the Bank Rec. Header Table that this line applies to.';
                    Visible = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ToolTip = 'Specifies the line''s number.';
                    Visible = false;
                }
                field("Record Type"; Rec."Record Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of line the record refers to. The valid line types are: Check, Deposit, Adjustment.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Statement Date for Check or Deposit type. For Adjustment type lines, the entry will be the actual date the posting.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that the entry on the journal line is.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number for the journal line.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ToolTip = 'Specifies the type of account that the journal line entry will be posted to.';
                    Visible = false;
                }
                field("Account No."; Rec."Account No.")
                {
                    ToolTip = 'Specifies the account number that the journal line entry will be posted to.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the transaction on the bank reconciliation line.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the item, such as a check, that was deposited.';
                }
                field(Cleared; Cleared)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the check on the line has been cleared, as indicated on the bank statement.';
                }
                field("Cleared Amount"; Rec."Cleared Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount cleared by the bank, as indicated by the bank statement.';
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the Balance Account Type that will be posted to the general ledger.';
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you can select the number of the G/L, customer, vendor or bank account to which a balancing entry for the line will posted.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ToolTip = 'Specifies the currency code for the amounts on the line, as it will be posted to the G/L.';
                    Visible = false;
                }
                field("Currency Factor"; Rec."Currency Factor")
                {
                    ToolTip = 'Specifies a currency factor for the reconciliation sub-line entry. The value is calculated based on currency code, exchange rate, and the bank record header''s statement date.';
                    Visible = false;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Bank Ledger Entry No."; Rec."Bank Ledger Entry No.")
                {
                    ToolTip = 'Specifies the entry number from the Bank Account Ledger Entry table record where the Bank Rec. Line record originated.';
                    Visible = false;
                }
                field("Check Ledger Entry No."; Rec."Check Ledger Entry No.")
                {
                    ToolTip = 'Specifies the entry number from the Bank Account Ledger Entry table record where the Bank Rec. Line record originated.';
                    Visible = false;
                }
                field("Adj. Source Record ID"; Rec."Adj. Source Record ID")
                {
                    ToolTip = 'Specifies what type of Bank Rec. Line record was the source for the created Adjustment line. The valid types are Check or Deposit.';
                    Visible = false;
                }
                field("Adj. Source Document No."; Rec."Adj. Source Document No.")
                {
                    ToolTip = 'Specifies the Document number from the Bank Rec. Line record that was the source for the created Adjustment line.';
                    Visible = false;
                }
                field("Adj. No. Series"; Rec."Adj. No. Series")
                {
                    ToolTip = 'Specifies the number series, from the G/L Setup table, used to create the document number on the created Adjustment line.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

#endif