page 575 "VAT Registration No. Formats"
{
    AutoSplitKey = true;
    Caption = 'VAT Registration No. Formats';
    DataCaptionFields = "Country/Region Code";
    PageType = List;
    SourceTable = "VAT Registration No. Format";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field(Format; Format)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a format for a country''s/region''s VAT registration number.';
                }
                field("Check VAT Registration No."; Rec."Check VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Test VAT Registration Number")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test VAT Registration Number';
                    Image = SuggestNumber;
                    RunObject = Report "Test VAT Registration Number";
                    ToolTip = 'View the company VAT registration numbers for customers, vendors, and company contacts. VAT registration numbers consist of 15 alphanumeric characters. The first two characters indicate the country/region where the business is registered. For example, ES indicates Spain.';
                }
            }
        }
    }
}

