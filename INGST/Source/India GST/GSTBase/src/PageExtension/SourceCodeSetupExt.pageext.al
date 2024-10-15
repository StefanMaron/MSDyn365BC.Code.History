pageextension 18014 "Source Code Setup Ext" extends "Source Code Setup"
{
    layout
    {
        // Add changes to page layout here
        addlast(General)
        {
            field("Service Transfer Shipment"; "Service Transfer Shipment")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for Service transfer shipment.';
            }
            field("Service Transfer Receipt"; "Service Transfer Receipt")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for Service transfer receipt.';
            }
            field("GST Credit Adjustment Journal"; "GST Credit Adjustment Journal")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for GST credit adjustment journal';
            }
            field("GST Settlement"; "GST Settlement")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for GST settlement.';
            }
            field("GST Distribution"; "GST Distribution")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for GST distribution.';
            }
            field("GST Liability Adjustment"; "GST Liability Adjustment")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for GST liability adjustment.';
            }
            field("GST Adjustment Journal"; "GST Adjustment Journal")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the code for the GST adjustment journal.';
            }
        }
    }


}