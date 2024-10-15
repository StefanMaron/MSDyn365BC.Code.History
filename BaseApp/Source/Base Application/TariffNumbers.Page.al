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

