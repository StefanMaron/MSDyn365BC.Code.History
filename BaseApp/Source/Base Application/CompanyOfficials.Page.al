page 11792 "Company Officials"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Company Officials';
    CardPageID = "Company Officials Card";
    Editable = false;
    PageType = List;
    SourceTable = "Company Officials";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1220018)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of company officials.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee number for the company official.';
                }
                field(FullName; FullName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Full Name';
                    ToolTip = 'Specifies the full name of company officials.';
                }
                field("First Name"; "First Name")
                {
                    ToolTip = 'Specifies the employee''s first name.';
                    Visible = false;
                }
                field("Middle Name"; "Middle Name")
                {
                    ToolTip = 'Specifies the employee''s middle name.';
                    Visible = false;
                }
                field("Last Name"; "Last Name")
                {
                    ToolTip = 'Specifies the employee''s last name.';
                    Visible = false;
                }
                field(Initials; Initials)
                {
                    ToolTip = 'Specifies initials';
                    Visible = false;
                }
                field("Job Title"; "Job Title")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s job title.';
                }
                field("Post Code"; "Post Code")
                {
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ToolTip = 'Specifies the country/region code.';
                    Visible = false;
                }
                field(Extension; Extension)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies extention';
                }
                field("Phone No."; "Phone No.")
                {
                    ToolTip = 'Specifies the employee''s phone number.';
                    Visible = false;
                }
                field("Mobile Phone No."; "Mobile Phone No.")
                {
                    ToolTip = 'Specifies the employee''s mobile phone number.';
                    Visible = false;
                }
                field("E-Mail"; "E-Mail")
                {
                    ToolTip = 'Specifies the e-mail address for the company official.';
                    Visible = false;
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s search name.';
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

