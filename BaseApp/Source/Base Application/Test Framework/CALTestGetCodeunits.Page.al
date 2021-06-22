page 130403 "CAL Test Get Codeunits"
{
    Caption = 'CAL Test Get Codeunits';
    Editable = false;
    PageType = List;
    SourceTable = AllObjWithCaption;
    SourceTableView = WHERE("Object Type" = CONST(Codeunit),
                            "Object Subtype" = CONST('Test'));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = All;
                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
    }
}

