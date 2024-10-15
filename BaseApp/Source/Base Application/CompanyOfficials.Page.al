page 12160 "Company Officials"
{
    Caption = 'Company Officials';
    CardPageID = "Company Officials Card";
    Editable = false;
    PageType = List;
    SourceTable = "Company Officials";

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique entry number that is assigned to the company official.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee identification number of the company official.';
                }
                field(FullName; FullName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Full Name';
                    ToolTip = 'Specifies the full name of the person.';
                }
                field("First Name"; "First Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first name of the company official.';
                    Visible = false;
                }
                field("Middle Name"; "Middle Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the middle name of the company official.';
                    Visible = false;
                }
                field("Last Name"; "Last Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last name of the company official.';
                    Visible = false;
                }
                field(Initials; Initials)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the initials of the company official.';
                    Visible = false;
                }
                field("Job Title"; "Job Title")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the job title of the company official.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the post code of the company official.';
                    Visible = false;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the residence of the company official.';
                    Visible = false;
                }
                field(Extension; Extension)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone extension number of the company official.';
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the phone number of the company official.';
                    Visible = false;
                }
                field("Mobile Phone No."; "Mobile Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the mobile telephone number of the company official.';
                    Visible = false;
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the email address of the company official.';
                    Visible = false;
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a search name for the company official.';
                }
            }
        }
    }

    actions
    {
    }
}

