page 7603 "Customized Calendar Changes"
{
    Caption = 'Customized Calendar Changes';
    DataCaptionExpression = GetCaption;
    PageType = List;
    SourceTable = "Customized Calendar Change";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the source type, such as company, for this entry.';
                    Visible = false;
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Base Calendar Code"; "Base Calendar Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which base calendar was used as the basis for this customized calendar.';
                    Visible = false;
                }
                field("Recurring System"; "Recurring System")
                {
                    ApplicationArea = Suite;
                    Caption = 'Recurring System';
                    ToolTip = 'Specifies a date or day as a recurring nonworking or working day.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date associated with this customized calendar entry.';
                }
                field(Day; Day)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the day of the week associated with this entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of this entry.';
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

