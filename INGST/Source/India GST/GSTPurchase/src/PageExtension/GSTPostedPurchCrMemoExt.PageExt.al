pageextension 18080 "GST Posted Purch. Cr. Memo Ext" extends "Posted Purchase Credit Memo"
{
    layout
    {
        addafter("Shipping and Payment")
        {
            group("Tax Information")
            {
                field("Bill of Entry Date"; "Bill of Entry Date")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry date defined in bill of entry document.';
                }
                field("Bill of Entry No."; "Bill of Entry No.")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bill of entry number. It is a document number which is submitted to custom department .';
                }
                field("Without Bill Of Entry"; "Without Bill Of Entry")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the invoice is with or without bill of entry.';
                }
                field("Bill of Entry Value"; "Bill of Entry Value")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the values as mentioned in bill of entry document.';
                }
                field("Invoice Type"; "Invoice Type")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the invoice created. For example, Self Invoice/Debit Note/Supplementary/Non-GST.';
                }
                field("GST Invoice"; "GST Invoice")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if GST is applicable.';
                }
                field("POS Out Of India"; "POS Out Of India")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the place of supply of invoice is out of India.';
                }
                field("POS as Vendor State"; "POS as Vendor State")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor state code.';
                }
                field("Associated Enterprises"; "Associated Enterprises")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that an import transaction of services from companys Associates Vendor';
                }
                field("Location State Code"; "Location State Code")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the state code mentioned in location used in the transaction.';
                }
                field("Location GST Reg. No."; "Location GST Reg. No.")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST Registration number of the Location specified on the journal line.';
                }
                field("Vendor GST Reg. No."; "Vendor GST Reg. No.")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST registration number of the Vendor specified on the journal line.';
                }
                field("Order Address GST Reg. No."; "Order Address GST Reg. No.")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST registration number of the mentioned order address in the transaction.';
                }
                field("GST Order Address State"; "GST Order Address State")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the state code of the mentioned order address in the transaction.';
                }
                field("Nature of Supply"; "Nature of Supply")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the nature of GST transaction. For example, B2B/B2C.';
                }
                field("Vehicle No."; "Vehicle No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the vehicle number on the sales document.';
                }
                field("Vehicle Type"; "Vehicle Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the vehicle type on the sales document. For example, Regular/ODC.';
                }
                field("Distance (Km)"; "Distance (Km)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the distance on the purchase document.';
                }
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the shipping agent code. For example, DHL, FedEx etc.';
                }
                field("Rate Change Applicable"; "Rate Change Applicable")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if rate change is applicable on the sales document.';
                }
                field("Supply Finish Date"; "Supply Finish Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the supply finish date. For example, Before rate change/After rate change.';
                }
                field("Reference Invoice No."; "Reference Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the reference invoice number.';
                }
                field("GST Reason Type"; "GST Reason Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the reason of return or credit memo of a posted document where GST is applicable. For example, Deficiency in Service/Correction in Invoice etc.';
                }
                field("E-Way Bill No."; "E-Way Bill No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the E-way bill number on the purchase document.';
                }
            }
        }
    }
}
