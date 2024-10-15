pageextension 18153 "GST Sales Quote Ext" extends "Sales Quote"
{
    layout
    {
        addfirst("Tax Info")
        {
            field("Invoice Type"; "Invoice Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Type of Invoice.';
            }
            field("POS Out Of India"; "POS Out Of India")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the place of supply of invoice is out of India.';
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
            field("E-Commerce Customer"; "E-Commerce Customer")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the customer number for which merchant id has to be recorded.';
            }
            field("E-Commerce Merchant Id"; "E-Commerce Merchant Id")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the merchant ID provided to customers by their payment processor.';
            }
            field("Reference Invoice No."; "Reference Invoice No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Reference Invoice number.';
            }
            field("GST Without Payment of Duty"; "GST Without Payment of Duty")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the quotation is with or without payment of duty.';
            }
            field("GST Invoice"; "GST Invoice")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if GST is applicable.';
            }
            field("GST Customer Type"; "GST Customer Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Customer Type';
            }
            field("Location State Code"; "Location State Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sate code mentioned in location used in the transaction.';
            }
            field("Location GST Reg. No."; "Location GST Reg. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST Registration number of the Location specified on the journal line.';
            }
            field("Customer GST Reg. No."; "Customer GST Reg. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST registration number of the Customer specified on the journal line.';
            }
        }
    }
}

