page 367 "Post Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Post Codes';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Post Code";
    UsageCategory = Lists;

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
                field(Priority; Priority)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a priority to sort cities with the same post code.';
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Import Post Codes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Post Codes';
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Report "Import Post Codes";
                    ToolTip = 'Update the postal code directory with information from the Swiss Post website. All postal codes in the range 1000 to 9999 will be deleted before import. International postal codes, which include a country/region code, such as DE-60000, are retained.';
                }
            }
        }
    }
}

