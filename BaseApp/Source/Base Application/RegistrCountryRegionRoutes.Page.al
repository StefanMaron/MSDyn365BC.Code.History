page 11763 "Registr. Country/Region Routes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Registration Country/Region';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Registr. Country/Region Route";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1220007)
            {
                ShowCaption = false;
                field("Perform. Country/Region Code"; "Perform. Country/Region Code")
                {
                    ToolTip = 'Specifies the registration Country for our company.';
                    Visible = false;
                }
                field("Final Country/Region Code"; "Final Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registration Country for Customer and Vendor.';
                }
                field("Old VAT Bus. Posting Group"; "Old VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT Bus. Posting Group in customes or vendor Card.';
                }
                field("New VAT Bus. Posting Group"; "New VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a new VAT Bus. Posting Goup for Final Country/Region Code';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

