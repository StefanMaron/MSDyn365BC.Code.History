pageextension 18007 "GST Item Card Ext" extends "Item Card"
{
    layout
    {
        addlast("Posting Details")
        {
            field("GST Group Code"; Rec."GST Group Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies an unique identifier for the GST group code used to calculate and post GST.';
            }
            field("GST Credit"; Rec."GST Credit")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the GST credit has to be availed or not.';
            }
            field("HSN/SAC Code"; Rec."HSN/SAC Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies an unique identifier for the type of HSN or SAC that is used to calculate and post GST.';
            }
            field(Exempted; Rec.Exempted)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies whether the item is exempted from GST or not.';
            }
            field("Price Exclusive of Tax"; Rec."Price Exclusive of Tax")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies whether price inclusive of tax feature is applicable or not.';
            }
            field(Subcontracting; Rec.Subcontracting)
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies whether the item will be used for subcontracting or not.';
            }
            field("Sub. Comp. Location"; Rec."Sub. Comp. Location")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies the location from which item will be transferred to subcontracting location or vice versa.';
            }
        }
    }
}