report 7314 "Whse. Change Unit of Measure"
{
    Caption = 'Whse. Change Unit of Measure';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        InsertAllowed = false;
        SourceTable = "Warehouse Activity Line";

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Action Type"; "Action Type")
                    {
                        ApplicationArea = Warehouse;
                        Editable = false;
                        ToolTip = 'Specifies if you want to change the unit of measure on a Take line or on a Place line.';
                    }
                    field("Qty. to Handle"; "Qty. to Handle")
                    {
                        ApplicationArea = Warehouse;
                        Editable = false;
                        ToolTip = 'Specifies how many units to handle in this warehouse activity.';
                    }
                    group(From)
                    {
                        Caption = 'From';
                        field("Unit of Measure Code"; "Unit of Measure Code")
                        {
                            ApplicationArea = Warehouse;
                            Editable = false;
                            ToolTip = 'Specifies for a warehouse activity line, such as a warehouse pick, which unit of measure you want.';
                        }
                    }
                    group("To")
                    {
                        Caption = 'To';
                        field(UnitOfMeasureCode; UOMCode)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Unit of Measure Code';
                            TableRelation = "Item Unit of Measure".Code;
                            ToolTip = 'Specifies the unit of measure for a warehouse activity line.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                ItemUOM.Reset();
                                ItemUOM.FilterGroup(2);
                                ItemUOM.SetRange("Item No.", "Item No.");
                                ItemUOM.FilterGroup(0);
                                ItemUOM.Code := WarehouseActivityLine."Unit of Measure Code";
                                if PAGE.RunModal(0, ItemUOM) = ACTION::LookupOK then begin
                                    Text := ItemUOM.Code;
                                    exit(true);
                                end;
                            end;

                            trigger OnValidate()
                            begin
                                ItemUOM.Get("Item No.", UOMCode);
                                WarehouseActivityLine."Qty. per Unit of Measure" := ItemUOM."Qty. per Unit of Measure";
                                WarehouseActivityLine."Unit of Measure Code" := ItemUOM.Code;
                                CheckUOM;
                                UOMCode := ItemUOM.Code;
                            end;
                        }
                    }
                    field("WarehouseActivityLine.Quantity"; WarehouseActivityLine.Quantity)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Quantity';
                        DecimalPlaces = 0 : 5;
                        Editable = false;
                        ToolTip = 'Specifies the quantity that corresponds to the warehouse activity line.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnAfterGetRecord()
        begin
            UOMCode := "Unit of Measure Code";
            WarehouseActivityLine.Quantity := "Qty. to Handle";
            WarehouseActivityLine."Qty. (Base)" := "Qty. to Handle (Base)";
        end;

        trigger OnOpenPage()
        begin
            Copy(WarehouseActivityLine);
            Get("Activity Type", "No.", "Line No.");
            SetRecFilter;
            TestField("Bin Code");
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if CloseAction = ACTION::OK then
                if UOMCode <> "Unit of Measure Code" then
                    ChangeUOM2 := true;
        end;
    }

    labels
    {
    }

    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        BinContent: Record "Bin Content";
        ItemUOM: Record "Item Unit of Measure";
        UOMCode: Code[10];
        QtyAvailBase: Decimal;
        QtyChangeBase: Decimal;
        ChangeUOM2: Boolean;
        Text001: Label 'The %1 %2 exceeds the Quantity available to pick %3 of the %4.';

    procedure DefWhseActLine(WhseActLine2: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine.Copy(WhseActLine2);
    end;

    local procedure CheckUOM()
    begin
        Clear(BinContent);
        QtyChangeBase := 0;
        QtyAvailBase := 0;
        if "Serial No." <> '' then
            WarehouseActivityLine.TestField("Qty. per Unit of Measure", 1);
        BinContent."Qty. per Unit of Measure" := WarehouseActivityLine."Qty. per Unit of Measure";

        QtyChangeBase := "Qty. to Handle (Base)";
        if "Action Type" = "Action Type"::Take then begin
            if BinContent.Get(
                 "Location Code", "Bin Code", "Item No.",
                 "Variant Code", WarehouseActivityLine."Unit of Measure Code")
            then begin
                QtyChangeBase := "Qty. to Handle (Base)";
                if "Activity Type" in ["Activity Type"::Pick, "Activity Type"::"Invt. Pick", "Activity Type"::"Invt. Movement"] then
                    QtyAvailBase := BinContent.CalcQtyAvailToPick(0)
                else
                    QtyAvailBase := BinContent.CalcQtyAvailToTake(0);
                if QtyAvailBase < QtyChangeBase then
                    Error(Text001, FieldCaption("Qty. (Base)"), QtyChangeBase, BinContent.TableCaption, FieldCaption("Bin Code"))
            end else
                Error(Text001, FieldCaption("Qty. (Base)"), QtyChangeBase, BinContent.TableCaption, FieldCaption("Bin Code"));
        end;

        if BinContent."Qty. per Unit of Measure" = WarehouseActivityLine."Qty. per Unit of Measure" then begin
            WarehouseActivityLine.Validate(Quantity, "Qty. to Handle (Base)" / WarehouseActivityLine."Qty. per Unit of Measure");
            WarehouseActivityLine.Validate("Unit of Measure Code");
        end else begin
            WarehouseActivityLine.Validate("Unit of Measure Code");
            WarehouseActivityLine."Qty. per Unit of Measure" := BinContent."Qty. per Unit of Measure";
            WarehouseActivityLine.Validate(Quantity, "Qty. to Handle (Base)" / BinContent."Qty. per Unit of Measure");
            WarehouseActivityLine.Validate("Qty. Outstanding");
            WarehouseActivityLine.Validate("Qty. to Handle");
        end;
    end;

    procedure ChangeUOMCode(var WhseActLine: Record "Warehouse Activity Line") ChangeUOM: Boolean
    begin
        WhseActLine := WarehouseActivityLine;
        ChangeUOM := ChangeUOM2;
    end;
}

