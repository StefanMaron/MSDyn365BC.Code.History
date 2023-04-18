page 7025 "Price Calculation Methods"
{
    PageType = List;
    Caption = 'Price Calculation Methods';
    DataCaptionFields = Method;
    SourceTable = "Price Calculation Setup";
    SourceTableTemporary = true;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Method; Rec.Method)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'The name of the price calculation method.';
                    trigger OnDrillDown()
                    var
                        PriceCalculationMethodCard: Page "Price Calculation Method Card";
                    begin
                        PriceCalculationMethodCard.Set(Rec.Method);
                        PriceCalculationMethodCard.RunModal();
                    end;
                }
                field(Implementations; CountImplementations())
                {
                    Caption = 'Implementations';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'The number of available implementations of the price calculation.';
                }
            }
        }
    }

    var
        ImplementationsPerMethod: Dictionary of [Integer, Integer];

    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
#if not CLEAN21
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
#endif
        PriceUXManagement: Codeunit "Price UX Management";
    begin
#if not CLEAN21
        FeaturePriceCalculation.FailIfFeatureDisabled();
#endif
        if PriceCalculationMgt.RefreshSetup() then
            Commit();
        PriceUXManagement.GetSupportedMethods(Rec, ImplementationsPerMethod);
    end;

    local procedure CountImplementations() Result: Integer;
    begin
        if not ImplementationsPerMethod.Get(Rec.Method.AsInteger(), Result) then
            Result := 0;
    end;
}