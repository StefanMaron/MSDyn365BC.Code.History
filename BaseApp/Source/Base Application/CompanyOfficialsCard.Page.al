page 11793 "Company Officials Card"
{
    Caption = 'Company Officials Card';
    PageType = Card;
    SourceTable = "Company Officials";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of company officials.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field("Job Title"; "Job Title")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s job title.';
                }
                field("First Name"; "First Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s first name.';
                }
                field("Last Name"; "Last Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s last name.';
                }
                field("Middle Name"; "Middle Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Middle Name/Initials';
                    ToolTip = 'Specifies the middle name for the company official.';
                }
                field(Initials; Initials)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies initials';
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s address.';
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s address.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Code/City';
                    ToolTip = 'Specifies the postal code for the company official.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s city.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code.';
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s phone number.';
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s search name.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee number for the company official.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the company officials card was last modified.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field(Extension; Extension)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies extention';
                }
                field("Mobile Phone No."; "Mobile Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s mobile phone number.';
                }
                field(Pager; Pager)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies pager of company officials';
                }
                field("Phone No.2"; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s phone number.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the e-mail address for the company official.';
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
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Address")
            {
                Caption = '&Address';
                Image = Addresses;
                separator(Action1220026)
                {
                }
                action("Online Map")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Online Map';
                    Image = Map;
                    ToolTip = 'View the address on an online map.';

                    trigger OnAction()
                    begin
                        DisplayMap;
                    end;
                }
            }
        }
    }
}

