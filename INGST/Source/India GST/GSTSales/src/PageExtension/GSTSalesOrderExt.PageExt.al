pageextension 18150 "GST Sales Order Ext" extends "Sales Order"
{
    layout
    {
        addfirst("Tax Info")
        {

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
            field("E-Commerce Customer"; "E-Commerce Customer")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the customer number for which merchant id has to be recorded.';
            }
            field("E-Commerce Merchant Id"; "E-Commerce Merchant Id")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the customer number for which merchant id has to be recorded.';
            }
            field("Reference Invoice No."; "Reference Invoice No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Reference Invoice number.';
            }
            field("GST Without Payment of Duty"; "GST Without Payment of Duty")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the GST order is with or without payment of duty.';
            }
            field("GST Invoice"; "GST Invoice")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if GST is applicable.';
            }
            field("POS Out Of India"; "POS Out Of India")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the place of supply of invoice is out of India.';
            }
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
                ToolTip = 'Specifies the sate code mentioned of the location used in the transaction.';

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
            field("Rate Change Applicable"; "Rate Change Applicable")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if rate change is applicable on the sales document.';
            }
            field("Supply Finish Date"; "Supply Finish Date")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the supply finish date. For example, Before rate change/After rate change.';
            }
            field("Payment Date"; "Payment Date")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the payment date. For example, Before rate change/After rate change.';
            }
            field("Vehicle No."; "Vehicle No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the vehicle number on the sales document.';
            }
            field("Vehicle Type"; "Vehicle Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the vehicle type on the sales document. For example, Regular/ODC.  ';
            }
            field("Distance (Km)"; "Distance (Km)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the distance on the sales document.';
            }
            field(Trading; Trading)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if trading is applicable.';
            }
        }
    }
    actions
    {
        addafter(IncomingDocument)
        {
            action("Update Reference Invoice No.")
            {
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = Basic, Suite;
                Image = ApplyEntries;
                ToolTip = 'Specifies the function through which reference number can be updated in the document.';

                trigger OnAction()
                var
                    i: Integer;
                begin
                    i := 0;
                    //blank OnAction created as we have a subscriber of this action in "Reference Invoice No. Mgt." codeunit;
                end;
            }
        }
    }
}