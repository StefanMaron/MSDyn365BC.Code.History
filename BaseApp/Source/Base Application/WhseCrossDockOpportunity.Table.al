table 5768 "Whse. Cross-Dock Opportunity"
{
    Caption = 'Whse. Cross-Dock Opportunity';
    DrillDownPageID = "Cross-Dock Opportunities";
    LookupPageID = "Cross-Dock Opportunities";

    fields
    {
        field(1; "Source Template Name"; Code[10])
        {
            Caption = 'Source Template Name';
            Editable = false;
        }
        field(2; "Source Name/No."; Code[20])
        {
            Caption = 'Source Name/No.';
            Editable = false;
        }
        field(3; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
            Editable = false;
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(5; "From Source Type"; Integer)
        {
            Caption = 'From Source Type';
            Editable = false;
        }
        field(6; "From Source Subtype"; Option)
        {
            Caption = 'From Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(7; "From Source No."; Code[20])
        {
            Caption = 'From Source No.';
            Editable = false;
        }
        field(8; "From Source Line No."; Integer)
        {
            Caption = 'From Source Line No.';
            Editable = false;
        }
        field(9; "From Source Subline No."; Integer)
        {
            Caption = 'From Source Subline No.';
            Editable = false;
        }
        field(10; "From Source Document"; Option)
        {
            Caption = 'From Source Document';
            Editable = false;
            OptionCaption = ',Sales Order,Sales Return Order,Purchase Order,Purchase Return Order,Inbound Transfer,Outbound Transfer,Prod. Consumption,Prod. Output,Item Ledger Entry,,,,,,,,,,,Assembly Consumption,Assembly Order';
            OptionMembers = ,"Sales Order","Sales Return Order","Purchase Order","Purchase Return Order","Inbound Transfer","Outbound Transfer","Prod. Consumption","Prod. Output","Item Ledger Entry",,,,,,,,,,,"Assembly Consumption","Assembly Order";
        }
        field(11; "To Source Type"; Integer)
        {
            Caption = 'To Source Type';
            Editable = false;
        }
        field(12; "To Source Subtype"; Option)
        {
            Caption = 'To Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(13; "To Source No."; Code[20])
        {
            Caption = 'To Source No.';
            Editable = false;
        }
        field(14; "To Source Line No."; Integer)
        {
            Caption = 'To Source Line No.';
            Editable = false;
        }
        field(15; "To Source Subline No."; Integer)
        {
            Caption = 'To Source Subline No.';
            Editable = false;
        }
        field(16; "To Source Document"; Option)
        {
            BlankZero = true;
            Caption = 'To Source Document';
            OptionCaption = ',Sales Order,,,,,,,Purchase Return Order,,Outbound Transfer,Prod. Order Comp.,,,,,,,Service Order,,Assembly Consumption,Assembly Order';
            OptionMembers = ,"Sales Order",,,,,,,"Purchase Return Order",,"Outbound Transfer","Prod. Order Comp.",,,,,,,"Service Order",,"Assembly Consumption","Assembly Order";
        }
        field(17; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            Editable = false;
            TableRelation = Item;
        }
        field(18; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(19; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(20; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(21; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location;
        }
        field(24; "Qty. Needed"; Decimal)
        {
            Caption = 'Qty. Needed';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(25; "Qty. Needed (Base)"; Decimal)
        {
            Caption = 'Qty. Needed (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(26; "Qty. to Cross-Dock"; Decimal)
        {
            Caption = 'Qty. to Cross-Dock';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Qty. to Cross-Dock (Base)" := CalcBaseQty("Qty. to Cross-Dock");
                CalcFields("Qty. Cross-Docked (Base)");
                CalcQtyOnCrossDock(NotUsed, QtyOnCrossdockAllUomBase);
                if ("Qty. Cross-Docked (Base)" + "Qty. to Cross-Dock (Base)" - xRec."Qty. to Cross-Dock (Base)") +
                   QtyOnCrossdockAllUomBase >
                   CalcQtyToHandleBase("Source Template Name", "Source Name/No.", "Source Line No.")
                then
                    Error(CrossDockQtyExceedsReceiptQtyErr);
            end;
        }
        field(27; "Qty. to Cross-Dock (Base)"; Decimal)
        {
            Caption = 'Qty. to Cross-Dock (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Cross-Dock", "Qty. to Cross-Dock (Base)");
            end;
        }
        field(28; "Qty. Cross-Docked (Base)"; Decimal)
        {
            CalcFormula = Sum ("Whse. Cross-Dock Opportunity"."Qty. to Cross-Dock (Base)" WHERE("Source Template Name" = FIELD("Source Template Name"),
                                                                                                "Source Name/No." = FIELD("Source Name/No."),
                                                                                                "Source Line No." = FIELD("Source Line No."),
                                                                                                "Location Code" = FIELD("Location Code")));
            Caption = 'Qty. Cross-Docked (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "Total Qty. Needed (Base)"; Decimal)
        {
            CalcFormula = Sum ("Whse. Cross-Dock Opportunity"."Qty. Needed (Base)" WHERE("Source Template Name" = FIELD("Source Template Name"),
                                                                                         "Source Name/No." = FIELD("Source Name/No."),
                                                                                         "Source Line No." = FIELD("Source Line No."),
                                                                                         "Location Code" = FIELD("Location Code")));
            Caption = 'Total Qty. Needed (Base)';
            FieldClass = FlowField;
        }
        field(36; "Reserved Quantity"; Decimal)
        {
            CalcFormula = - Sum ("Reservation Entry".Quantity WHERE("Source ID" = FIELD("To Source No."),
                                                                   "Source Ref. No." = FIELD("To Source Line No."),
                                                                   "Source Type" = FIELD("To Source Type"),
                                                                   "Source Subtype" = FIELD("To Source Subtype"),
                                                                   "Source Prod. Order Line" = FIELD("To Source Subline No."),
                                                                   "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(37; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = - Sum ("Reservation Entry".Quantity WHERE("Source ID" = FIELD("To Source No."),
                                                                   "Source Ref. No." = FIELD("To Source Line No."),
                                                                   "Source Type" = FIELD("To Source Type"),
                                                                   "Source Subtype" = FIELD("To Source Subtype"),
                                                                   "Source Prod. Order Line" = FIELD("To Source Subline No."),
                                                                   "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(39; "To-Src. Unit of Measure Code"; Code[10])
        {
            Caption = 'To-Src. Unit of Measure Code';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(40; "To-Src. Qty. per Unit of Meas."; Decimal)
        {
            Caption = 'To-Src. Qty. per Unit of Meas.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(41; "Due Date"; Date)
        {
            Caption = 'Due Date';
            Editable = false;
        }
        field(42; "Pick Qty."; Decimal)
        {
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = Normal;
        }
        field(43; "Pick Qty. (Base)"; Decimal)
        {
            Caption = 'Pick Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = Normal;
        }
        field(44; "Picked Qty."; Decimal)
        {
            Caption = 'Picked Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(45; "Picked Qty. (Base)"; Decimal)
        {
            Caption = 'Picked Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Source Template Name", "Source Name/No.", "Source Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Location Code")
        {
            SumIndexFields = "Qty. to Cross-Dock", "Qty. to Cross-Dock (Base)", "Qty. Needed", "Qty. Needed (Base)";
        }
        key(Key3; "From Source Type", "From Source Subtype", "From Source No.", "From Source Line No.", "From Source Subline No.")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. Needed", "Qty. Needed (Base)";
        }
        key(Key4; "To Source Type", "To Source Subtype", "To Source No.", "To Source Line No.", "To Source Subline No.")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. to Cross-Dock", "Qty. to Cross-Dock (Base)";
        }
        key(Key5; "Due Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        CrossDockQtyExceedsReceiptQtyErr: Label 'The sum of the Qty. to Cross-Dock and Qty. Cross-Docked (Base) fields must not exceed the value in the Qty. to Receive field on the warehouse receipt line.';
        UOMMgt: Codeunit "Unit of Measure Management";
        QtyOnCrossdockAllUomBase: Decimal;
        NotUsed: Decimal;

    procedure AutoFillQtyToCrossDock(var Rec: Record "Whse. Cross-Dock Opportunity")
    var
        CrossDock: Record "Whse. Cross-Dock Opportunity";
        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
        QtyOnCrossDockBase: Decimal;
        QtyToHandleBase: Decimal;
        Dummy: Decimal;
    begin
        CrossDock.CopyFilters(Rec);
        with CrossDock do
            if Find('-') then begin
                QtyToHandleBase := CalcQtyToHandleBase("Source Template Name", "Source Name/No.", "Source Line No.");

                CrossDockMgt.CalcCrossDockedItems("Item No.", "Variant Code",
                  "Unit of Measure Code", "Location Code", Dummy, QtyOnCrossDockBase);
                QtyOnCrossDockBase += CrossDockMgt.CalcCrossDockReceivedNotCrossDocked("Location Code", "Item No.", "Variant Code");

                repeat
                    CalcFields("Qty. Cross-Docked (Base)");
                    if ("Qty. Cross-Docked (Base)" + QtyOnCrossDockBase) >= QtyToHandleBase then
                        exit;
                    if "Qty. Needed (Base)" <> Rec."Qty. to Cross-Dock (Base)" then
                        if (QtyToHandleBase - "Qty. Cross-Docked (Base)" - QtyOnCrossDockBase) > "Qty. Needed (Base)" then begin
                            Validate(
                              "Qty. to Cross-Dock",
                              CalcQty("Qty. Needed (Base)", "To-Src. Qty. per Unit of Meas."));
                            Modify;
                        end else begin
                            Validate(
                              "Qty. to Cross-Dock",
                              CalcQty(QtyToHandleBase - "Qty. Cross-Docked (Base)" - QtyOnCrossDockBase, "To-Src. Qty. per Unit of Meas."));
                            Modify;
                        end;
                until Next = 0;
            end;
    end;

    local procedure CalcBaseQty(Qty: Decimal): Decimal
    begin
        TestField("To-Src. Qty. per Unit of Meas.");
        exit(Round(Qty * "To-Src. Qty. per Unit of Meas.", UOMMgt.QtyRndPrecision));
    end;

    local procedure CalcQty(QtyBase: Decimal; QtyPerUOM: Decimal): Decimal
    var
        Discriminant: Decimal;
    begin
        if QtyPerUOM = 0 then
            QtyPerUOM := 1;
        Discriminant := QtyBase mod QtyPerUOM;
        if Discriminant = 0 then
            exit(Round(QtyBase / QtyPerUOM, UOMMgt.QtyRndPrecision));
    end;

    local procedure CalcQtyToHandleBase(TemplateName: Code[10]; NameNo: Code[20]; LineNo: Integer) QtyToHandleBase: Decimal
    var
        ReceiptLine: Record "Warehouse Receipt Line";
    begin
        QtyToHandleBase := 0;
        if TemplateName = '' then begin
            ReceiptLine.Get(NameNo, LineNo);
            QtyToHandleBase := ReceiptLine."Qty. to Receive (Base)";
        end;
    end;

    local procedure CalcQtyOnCrossDock(var QtyOnCrossDockUOMBase: Decimal; var QtyOnCrossDockAllUOMBase: Decimal)
    var
        ReceiptLine: Record "Warehouse Receipt Line";
        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
    begin
        if "Source Template Name" = '' then begin
            ReceiptLine.Get("Source Name/No.", "Source Line No.");
            CrossDockMgt.CalcCrossDockedItems(ReceiptLine."Item No.", ReceiptLine."Variant Code",
              ReceiptLine."Unit of Measure Code", ReceiptLine."Location Code", QtyOnCrossDockUOMBase,
              QtyOnCrossDockAllUOMBase);
            QtyOnCrossDockAllUOMBase +=
              CrossDockMgt.CalcCrossDockReceivedNotCrossDocked(
                ReceiptLine."Location Code", ReceiptLine."Item No.", ReceiptLine."Variant Code");
        end;
    end;

    procedure ShowReservation()
    var
        SalesLine: Record "Sales Line";
        ProdComp: Record "Prod. Order Component";
        TransLine: Record "Transfer Line";
        AssemblyLine: Record "Assembly Line";
    begin
        case "To Source Type" of
            37:
                begin
                    SalesLine.Get("To Source Subtype", "To Source No.", "To Source Line No.");
                    SalesLine.ShowReservation;
                end;
            5407:
                begin
                    ProdComp.Get("To Source Subtype", "To Source No.", "To Source Subline No.", "To Source Line No.");
                    ProdComp.ShowReservation;
                end;
            5741:
                begin
                    TransLine.Get("To Source No.", "To Source Line No.");
                    TransLine.ShowReservation;
                end;
            901:
                begin
                    AssemblyLine.Get("To Source Subtype", "To Source No.", "To Source Line No.");
                    AssemblyLine.ShowReservation;
                end;
        end;
    end;
}

