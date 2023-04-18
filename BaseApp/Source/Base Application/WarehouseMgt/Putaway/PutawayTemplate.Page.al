page 7312 "Put-away Template"
{
    Caption = 'Put-away Template';
    PageType = ListPlus;
    SourceTable = "Put-away Template Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the put-away template header.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the put-away template header.';
                }
            }
            part(Control8; "Put-away Template Subform")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "Put-away Template Code" = FIELD(Code);
                Visible = true;
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
    }
}

