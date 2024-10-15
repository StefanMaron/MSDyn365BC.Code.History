page 18002 "GST Ledger Entry"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "GST Ledger Entry";
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(general)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Source Type as customer for sales transaction,. For purchase transaction, Source Type is vendor. For Bank Charges Transaction, Source Type is Bank account.';
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the GST posting setup.';
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the GST posting setup.';



                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the GST ledger entry.';




                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type that the GST entry belongs to.';

                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the transaction that created the entry.';

                }
                field("Transaction No."; "Transaction No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction number  that the GST entry belongs to.';

                }
                field("Transaction Type"; "Transaction Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction type that created the entry.';
                }
                field("GST Base Amount"; "GST Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the GST amount is calculated from.';
                }
                field("GST Amount"; "GST Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the GST entry in LCY.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor number, if Source Type is vendor. If Source Type is customer, the Customer number is displayed. If Source Type is Bank Account, the Bank Account number is displayed.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who posted the transaction.';
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code. Source code can be PURCHASES, SALES, GENJNL, BANKPYMT etc.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code defined in Reason Code table.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document No. that refers to the Customer or Vendors numbering system.';
                }
                field("GST Component Code"; "GST Component Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how  GST will be calculated for purchases or sales of items or resource with this component code. ';
                }
                field("GST on Advance Payment"; "GST on Advance Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if GST is required to be calculated on Advance Payment.';
                }
                field("Reverse Charge"; "Reverse Charge")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Reverse charge is applicable for import of goods and purchases from an unregistered vendor. This field is blank for sales transactions.';

                }
                field("Reversed Entry No."; "Reversed Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reversed entry number, if the transaction is reversed. ';
                }
                field("Reversed by Entry No."; "Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Reversed by entry number, if the transaction is reversed. ';
                }
                field("POS Out Of India"; "POS Out Of India")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if Place of Supply is out of India.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code on GST ledger entry.';
                }
                field("Currency Factor"; "Currency Factor")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies currency factor for this transactions.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the entry is an initial entry or an application entry or an adjustment entry.';
                }

            }

        }

    }
}
