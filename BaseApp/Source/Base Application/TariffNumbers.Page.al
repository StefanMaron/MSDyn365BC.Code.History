page 310 "Tariff Numbers"
{
    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the item.';
                }
                field("Supplementary Units"; "Supplementary Units")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the customs and tax authorities require information about quantity and unit of measure for this item.';
                }
                field("Supplem. Unit of Measure Code"; "Supplem. Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the supplementary unit of measure code for the tariff number. This number is assigned to an item.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Statement Code"; "Statement Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statement code for VAT control report and reverse charge.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Statement Limit Code"; "Statement Limit Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statement limit code for VAT control report and reverse charge.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VAT Stat. Unit of Measure Code"; "VAT Stat. Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit of measure code for reverse charge reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Allow Empty Unit of Meas.Code"; "Allow Empty Unit of Meas.Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the possibillity to allow or not allow empty unit of meas. code for VAT reverse charge.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
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

