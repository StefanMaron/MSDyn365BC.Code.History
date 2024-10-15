page 12159 "Company Officials Card"
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
                    ToolTip = 'Specifies the unique entry number that is assigned to the company official.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Job Title"; "Job Title")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the job title of the company official.';
                }
                field("First Name"; "First Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first name of the company official.';
                }
                field("Last Name"; "Last Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last name of the company official.';
                }
                field("Middle Name"; "Middle Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Middle Name/Initials';
                    ToolTip = 'Specifies the middle name of the company official.';
                }
                field(Initials; Initials)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the initials of the company official.';
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the company official.';
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional address information for the company official.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Code/City';
                    ToolTip = 'Specifies the post code of the company official.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of residence of the company official.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the residence of the company official.';
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the phone number of the company official.';
                }
                field("Date of Birth"; "Date of Birth")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of birth of the individual person.';
                }
                field("Birth Post Code"; "Birth Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the city where the person was born.';
                }
                field("Birth City"; "Birth City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city where the person was born.';
                }
                field("Birth County"; "Birth County")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the county where the person was born.';
                }
                field(Gender; Gender)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the gender of the person.';
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a search name for the company official.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee identification number of the company official.';
                }
                field("Area"; Area)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the area of residence of the company official.';
                }
                field("Fiscal Code"; "Fiscal Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fiscal identification code that is assigned by the government to interact with state and public offices and authorities.';
                }
                field("Appointment Code"; "Appointment Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the company that is submitting VAT statements on behalf of other legal entities.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the company official''s information was last changed.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field(Extension; Extension)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone extension number of the company official.';
                }
                field("Mobile Phone No."; "Mobile Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the mobile telephone number of the company official.';
                }
                field(Pager; Pager)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the pager number of the company official.';
                }
                field("Phone No.2"; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the phone number of the company official.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the email address of the company official.';
                }
            }
        }
    }

    actions
    {
    }
}

