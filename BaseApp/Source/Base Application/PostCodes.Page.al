page 367 "Post Codes"
{
    Caption = 'Post Codes';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Post Code";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code that is associated with a city.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city linked to the postal code in the Code field.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field(County; County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a county name.';
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
        area(navigation)
        {
            group("&Post Code")
            {
                Caption = '&Post Code';
                Image = ZoneCode;
                action("&Ranges")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Ranges';
                    Image = Ranges;
                    RunObject = Page "Post Code Ranges";
                    RunPageLink = "Post Code" = FIELD(Code),
                                  City = FIELD(City);
                    RunPageView = SORTING("Post Code", City, Type, "From No.");
                    ToolTip = 'View or edit street names and cities by post codes. When you enter the post code and house number in an address field the program assists you in filling in the corresponding street name and city. If the house number does not fit into a range by the given post code, the Post Code Range window appears with a list of all the street names and cities by the given post code for you to select from.';
                }
            }
        }
    }
}

