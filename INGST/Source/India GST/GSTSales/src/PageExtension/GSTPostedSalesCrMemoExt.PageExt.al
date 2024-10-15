pageextension 18143 "GST Posted Sales Cr. Memo Ext" extends "Posted Sales Credit Memo"
{
    layout
    {
        addfirst("Tax Info")
        {
            field("GST Bill-to State Code"; "GST Bill-to State Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the bill-to state code of the customer on the sales document.';
            }
            field("GST Ship-to State Code"; "GST Ship-to State Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the ship-to state code of the customer on the sales document.';
            }
            field("Location State Code"; "Location State Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sate code mentioned in location on the sales document.';
            }
            field("Location GST Reg. No."; "Location GST Reg. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST registration number of the Location specified on the Sales document.';
            }
            field("Customer GST Reg. No."; "Customer GST Reg. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST registration number of the customer specified on the Sales document.';
            }
            field("Ship-to GST Reg. No."; "Ship-to GST Reg. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the ship to GST registration number of the customer specified on the Sales document.';
            }
            field("Nature of Supply"; "Nature of Supply")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the nature of GST transaction. For example, B2B/B2C.';
            }
            field("GST Customer Type"; "GST Customer Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type of the customer. For example, Registered, Unregistered, Export etc..';
            }
            field("GST Without Payment of Duty"; "GST Without Payment of Duty")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the invoice is a GST invoice with or without payment of duty.';
            }
            field("Invoice Type"; "Invoice Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Invoice type as per GST law.';
            }
            field("Bill Of Export No."; "Bill Of Export No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the bill of export number. It is a document number which is submitted to custom department .';
            }
            field("Bill Of Export Date"; "Bill Of Export Date")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the entry date defined in bill of export document.';
            }
            field("e-Commerce Customer"; "e-Commerce Customer")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the customer number for which merchant id has to be recorded.';
            }
            field("e-Commerce Merchant Id"; "e-Commerce Merchant Id")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the merchant ID provided to customers by their payment processor.';
            }
            field("Distance (Km)"; "Distance (Km)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the distance.';
            }
            field("POS Out Of India"; "POS Out Of India")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the place of supply of invoice is out of India.';
            }
            field("Reference Invoice No."; "Reference Invoice No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Reference Invoice number.';
            }
            field("Sale Return Type"; "Sale Return Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sale return type. For example, Sales cancellation.';
            }
        }
    }
}
