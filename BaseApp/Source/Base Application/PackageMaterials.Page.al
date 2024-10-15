page 31070 "Package Materials"
{
    Caption = 'Package Materials';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Package Material";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of Packaging Material will be removed and this page should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '15.3';

    layout
    {
        area(content)
        {
            repeater(Control1220004)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the package.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description for the package material.';
                }
                field("Tax Rate (LCY)"; "Tax Rate (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax rate in LCY.';
                }
                field("Discount %"; "Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a discount percentage for the package material.';
                }
                field("Exemption %"; "Exemption %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an exemption percentage for the package material.';
                }
            }
        }
    }

    actions
    {
    }
}

