page 5732 "Catalog Item Setup"
{
    AdditionalSearchTerms = 'non-inventoriable setup,special order setup';
    ApplicationArea = Basic, Suite;
    Caption = 'Catalog Item Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Nonstock Item Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No. Format"; "No. Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of the catalog item number that appears on the item card.';
                }
                field("No. Format Separator"; "No. Format Separator")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the character that separates the elements of your catalog item number format, if the format uses both a code and a number.';
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

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

