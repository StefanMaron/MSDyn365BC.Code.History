page 10134 "Posted Bank Rec. Lines"
{
    Caption = 'Posted Bank Rec. Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Posted Bank Rec. Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Bank Account No."; "Bank Account No.")
                {
                    ToolTip = 'Specifies the Bank Account No. field posted from the Bank Rec. Line table.';
                    Visible = false;
                }
                field("Statement No."; "Statement No.")
                {
                    ToolTip = 'Specifies the Statement No. field posted from the Bank Rec. Line table.';
                    Visible = false;
                }
                field("Line No."; "Line No.")
                {
                    ToolTip = 'Specifies the posted bank reconciliation line number.';
                    Visible = false;
                }
                field("Record Type"; "Record Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Record Type field posted from the Bank Rec. Line table.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Posting Date field from the Bank Rec. Line table.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document from the Bank Reconciliation Line table.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank reconciliation that this line belongs to.';
                }
                field("Account Type"; "Account Type")
                {
                    ToolTip = 'Specifies the Account Type field from the Bank Reconciliation Line table.';
                    Visible = false;
                }
                field("Account No."; "Account No.")
                {
                    ToolTip = 'Specifies the Account No. field from the Bank Reconciliation Line table.';
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
                field("Cleared Amount"; "Cleared Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that was cleared by the bank, as indicated by the bank statement.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the Balance Account Type that will be posted to the general ledger.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger customer, vendor, or bank account number the line will be posted to.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ToolTip = 'Specifies the currency code for line amounts posted to the general ledger. This field is for adjustment type lines only.';
                    Visible = false;
                }
                field("Currency Factor"; "Currency Factor")
                {
                    ToolTip = 'Specifies a currency factor for the reconciliation sub-line entry. The value is calculated based on currency code, exchange rate, and the bank record header''s statement date.';
                    Visible = false;
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the external document number for the posted journal line.';
                }
                field("Bank Ledger Entry No."; "Bank Ledger Entry No.")
                {
                    ToolTip = 'Specifies the entry number from the Bank Account Ledger Entry table where the line originated.';
                    Visible = false;
                }
                field("Check Ledger Entry No."; "Check Ledger Entry No.")
                {
                    ToolTip = 'Specifies the entry number from the Check Ledger Entry table where the line originated.';
                    Visible = false;
                }
                field("Adj. Source Record ID"; "Adj. Source Record ID")
                {
                    ToolTip = 'Specifies the adjustment source record type for the Posted Bank Rec. Line.';
                    Visible = false;
                }
                field("Adj. Source Document No."; "Adj. Source Document No.")
                {
                    ToolTip = 'Specifies the adjustment source document number for the Posted Bank Reconciliation Line.';
                    Visible = false;
                }
                field("Adj. No. Series"; "Adj. No. Series")
                {
                    ToolTip = 'Specifies the Posted Bank Rec. Line adjustment number series, which was used to create the document number on the adjustment line.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

