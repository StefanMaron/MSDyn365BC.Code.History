page 17363 "HR Field Group"
{
    Caption = 'HR Field Group';
    PageType = Document;
    SourceTable = "HR Field Group";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Print Order"; "Print Order")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No. of Fields"; "No. of Fields")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            part(Control1210006; "HR Field Group Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Field Group Code" = FIELD(Code);
            }
        }
    }

    actions
    {
    }
}

