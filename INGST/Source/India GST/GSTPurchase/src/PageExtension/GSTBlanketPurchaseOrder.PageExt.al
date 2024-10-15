pageextension 18097 "GST Blanket Purchase Order" extends "Blanket Purchase Order"
{
    layout
    {
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
                field("Nature of Supply"; "Nature of Supply")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the nature of GST transaction. For example, B2B/B2C.';
                }

            }

        }
    }
}