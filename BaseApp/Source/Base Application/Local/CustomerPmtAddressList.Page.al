#if not CLEAN22
page 7000039 "Customer Pmt. Address List"
{
    Caption = 'Customer Pmt. Address List';
    CardPageID = "Customer Pmt. Address Card";
    DataCaptionFields = "Customer No.";
    Editable = false;
    PageType = List;
    SourceTable = "Customer Pmt. Address";
    ObsoleteReason = 'Address is taken from the fields Bill-to Address, Bill-to City, etc.';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code to identify the customer''s payment address.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a number to identify the customer''s payment address.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code for this address.';
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code for the city in this address.';
                    Visible = false;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number for this address.';
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fax number for this address.';
                    Visible = false;
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person at this customer payment address to whose attention you usually send the items.';
                }
            }
        }
    }

    actions
    {
    }
}


#endif