page 5209 "Employee Relatives"
{
    AutoSplitKey = true;
    Caption = 'Employee Relatives';
    DataCaptionFields = "Person No.";
    PageType = List;
    SourceTable = "Employee Relative";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Relative Code"; "Relative Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a relative code for the employee.';
                }
                field("Relative Person No."; "Relative Person No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the relative''s employee number, if the relative also works at the company.';
                }
                field("First Name"; "First Name")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the first name of the employee''s relative.';
                }
                field("Middle Name"; "Middle Name")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the middle name of the employee''s relative.';
                    Visible = false;
                }
                field("Last Name"; "Last Name")
                {
                }
                field("Birth Date"; "Birth Date")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the relative''s date of birth.';
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the relative''s telephone number.';
                }
                field("Relation Start Date"; "Relation Start Date")
                {
                }
                field("Relation End Date"; "Relation End Date")
                {
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies if a comment was entered for this entry.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Relative")
            {
                Caption = '&Relative';
                Image = Relatives;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Human Resource Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Employee Relative"),
                                  "No." = FIELD("Person No."),
                                  "Table Line No." = FIELD("Line No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
    }
}

