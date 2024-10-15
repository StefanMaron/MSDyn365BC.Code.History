page 31071 "Item Package Materials"
{
    Caption = 'Item Package Materials';
    DataCaptionFields = "Item No.";
    PageType = List;
    SourceTable = "Item Package Material";
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of Packaging Material will be removed and this page should not be used. (Obsolete::Removed in release 01.2021)';

    layout
    {
        area(content)
        {
            repeater(Control1220003)
            {
                ShowCaption = false;
                field("Item Unit Of Measure Code"; "Item Unit Of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item unit of measure code for the item.';
                }
                field("Package Material Code"; "Package Material Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the package material code for the item.';
                }
                field(Weight; Weight)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the weight of acc. sch. res. subform matrix';
                }
            }
        }
    }

    actions
    {
    }
}

