page 7006 "Price Calculation Setup"
{
    Caption = 'Price Calculation Setup';
    PageType = List;
    SourceTable = "Price Calculation Setup";
    // ApplicationArea and UsageCategory properties should be enabled by an extension
    // ApplicationArea = Basic, Suite;
    // UsageCategory = Administration;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies a code that you can select.';
                }
                field(CalculationMethod; Method)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies a price calculation method.';
                }
                field(PriceType; Type)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies what type of amount to calculate - price or cost.';
                }
                field(AssetType; "Asset Type")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies an asset type.';
                }
                field(Details; Details)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the count of detailed price calculation setup records.';
                }
                field(Implementation; Implementation)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies a codeunit that can implement the calculation method.';
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the implementation codeunit is enabled.';
                }
                field(DefaultImpl; Default)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if this is the default implementation. You cannot remove the Default check mark, instead pick another record for the same calculation method to become the default implementation.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        PriceCalculationMgt.Run();
    end;
}