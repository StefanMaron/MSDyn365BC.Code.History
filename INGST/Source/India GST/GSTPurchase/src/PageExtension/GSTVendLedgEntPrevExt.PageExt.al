pageextension 18095 "GST Vend Ledg Ent Prev Ext" extends "Vend. Ledg. Entries Preview"
{
    layout
    {
        addlast(Control1)
        {
            field("Location Code"; "Location Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the location code for which the entry was posted.';
            }
            field("GST on Advance Payment"; "GST on Advance Payment")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if GST is required to be calculated on Advance Payment.';
            }
            field("GST Group Code"; "GST Group Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the GST group is assigned for goods or service.';
            }
            field("HSN/SAC Code"; "HSN/SAC Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the HSN for Items & Fixed Assets. SAC for Services & Resources. For charges, it can be either SAC or HSN.';
            }
            field("GST Reverse Charge"; "GST Reverse Charge")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies whether the reverse charge is applicable for this GST group or not.';
            }
            field("GST Vendor Type"; "GST Vendor Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type of the vendor. For example,  Registered, Unregistered, Composite, Import etc..';
            }
            field("GST Input Service Distribution"; "GST Input Service Distribution")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the location is designated for input service distribution.';
            }
            field("Buyer State Code"; "Buyer State Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the  Buyer state code';
            }
            field("Buyer GST Reg. No."; "Buyer GST Reg. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST registration number of the Buyer specified on the journal line.';

            }
            field("GST Jurisdiction Type"; "GST Jurisdiction Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type related to GST jurisdiction. For example, interstate/intrastate.';
            }
            field("Location State Code"; "Location State Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the location state of the posted entry.';
            }
            field("Location GST Reg. No."; "Location GST Reg. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST Registration number of the location used in posted entry.';

            }

        }
    }
}