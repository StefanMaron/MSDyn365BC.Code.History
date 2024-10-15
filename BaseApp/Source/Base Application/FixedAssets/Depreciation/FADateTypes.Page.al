namespace Microsoft.FixedAssets.Depreciation;

page 5661 "FA Date Types"
{
    Caption = 'FA Date Types';
    Editable = false;
    PageType = List;
    SourceTable = "FA Date Type";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("FA Date Type Name"; Rec."FA Date Type Name")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the name of the fixed asset data type.';
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
    }
}

