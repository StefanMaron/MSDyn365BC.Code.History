pageextension 18141 "GST Cust. Ledger Entries Ext" extends "Customer Ledger Entries"
{
    layout
    {
        addlast(Control1)
        {
            field("GST Group Code"; "GST Group Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies an unique identifier for the GST group code used to calculate and post GST.';
            }
            field("HSN/SAC Code"; "HSN/SAC Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies an unique identifier for the type of HSN or SAC that is used to calculate and post GST.';
            }

            field("GST on Advance Payment"; "GST on Advance Payment")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if GST is required to be calculated on Advance Payment.';
            }

            field("GST Without Payment of Duty"; "GST Without Payment of Duty")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the GST is paid without duty.';
            }

            field("GST Customer Type"; "GST Customer Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type of the customer. For example, Registered, Unregistered, Export etc..';
            }
            field("Seller State Code"; "Seller State Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Customer state code that the entry is posted to.';
            }

            field("Seller GST Reg. No."; "Seller GST Reg. No.")
            {
                ToolTip = 'Specifies the GST registration number of the Seller specified on the journal line.';
                ApplicationArea = Basic, Suite;
            }

            field("Location Code"; "Location Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the location code for which the journal lines will be posted.';
            }


            field("GST Jurisdiction Type"; "GST Jurisdiction Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type related to GST jurisdiction. For example interstate/intrastate.';
            }

            field("Location State Code"; "Location State Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the location state of the posted entry.';
            }

            field("Location GST Reg. No."; "Location GST Reg. No.")
            {
                ToolTip = 'Specifies the GST Registration number of the location used in posted entry.';
                ApplicationArea = Basic, Suite;
            }

        }
    }
}