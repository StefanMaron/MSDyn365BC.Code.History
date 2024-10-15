page 11785 "Posting Descriptions"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posting Descriptions';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Posting Description";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1220005)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the posting description.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the posting description.';
                }
                field(Type; Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of issued payment order';
                    Visible = TypeVisible;
                }
                field("Posting Description Formula"; "Posting Description Formula")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the formula for the posting description.';
                }
                field("Validate on Posting"; "Validate on Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the description will be validated';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220007; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220006; Notes)
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
            group("&Post. Desc.")
            {
                Caption = '&Post. Desc.';
                action("Pa&rameters")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pa&rameters';
                    Image = SetupLines;
                    RunObject = Page "Posting Desc. Parameters";
                    RunPageLink = "Posting Desc. Code" = FIELD(Code);
                    ToolTip = 'Open the page for posting descriptions parameters settings.';
                }
            }
        }
    }

    trigger OnInit()
    begin
        TypeVisible := true;
    end;

    trigger OnOpenPage()
    begin
        TypeVisible := GetFilter(Type) = '';
    end;

    var
        [InDataSet]
        TypeVisible: Boolean;
}

