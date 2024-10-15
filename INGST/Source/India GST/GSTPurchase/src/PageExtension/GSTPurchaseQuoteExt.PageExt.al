pageextension 18086 "GST Purchase Quote Ext" extends "Purchase Quote"
{
    layout
    {
        addlast(FactBoxes)
        {
            part("Tax Information"; "Tax Information Factbox")
            {
                ApplicationArea = Basic, Suite;
                Provider = "PurchLines";
                SubPageLink = "Table ID Filter" = const(39),
                    "Document Type Filter" = field("Document Type"),
                    "Document No. Filter" = field("Document No."),
                    "Line No. Filter" = field("Line No.");
            }
        }
        addafter("Foreign Trade")
        {
            group("Tax Information ")
            {
                field("GST Vendor Type"; "GST Vendor Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor type for GST transaction';
                }
                field("Bill of Entry Date"; "Bill of Entry Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry date defined in bill of entry document.';
                }
                field("Bill of Entry No."; "Bill of Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bill of entry number. It is a document number which is submitted to custom department .';
                }
                field("Bill of Entry Value"; "Bill of Entry Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the values as mentioned in bill of entry document.';
                }
                field("Invoice Type"; "Invoice Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the quote created. For example, Self Invoice/Debit Note/Supplementary/Non-GST.';
                }
                field("POS Out Of India"; "POS Out Of India")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the place of supply of invoice is out of India.';
                }
                field("Associated Enterprises"; "Associated Enterprises")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if Vendor is an associated enterprises';
                }
                field("Location State Code"; "Location State Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the state code mentioned in location used in the transaction.';
                }
                field("Location GST Reg. No."; "Location GST Reg. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST Registration number of the Location specified on the journal line.';
                }
                field("Vendor GST Reg. No."; "Vendor GST Reg. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST registration number of the Vendor specified on the journal line.';
                }
                field("Order Address GST Reg. No."; "Order Address GST Reg. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST registration number of the mentioned order address in the transaction.';
                }
                field("GST Order Address State"; "GST Order Address State")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the state code of the mentioned order address in the transaction.';
                }

            }
        }
    }
}
