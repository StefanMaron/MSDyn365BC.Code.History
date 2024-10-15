page 31062 "Statistic Indications"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Statistic Indications (Obsolete)';
    PageType = List;
    SourceTable = "Statistic Indication";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies full name of tariff number.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This field should not be used and will be removed.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Full Name ENG"; "Full Name ENG")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies full name of tariff number.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This field should not be used and will be removed.';
                    ObsoleteTag = '17.0';
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

