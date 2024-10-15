page 7602 "Base Calendar Changes"
{
    Caption = 'Base Calendar Changes';
    DataCaptionFields = "Base Calendar Code";
    PageType = List;
    SourceTable = "Base Calendar Change";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Base Calendar Code"; "Base Calendar Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the base calendar in the entry.';
                    Visible = false;
                }
                field("Recurring System"; "Recurring System")
                {
                    ApplicationArea = Suite;
                    Caption = 'Recurring System';
                    ToolTip = 'Specifies a date or day as a recurring nonworking day.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date to change associated with the base calendar in this entry.';
                }
                field(Day; Day)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the day of the week associated with this change entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the change in this entry.';
                }
                field(Nonworking; Nonworking)
                {
                    ApplicationArea = Suite;
                    Caption = 'Nonworking';
                    ToolTip = 'Specifies that the day is not a working day.';
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

