page 310 "Tariff Numbers"
{
    ApplicationArea = BasicEU;
    Caption = 'Tariff Numbers';
    PageType = List;
    SourceTable = "Tariff Number";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a description of the item.';
                }
                field("Supplementary Units"; "Supplementary Units")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies whether the customs and tax authorities require information about quantity and unit of measure for this item.';
                }
                field("Supplem. Unit of Measure Code"; "Supplem. Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the supplementary unit of measure code for the tariff number. This number is assigned to an item.';
                }
                field("Statement Code"; "Statement Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statement code for VAT control report and reverse charge.';
                }
                field("Statement Limit Code"; "Statement Limit Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statement limit code for VAT control report and reverse charge.';
                }
                field("VAT Stat. Unit of Measure Code"; "VAT Stat. Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit of measure code for reverse charge reporting.';
                }
                field("Allow Empty Unit of Meas.Code"; "Allow Empty Unit of Meas.Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the possibillity to allow or not allow empty unit of meas. code for VAT reverse charge.';
                }
                field("Full Name"; "Full Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies full name of tariff number.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Fields for Full Description will be removed and this field should not be used. Standard fields for Name are now 100. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
                field("Full Name ENG"; "Full Name ENG")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies full name of tariff number.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Fields for Full Description will be removed and this field should not be used. Standard fields for Name are now 100. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
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

