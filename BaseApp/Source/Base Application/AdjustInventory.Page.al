page 1327 "Adjust Inventory"
{
    Caption = 'Adjust Inventory';
    DataCaptionExpression = Item."No." + ' - ' + Item.Description;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = Location;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Visible = LocationCount <= 1;
                field(BaseUnitofMeasureNoLocation; Item."Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Unit of Measure';
                    Editable = false;
                    ToolTip = 'Specifies the unit in which the item is held in inventory. The base unit of measure also serves as the conversion basis for alternate units of measure.';
                }
                field(CurrentInventoryNoLocation; Item.Inventory)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Current Inventory';
                    Editable = false;
                    ToolTip = 'Specifies how many units, such as pieces, boxes, or cans, of the item are in inventory.';
                }
                field(NewInventoryNoLocation; TempItemJournalLine.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the inventory quantity that will be recorded for the item when you choose the OK button.';

                    trigger OnValidate()
                    begin
                        TempItemJournalLine.Modify();
                    end;
                }
            }
            repeater(Control5)
            {
                ShowCaption = false;
                Visible = LocationCount > 1;
                field("Code"; Code)
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field(Name; Name)
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field(NewInventory; TempItemJournalLine.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Inventory';
                    DecimalPlaces = 0 : 5;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the inventory quantity that will be recorded for the item when you choose the OK button.';

                    trigger OnValidate()
                    begin
                        TempItemJournalLine.Modify();
                    end;
                }
                field(BaseUnitofMeasure; Item."Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Unit of Measure';
                    Editable = false;
                    ToolTip = 'Specifies the unit in which the item is held in inventory. The base unit of measure also serves as the conversion basis for alternate units of measure.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Item.SetFilter("Location Filter", '%1', Code);
        Item.CalcFields(Inventory);
        TempItemJournalLine.SetRange("Location Code", Code);
        TempItemJournalLine.FindFirst;
    end;

    trigger OnOpenPage()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LineNo: Integer;
    begin
        GetLocationsIncludingUnspecifiedLocation(not ApplicationAreaMgmtFacade.IsLocationEnabled, true);
        SetRange("Bin Mandatory", false);
        LocationCount := Count;

        FindSet;
        repeat
            TempItemJournalLine.Init();
            Item.SetFilter("Location Filter", '%1', Code);
            Item.CalcFields(Inventory);
            TempItemJournalLine."Line No." := LineNo;
            TempItemJournalLine.Quantity := Item.Inventory;
            TempItemJournalLine."Item No." := Item."No.";
            TempItemJournalLine."Location Code" := Code;
            TempItemJournalLine.Insert();
            LineNo := LineNo + 1;
        until Next = 0;

        FindFirst;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        AdjustItemInventory: Codeunit "Adjust Item Inventory";
        ErrorText: Text;
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then begin
            TempItemJournalLine.Reset();
            ErrorText := AdjustItemInventory.PostMultipleAdjustmentsToItemLedger(TempItemJournalLine);
            if ErrorText <> '' then
                Message(ErrorText);
        end;
    end;

    var
        Item: Record Item;
        TempItemJournalLine: Record "Item Journal Line" temporary;
        LocationCount: Integer;

    procedure SetItem(ItemNo: Code[20])
    begin
        Item.Get(ItemNo);
    end;
}

