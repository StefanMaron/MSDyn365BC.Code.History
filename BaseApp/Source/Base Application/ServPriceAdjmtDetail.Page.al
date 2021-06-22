page 6083 "Serv. Price Adjmt. Detail"
{
    Caption = 'Serv. Price Adjmt. Detail';
    DataCaptionExpression = FormCaption;
    PageType = List;
    SourceTable = "Serv. Price Adjustment Detail";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Serv. Price Adjmt. Gr. Code"; "Serv. Price Adjmt. Gr. Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service price adjustment group that applies to the posted service line.';
                    Visible = ServPriceAdjmtGrCodeVisible;
                }
                field(Type; Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type for the service item line to be adjusted.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Work Type"; "Work Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the work type of the resource.';
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service item, resource, resource group, or service cost, of which the price will be adjusted, based on the value selected in the Type field.';
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

    trigger OnInit()
    begin
        ServPriceAdjmtGrCodeVisible := true;
    end;

    trigger OnOpenPage()
    var
        ServPriceAdjmtGroup: Record "Service Price Adjustment Group";
        ShowColumn: Boolean;
    begin
        ShowColumn := true;
        if GetFilter("Serv. Price Adjmt. Gr. Code") <> '' then
            if ServPriceAdjmtGroup.Get("Serv. Price Adjmt. Gr. Code") then
                ShowColumn := false
            else
                Reset;
        ServPriceAdjmtGrCodeVisible := ShowColumn;
    end;

    var
        [InDataSet]
        ServPriceAdjmtGrCodeVisible: Boolean;

    local procedure FormCaption(): Text[180]
    var
        ServPriceAdjmtGrp: Record "Service Price Adjustment Group";
    begin
        if GetFilter("Serv. Price Adjmt. Gr. Code") <> '' then
            if ServPriceAdjmtGrp.Get("Serv. Price Adjmt. Gr. Code") then
                exit(StrSubstNo('%1 %2', "Serv. Price Adjmt. Gr. Code", ServPriceAdjmtGrp.Description));
    end;
}

