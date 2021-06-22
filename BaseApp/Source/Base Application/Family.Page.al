page 99000790 Family
{
    Caption = 'Family';
    PageType = ListPlus;
    SourceTable = Family;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description for a product family.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies an additional description of the product family if there is not enough space in the Description field.';
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field("Routing No."; "Routing No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the routing which is used for the production of the family.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies when the standard data of this production family was last modified.';
                }
            }
            part(Control13; "Family Lines")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Family No." = FIELD("No.");
                SubPageView = SORTING("Family No.", "Line No.");
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

