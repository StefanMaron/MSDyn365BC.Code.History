page 31071 "Item Package Materials"
{
    Caption = 'Item Package Materials';
    DataCaptionFields = "Item No.";
    PageType = List;
    SourceTable = "Item Package Material";

    layout
    {
        area(content)
        {
            repeater(Control1220003)
            {
                ShowCaption = false;
                field("Item Unit Of Measure Code"; "Item Unit Of Measure Code")
                {
                    ToolTip = 'Specifies the item unit of measure code for the item.';
                }
                field("Package Material Code"; "Package Material Code")
                {
                    ToolTip = 'Specifies the package material code for the item.';
                }
                field(Weight; Weight)
                {
                    ToolTip = 'Specifies the weight of acc. sch. res. subform matrix';
                }
            }
        }
    }

    actions
    {
    }
}

