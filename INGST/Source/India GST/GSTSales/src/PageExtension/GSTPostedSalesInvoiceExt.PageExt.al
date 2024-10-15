pageextension 18144 "GST Posted Sales Invoice Ext" extends "Posted Sales Invoice"
{
    layout
    {
        addfirst("Tax Info")
        {
            field("Invoice Type"; "Invoice Type")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the Invoice type as per GST law.';
            }
            field("Bill Of Export No."; "Bill Of Export No.")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the bill of export number. It is a document number which is submitted to custom department .';
            }
            field("Bill Of Export Date"; "Bill Of Export Date")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the entry date defined in bill of export document.';
            }
            field("E-Commerce Customer"; "E-Commerce Customer")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the customer number for which merchant id has to be recorded.';
            }
            field("E-Commerce Merchant Id"; "E-Commerce Merchant Id")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the merchant ID provided to customers by their payment processor.';
            }
            field("Reference Invoice No."; "Reference Invoice No.")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the Reference Invoice number.';
            }
            field("GST Without Payment of Duty"; "GST Without Payment of Duty")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies if the invoice is a GST invoice with or without payment of duty.';
            }
            field("GST Invoice"; "GST Invoice")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies whether this transaction is related to GST.';
            }
            field("POS Out Of India"; "POS Out Of India")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies if the place of supply of invoice is out of India.';
            }
            field("GST Bill-to State Code"; "GST Bill-to State Code")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the bill-to state code of the customer on the sales document.';
            }
            field("GST Ship-to State Code"; "GST Ship-to State Code")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the ship-to state code of the customer on the sales document.';
            }
            field("Location State Code"; "Location State Code")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the sate code mentioned of the location used on the sales document.';
            }

            field("Nature of Supply"; "Nature of Supply")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the nature of GST transaction. For example, B2B/B2C.';
            }
            field("GST Customer Type"; "GST Customer Type")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the type of the customer. For example, Registered, Unregistered, Export etc..';
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
            field("Payment Date"; "Payment Date")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the payment date. For example, Before rate change/After rate change.';
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
                ToolTip = 'Specifies the vehicle type on the sales document. For example, Regular/ODC.  ';
            }
            field("Distance (Km)"; "Distance (Km)")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the distance on the sales document.';
            }
            field("E-Way Bill No."; "E-Way Bill No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the E-way bill number on the sale document.';
            }
        }
    }
}
