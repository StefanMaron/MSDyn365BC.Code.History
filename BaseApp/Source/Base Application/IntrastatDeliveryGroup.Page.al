page 31064 "Intrastat Delivery Group"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Intrastat Delivery Group (Obsolete)';
    PageType = List;
    SourceTable = "Intrastat Delivery Group";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Control1220005)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the intrastat delivery group.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the descpriton of intrastat delivery group.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220000; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220001; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
    }
}

