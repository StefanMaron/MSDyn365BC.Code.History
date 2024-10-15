pageextension 18099 "GST Parties" extends Parties
{
    layout
    {
        addafter(Address)
        {
            field("Address 2"; "Address 2")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the additional address information.';
            }
            field(State; State)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the Parties state code. This state code will appear on all documents for the party.';
            }
            field("Post Code"; "Post Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the Parties postal code.';
            }
            field("P.A.N. No."; "P.A.N. No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the Permanent Account Number of the Party.';
            }
            field("P.A.N. Reference No."; "P.A.N. Reference No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the PAN reference number in case the PAN is not available or applied by the party.';
            }
            field("P.A.N. Status"; "P.A.N. Status")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the PAN status.';
            }
            field("GST Party Type"; "GST Party Type")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the party type. For example, Vendor/Customer.';
            }
            field("GST Vendor Type"; "GST Vendor Type")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the type of the vendor. For example, Registered, Unregistered, Import, Exempted, SEZ etc.';
            }
            field("Associated Enterprises"; "Associated Enterprises")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies if party is an associated enterprise';
            }
            field("GST Registration Type"; "GST Registration Type")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the GST registration type. For example, GSTIN,UID,GID.';
            }
            field("GST Customer Type"; "GST Customer Type")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the type of the customer. For example, Registered, Unregistered, Export etc.';
            }
            field("GST Registration No."; "GST Registration No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the Parties goods and service tax registration number issued by authorized body.';
            }
            field("ARN No."; "ARN No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the ARN number in case goods and service tax registration number is not available or applied by the party.';
            }
        }
    }
}
