page 5955 "Standard Service Code Card"
{
    Caption = 'Standard Service Code Card';
    PageType = ListPlus;
    SourceTable = "Standard Service Code";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a standard service code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service the standard service code represents.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the currency on the standard service lines linked to the standard service code.';
                }
            }
            part(StdServLines; "Standard Service Code Subform")
            {
                ApplicationArea = Service;
                SubPageLink = "Standard Service Code" = FIELD(Code);
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

