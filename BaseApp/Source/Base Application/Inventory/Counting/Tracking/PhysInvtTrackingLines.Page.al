#if not CLEAN24
namespace Microsoft.Inventory.Counting.Tracking;

page 5899 "Phys. Invt. Tracking Lines"
{
    Caption = 'Phys. Invt. Tracking Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Phys. Invt. Tracking";
    ObsoleteReason = 'Replaced by page 6029 "Invt.Order.Tracking.Lines"';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number.';
                }
                field("Lot No"; Rec."Lot No")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the lot number.';
                }
                field("Qty. Expected (Base)"; Rec."Qty. Expected (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expected base quantity.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnClosePage()
    begin
        TempPhysInvtTracking := Rec;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        TempPhysInvtTracking.SetView(Rec.GetView());
        TempPhysInvtTracking := Rec;
        if not TempPhysInvtTracking.Find(Which) then
            exit(false);
        Rec := TempPhysInvtTracking;
        exit(true);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        CurrentSteps: Integer;
    begin
        TempPhysInvtTracking := Rec;
        CurrentSteps := TempPhysInvtTracking.Next(Steps);
        if CurrentSteps <> 0 then
            Rec := TempPhysInvtTracking;
        exit(CurrentSteps);
    end;

    var
        TempPhysInvtTracking: Record "Phys. Invt. Tracking" temporary;

    procedure SetSources(var PhysInvtTracking: Record "Phys. Invt. Tracking")
    begin
        TempPhysInvtTracking.Reset();
        TempPhysInvtTracking.DeleteAll();
        if PhysInvtTracking.Find('-') then
            repeat
                TempPhysInvtTracking := PhysInvtTracking;
                TempPhysInvtTracking.Insert();
            until PhysInvtTracking.Next() = 0;
    end;
}
#endif
