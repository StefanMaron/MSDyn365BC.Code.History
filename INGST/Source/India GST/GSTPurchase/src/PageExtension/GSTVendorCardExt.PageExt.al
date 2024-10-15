pageextension 18092 "GST Vendor Card Ext" extends "Vendor Card"
{
    layout
    {
        addlast(General)
        {
            field(Transporter; Transporter)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the vendor as Transporter';
            }
        }
        addlast("Tax Information")
        {
            group("GST")
            {
                field("GST Registration No."; "GST Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendors GST registration number issued by authorized body.';
                }
                field("GST vendor Type"; "GST vendor Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of GST registration or the vendor. For example, Registered/Un-registered/Import/Composite/Exempted/SEZ.';
                }
                field("Associated Enterprises"; "Associated Enterprises")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that an import transaction of services from companys Associates Vendor';
                }
                field("Aggregate Turnover"; "Aggregate Turnover")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the vendors aggregate turnover is more than 20 lacs or less than 20 lacs.';
                }
                field("ARN No."; "ARN No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ARN number of the consignee till GST registration number is not assigned to the consignee.';
                }
            }
        }
    }
}
