pageextension 18142 "GST Customer Card Ext" extends "Customer Card"
{
    layout
    {
        addlast("Tax Information")
        {
            group("GST")
            {
                field("GST customer Type"; "GST customer Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of GST registration for the customer. For example, Registered/Un-registered/Export/Deemed Export etc..';
                }
                field("GST Registration Type"; "GST Registration Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the goods and services Tax registration type of party.';
                }
                field("GST Registration No."; "GST Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s goods and service tax registration number issued by authorized body.';
                }
                field("E-Commerce Operator"; "E-Commerce Operator")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the party is e-commerce operator.';
                }
                field("ARN No."; "ARN No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ARN number in case goods and service tax registration number is not available or applied by the party';
                }
            }
        }
    }
}
