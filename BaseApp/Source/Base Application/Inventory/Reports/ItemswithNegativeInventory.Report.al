namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Worksheet;
using System.Utilities;

report 5757 "Items with Negative Inventory"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/ItemswithNegativeInventory.rdlc';
    Caption = 'Items with Negative Inventory';
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Output; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(LocationCode; StrSubstNo('%1: %2', ItemLedgEntry.FieldCaption("Location Code"), LocCode))
            {
            }
            column(ItemLedgEntryBufferItemNo; TempItemLedgEntry."Item No.")
            {
            }
            column(ItemLedgEntryBufferRemainQty; TempItemLedgEntry."Remaining Quantity")
            {
                DecimalPlaces = 0 : 5;
            }
            column(ItemLedgEntryBufferPackageNo; TempItemLedgEntry."Package No.")
            {
            }
            column(ItemLedgEntryBufferLotNo; TempItemLedgEntry."Lot No.")
            {
            }
            column(ItemLedgEntryBufferSerialNo; TempItemLedgEntry."Serial No.")
            {
            }
            column(ItemLedgEntryBufferUOMCode; TempItemLedgEntry."Unit of Measure Code")
            {
            }
            column(ItemLedgEntryBufferDesc; TempItemLedgEntry.Description)
            {
            }
            column(ItemLedgEntryBufferVariantCode; TempItemLedgEntry."Variant Code")
            {
            }
            column(Check_on_Negative_InventoryCaption; Items_with_Negative_InventoryLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(ItemLedgEntryBufferRemainQtyCaption; ItemLedgEntryBufferRemainQtyCaption)
            {
            }
            column(ItemLedgEntryBufferPackageNoCaption; ItemLedgEntryBufferPackageNoCaption)
            {
            }
            column(ItemLedgEntryBufferLotNoCaption; ItemLedgEntryBufferLotNoCaption)
            {
            }
            column(ItemLedgEntryBufferSerialNoCaption; ItemLedgEntryBufferSerialNoCaption)
            {
            }
            column(ItemLedgEntryBufferUOMCodeCaption; ItemLedgEntryBufferUOMCodeCaption)
            {
            }
            column(ItemLedgEntryBufferDescCaption; ItemLedgEntryBufferDescCaption)
            {
            }
            column(ItemLedgEntryBufferVariantCodeCaption; ItemLedgEntryBufferVariantCodeCaption)
            {
            }
            column(ItemLedgEntryBufferItemNoCaption; ItemLedgEntryBufferItemNoCaption)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if ILECounter = 0 then
                    TempItemLedgEntry.Description := Text004
                else begin
                    if Number = 1 then
                        TempItemLedgEntry.Find('-')
                    else
                        TempItemLedgEntry.Next();

                    if TempItemLedgEntry.Description = '' then
                        if TempItemLedgEntry."Variant Code" <> '' then begin
                            ItemVariant.Get(TempItemLedgEntry."Item No.", TempItemLedgEntry."Variant Code");
                            TempItemLedgEntry.Description := ItemVariant.Description;
                        end else begin
                            Item.Get(TempItemLedgEntry."Item No.");
                            TempItemLedgEntry.Description := Item.Description;
                        end
                end;
            end;

            trigger OnPreDataItem()
            begin
                TempItemLedgEntry.SetCurrentKey(
                  "Item No.", "Location Code", Open, "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.", "Package No.");

                ILECounter := TempItemLedgEntry.Count();
                if ILECounter = 0 then
                    SetRange(Number, 1)
                else
                    SetRange(Number, 1, ILECounter);

                ItemLedgEntryBufferRemainQtyCaption := ItemLedgEntry.FieldCaption(Quantity);
                ItemLedgEntryBufferLotNoCaption := ItemLedgEntry.FieldCaption("Lot No.");
                ItemLedgEntryBufferSerialNoCaption := ItemLedgEntry.FieldCaption("Serial No.");
                ItemLedgEntryBufferUOMCodeCaption := ItemLedgEntry.FieldCaption("Unit of Measure Code");
                ItemLedgEntryBufferDescCaption := ItemLedgEntry.FieldCaption("Description");
                ItemLedgEntryBufferVariantCodeCaption := ItemLedgEntry.FieldCaption("Variant Code");
                ItemLedgEntryBufferItemNoCaption := ItemLedgEntry.FieldCaption("Item No.");

            end;
        }
        dataitem(ErrorLoop; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(ErrorTextNumber; ErrorText[Number])
            {
            }
            column(ErrorTextNumberCaption; ErrorTextNumberCaptionLbl)
            {
            }

            trigger OnPostDataItem()
            begin
                ErrorCounter := 0;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, ErrorCounter);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(LocationCode; LocCode)
                    {
                        ApplicationArea = Location;
                        Caption = 'Location Code';
                        ShowMandatory = true;
                        ToolTip = 'Specifies the location for items with negative inventory.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Clear(Location);
                            if LocCode <> '' then
                                Location.Code := LocCode;
                            if PAGE.RunModal(0, Location) = ACTION::LookupOK then
                                LocCode := Location.Code;
                        end;

                        trigger OnValidate()
                        begin
                            Location.Get(LocCode);
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if LocCode = '' then
            Error(Text001);

        ItemLedgEntry.SetCurrentKey(
          "Item No.", "Location Code", Open, "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.");

        if ItemLedgEntry.Find('-') then begin
            Window.Open(StrSubstNo(Text002, ItemLedgEntry.FieldCaption("Location Code"), LocCode) + Text003);
            i := 1;
            ILECounter := ItemLedgEntry.Count;
            repeat
                Window.Update(100, i);
                Window.Update(102, Round(i / ILECounter * 10000, 1));

                ItemLedgEntry.SetRange("Item No.", ItemLedgEntry."Item No.");
                if ItemLedgEntry.Find('-') then begin
                    ItemLedgEntry.SetRange("Location Code", LocCode);
                    ItemLedgEntry.SetRange(Open, true);
                    if ItemLedgEntry.Find('-') then
                        repeat
                            ItemLedgEntry.SetRange("Variant Code", ItemLedgEntry."Variant Code");
                            if ItemLedgEntry.Find('-') then
                                repeat
                                    ItemLedgEntry.SetRange("Unit of Measure Code", ItemLedgEntry."Unit of Measure Code");
                                    if ItemLedgEntry.Find('-') then
                                        repeat
                                            ItemLedgEntry.SetRange("Package No.", ItemLedgEntry."Package No.");
                                            if ItemLedgEntry.Find('-') then
                                                repeat
                                                    ItemLedgEntry.SetRange("Lot No.", ItemLedgEntry."Lot No.");
                                                    if ItemLedgEntry.Find('-') then
                                                        repeat
                                                            ItemLedgEntry.SetRange("Serial No.", ItemLedgEntry."Serial No.");
                                                            ItemLedgEntry.CalcSums("Remaining Quantity");
                                                            if ItemLedgEntry."Remaining Quantity" < 0 then
                                                                FillBuffer();
                                                            ItemLedgEntry.Find('+');
                                                            ItemLedgEntry.SetRange("Serial No.");
                                                        until ItemLedgEntry.Next() = 0;
                                                    ItemLedgEntry.Find('+');
                                                    ItemLedgEntry.SetRange("Lot No.");
                                                until ItemLedgEntry.Next() = 0;
                                            ItemLedgEntry.Find('+');
                                            ItemLedgEntry.SetRange("Package No.");
                                        until ItemLedgEntry.Next() = 0;
                                    ItemLedgEntry.Find('+');
                                    ItemLedgEntry.SetRange("Unit of Measure Code")
                                until ItemLedgEntry.Next() = 0;

                            ItemLedgEntry.Find('+');
                            ItemLedgEntry.SetRange("Variant Code");
                        until ItemLedgEntry.Next() = 0;
                end;

                ItemLedgEntry.SetRange(Open);
                ItemLedgEntry.SetRange("Location Code");
                ItemLedgEntry.Find('+');
                i := i + ItemLedgEntry.Count;
                ItemLedgEntry.SetRange("Item No.");
            until ItemLedgEntry.Next() = 0;

            Window.Close();
        end;

        ErrorCounter := 0;
        WhseRcptHeader.SetCurrentKey("Location Code");
        WhseRcptHeader.SetRange("Location Code", LocCode);
        if WhseRcptHeader.FindFirst() then
            AddError(
              StrSubstNo(
                Text005,
                WhseRcptHeader.TableCaption(),
                WhseRcptHeader.FieldCaption("Location Code"),
                LocCode));

        WhseShipHeader.SetCurrentKey("Location Code");
        WhseShipHeader.SetRange("Location Code", LocCode);
        if WhseShipHeader.FindFirst() then
            AddError(
              StrSubstNo(
                Text005,
                WhseShipHeader.TableCaption(),
                WhseShipHeader.FieldCaption("Location Code"),
                LocCode));

        for i := 1 to 2 do begin
            WhseActHeader.SetCurrentKey("Location Code");
            WhseActHeader.SetRange("Location Code", LocCode);
            WhseActHeader.SetRange(Type, i);
            if WhseActHeader.FindFirst() then
                AddError(
                  StrSubstNo(
                    Text006,
                    WhseActHeader.Type,
                    WhseActHeader.FieldCaption("Location Code"),
                    LocCode));
        end;

        WhseWkshLine.SetCurrentKey("Item No.", "Location Code");
        WhseWkshLine.SetRange("Location Code", LocCode);
        if WhseWkshLine.FindFirst() then
            AddError(
              StrSubstNo(
                Text007,
                WhseWkshLine.TableCaption(),
                WhseWkshLine.FieldCaption("Location Code"),
                LocCode));
    end;

    var
        Location: Record Location;
        ItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseShipHeader: Record "Warehouse Shipment Header";
        WhseActHeader: Record "Warehouse Activity Header";
        WhseWkshLine: Record "Whse. Worksheet Line";
        Window: Dialog;
        LocCode: Code[10];
        Text001: Label 'Enter a location code.';
        Text002: Label 'Checking %1 %2 for negative inventory...\\';
        Text003: Label 'Count #100##### @102@@@@@@@@';
        i: Integer;
        ILECounter: Integer;
        Text004: Label 'No negative inventory was found.';
        Text005: Label 'A %1 exists for %2 %3. It must be either posted or deleted before running the Create Whse. Location batch job.';
        ErrorCounter: Integer;
        ErrorText: array[5] of Text[250];
        Text006: Label 'A %1 exists for %2 %3. It must be either registered or deleted before running the Create Whse. Location batch job.';
        Text007: Label 'A %1 exists for %2 %3. It must be deleted before running the Create Whse. Location batch job.';
        Items_with_Negative_InventoryLbl: Label 'Items with Negative Inventory';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ItemLedgEntryBufferRemainQtyCaption: Text;
        ItemLedgEntryBufferPackageNoCaption: Text;
        ItemLedgEntryBufferLotNoCaption: Text;
        ItemLedgEntryBufferSerialNoCaption: Text;
        ItemLedgEntryBufferUOMCodeCaption: Text;
        ItemLedgEntryBufferDescCaption: Text;
        ItemLedgEntryBufferVariantCodeCaption: Text;
        ItemLedgEntryBufferItemNoCaption: Text;
        ErrorTextNumberCaptionLbl: Label 'Error!';

    local procedure FillBuffer()
    begin
        TempItemLedgEntry := ItemLedgEntry;
        TempItemLedgEntry.Insert();
    end;

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    procedure InitializeRequest(NewLocCode: Code[10])
    begin
        LocCode := NewLocCode;
    end;
}

