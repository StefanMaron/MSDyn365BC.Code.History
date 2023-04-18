page 7028 "Price Calc. Implementations"
{
    Caption = 'Available Implementations';
    PageType = List;
    SourceTable = "Price Calculation Setup";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Extensible = true;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Implementation; Implementation)
                {
                    ToolTip = 'The name of the implementation codeunit or extension that will do the price calculation.';
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    procedure SetData(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
        Rec.Copy(TempPriceCalculationSetup, true);
    end;
}