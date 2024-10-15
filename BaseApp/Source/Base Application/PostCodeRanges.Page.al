page 11407 "Post Code Ranges"
{
    Caption = 'Post Code Ranges';
    DataCaptionFields = "Post Code", City;
    Editable = false;
    PageType = List;
    SourceTable = "Post Code Range";

    layout
    {
        area(content)
        {
            repeater(Control1000000)
            {
                ShowCaption = false;
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code to which the address data is related.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city linked to the postal code in the postal code field.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of house number range.';
                }
                field("From No."; "From No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first house number of the range.';
                }
                field("To No."; "To No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last house number of the range.';
                }
                field("Street Name"; "Street Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the street of the postcode and house number range.';
                }
            }
        }
    }

    actions
    {
    }
}

