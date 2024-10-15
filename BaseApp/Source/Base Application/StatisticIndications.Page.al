page 31062 "Statistic Indications"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Statistic Indications';
    PageType = List;
    SourceTable = "Statistic Indication";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1220008)
            {
                ShowCaption = false;
                field("Tariff No."; "Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the item''s tariff number.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statistic indication code for the item.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description for statistic indications.';
                }
                field("Full Name"; "Full Name")
                {
                    ToolTip = 'Specifies full name of tariff number.';
                    Visible = false;
                }
                field("Full Name ENG"; "Full Name ENG")
                {
                    ToolTip = 'Specifies full name of tariff number.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
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

