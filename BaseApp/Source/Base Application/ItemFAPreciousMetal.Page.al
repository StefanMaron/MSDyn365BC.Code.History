page 12487 "Item/FA Precious Metal"
{
    Caption = 'Item/FA Precious Metal';
    PageType = List;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Item/FA Precious Metal";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Precious Metals Code"; "Precious Metals Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code associated with this precious metal asset.';
                }
                field(Name; Name)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the name of the precious metal asset.';
                }
                field(Kind; Kind)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies and describes the precious metal.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the quantity of units of the precious metal asset.';
                }
                field(Mass; Mass)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the weight of the precious metal asset.';
                }
                field("Nomenclature No."; "Nomenclature No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code used in technical literature to refer to alloy names or alloy designations.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related document.';
                }
            }
        }
    }

    actions
    {
    }
}

