page 9126 "Lot Numbers by Bin FactBox"
{
    Caption = 'Lot Numbers by Bin';
    PageType = ListPart;
    SourceTable = "Lot Bin Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control7)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item that exists as lot numbers in the bin.';
                    Visible = false;
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone that is assigned to the bin where the lot number exists.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the lot number exists.';
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the lot number that exists in the bin.';
                }
                field("Qty. (Base)"; "Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many items with the lot number exist in the bin.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        FillTempTable;
        exit(Find(Which));
    end;

    local procedure FillTempTable()
    var
        LotNosByBinCode: Query "Lot Numbers by Bin";
    begin
        LotNosByBinCode.SetRange(Item_No, GetRangeMin("Item No."));
        LotNosByBinCode.SetRange(Variant_Code, GetRangeMin("Variant Code"));
        LotNosByBinCode.SetRange(Location_Code, GetRangeMin("Location Code"));
        LotNosByBinCode.SetFilter(Lot_No, '<>%1', '');
        LotNosByBinCode.Open;

        DeleteAll();

        while LotNosByBinCode.Read do begin
            Init;
            "Item No." := LotNosByBinCode.Item_No;
            "Variant Code" := LotNosByBinCode.Variant_Code;
            "Zone Code" := LotNosByBinCode.Zone_Code;
            "Bin Code" := LotNosByBinCode.Bin_Code;
            "Location Code" := LotNosByBinCode.Location_Code;
            "Lot No." := LotNosByBinCode.Lot_No;
            if Find then begin
                "Qty. (Base)" += LotNosByBinCode.Sum_Qty_Base;
                Modify;
            end else begin
                "Qty. (Base)" := LotNosByBinCode.Sum_Qty_Base;
                Insert;
            end;
        end;
    end;
}

