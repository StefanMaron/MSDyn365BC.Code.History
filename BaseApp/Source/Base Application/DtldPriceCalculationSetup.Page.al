page 7008 "Dtld. Price Calculation Setup"
{
    Caption = 'Detailed Price Calculation Setup';
    DataCaptionExpression = Heading;
    PageType = List;
    SourceTable = "Dtld. Price Calculation Setup";
    // ApplicationArea and UsageCategory properties should be enabled by an extension
    // ApplicationArea = Basic, Suite;
    // UsageCategory = Administration;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(SetupCode; "Setup Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a price calculation setup code.';
                    Visible = IsSetupCodeVisible;
                }
                field(CalculationMethod; Method)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a price calculation method.';
                    Visible = IsSetupCodeVisible;
                }
                field(Implementation; Implementation)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a price calculation implemetation name.';
                    Visible = IsSetupCodeVisible;
                    DrillDown = false;
                }
                field(PriceType; Type)
                {
                    Visible = IsSetupCodeVisible;
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies what type of amount to calculate - price or cost.';
                }
                field(AssetType; "Asset Type")
                {
                    Visible = IsSetupCodeVisible;
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies an asset type.';
                }
                field(AssetNo; "Asset No.")
                {
                    Editable = IsAssetNoEditable;
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies an asset number.';
                }
                field(SourceGroup; "Source Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a source group.';
                }
                field(SourceNo; "Source No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a source number.';
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the implementation codeunit is enabled.';
                }
            }
        }
    }

    var
        IsSetupCodeVisible: Boolean;
        IsAssetNoEditable: Boolean;
        Heading: text;

    trigger OnOpenPage()
    var
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
    begin
        IsSetupCodeVisible := GetFilter("Setup Code") = '';
        if not IsSetupCodeVisible then begin
            DtldPriceCalculationSetup.Validate("Setup Code", GetRangeMax("Setup Code"));
            Heading :=
                StrSubstNo('%1 %2 (%3) %4',
                    DtldPriceCalculationSetup.Type, DtldPriceCalculationSetup."Asset Type",
                    DtldPriceCalculationSetup.Method, DtldPriceCalculationSetup.Implementation);
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        IsAssetNoEditable := "Asset Type" <> "Asset Type"::" ";
    end;

    trigger OnNewRecord(BelowXRec: Boolean)
    begin
        if GetFilter("Setup Code") <> '' then
            Validate("Setup Code", GetRangeMin("Setup Code"));
    end;
}