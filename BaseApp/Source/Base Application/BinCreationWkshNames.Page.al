page 7369 "Bin Creation Wksh. Names"
{
    Caption = 'Bin Creation Wksh. Names';
    DataCaptionExpression = DataCaption;
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Bin Creation Wksh. Name";

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
                    ToolTip = 'Specifies a name for the worksheet.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description for the worksheet.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code for which the worksheet should be used.';
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

    local procedure DataCaption(): Text[250]
    var
        BinCreateWkshTmpl: Record "Bin Creation Wksh. Template";
    begin
        if not CurrPage.LookupMode then
            if GetFilter("Worksheet Template Name") <> '' then
                if GetRangeMin("Worksheet Template Name") = GetRangeMax("Worksheet Template Name") then
                    if BinCreateWkshTmpl.Get(GetRangeMin("Worksheet Template Name")) then
                        exit(BinCreateWkshTmpl.Name + ' ' + BinCreateWkshTmpl.Description);
    end;
}

