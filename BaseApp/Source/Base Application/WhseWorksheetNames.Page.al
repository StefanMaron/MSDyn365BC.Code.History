page 7344 "Whse. Worksheet Names"
{
    Caption = 'Whse. Worksheet Names';
    DataCaptionExpression = DataCaption;
    PageType = List;
    SourceTable = "Whse. Worksheet Name";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the name you enter for the worksheet.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code of the warehouse the worksheet should be used for.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description for the worksheet.';
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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetupNewName;
    end;

    local procedure DataCaption(): Text[250]
    var
        WhseWkshTemplate: Record "Whse. Worksheet Template";
    begin
        if not CurrPage.LookupMode then
            if GetFilter("Worksheet Template Name") <> '' then
                if GetRangeMin("Worksheet Template Name") = GetRangeMax("Worksheet Template Name") then
                    if WhseWkshTemplate.Get(GetRangeMin("Worksheet Template Name")) then
                        exit(WhseWkshTemplate.Name + ' ' + WhseWkshTemplate.Description);
    end;
}

