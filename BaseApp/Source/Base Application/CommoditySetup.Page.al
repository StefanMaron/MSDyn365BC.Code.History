page 31096 "Commodity Setup"
{
    Caption = 'Commodity Setup';
    DataCaptionFields = "Commodity Code";
    PageType = List;
    SourceTable = "Commodity Setup";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Commodity Code"; "Commodity Code")
                {
                    ToolTip = 'Specifies code from reverse charge and control report.';
                    Visible = false;
                }
                field("Valid From"; "Valid From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first date for commodity limit amount setup.';
                }
                field("Valid To"; "Valid To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date for commodity limit amount setup.';
                }
                field("Commodity Limit Amount LCY"; "Commodity Limit Amount LCY")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the commodidty limit in LCY. For amounts above the limit has to be used reverse charge.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220008; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220009; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
    }
}

