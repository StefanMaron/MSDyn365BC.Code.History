page 31070 "Package Materials"
{
    Caption = 'Package Materials';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Package Material";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1220004)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ToolTip = 'Specifies a code for the package.';
                }
                field(Description; Description)
                {
                    ToolTip = 'Specifies the description for the package material.';
                }
                field("Tax Rate (LCY)"; "Tax Rate (LCY)")
                {
                    ToolTip = 'Specifies the tax rate in LCY.';
                }
                field("Discount %"; "Discount %")
                {
                    ToolTip = 'Specifies a discount percentage for the package material.';
                }
                field("Exemption %"; "Exemption %")
                {
                    ToolTip = 'Specifies an exemption percentage for the package material.';
                }
            }
        }
    }

    actions
    {
    }
}

