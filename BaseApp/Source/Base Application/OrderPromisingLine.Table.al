table 99000880 "Order Promising Line"
{
    Caption = 'Order Promising Line';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(12; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location;
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(14; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(15; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(16; "Unavailable Quantity"; Decimal)
        {
            Caption = 'Unavailable Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(17; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Unavailable Quantity (Base)"; Decimal)
        {
            Caption = 'Unavailable Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(19; "Required Quantity (Base)"; Decimal)
        {
            Caption = 'Required Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(20; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Sales,Requisition Line,Purchase,Item Journal,BOM Journal,Item Ledger Entry,Prod. Order Line,Prod. Order Component,Planning Line,Planning Component,Transfer,Service Order,Job';
            OptionMembers = " ",Sales,"Requisition Line",Purchase,"Item Journal","BOM Journal","Item Ledger Entry","Prod. Order Line","Prod. Order Component","Planning Line","Planning Component",Transfer,"Service Order",Job;
        }
        field(21; "Source Subtype"; Integer)
        {
            Caption = 'Source Subtype';
        }
        field(22; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(23; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(25; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(30; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(31; "Required Quantity"; Decimal)
        {
            Caption = 'Required Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(40; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';

            trigger OnValidate()
            var
                SalesLine: Record "Sales Line";
                ServLine: Record "Service Line";
                JobPlanningLine: Record "Job Planning Line";
            begin
                case "Source Type" of
                    "Source Type"::Sales:
                        begin
                            SalesLine.Get("Source Subtype", "Source ID", "Source Line No.");
                            "Requested Shipment Date" := CalcReqShipDate(SalesLine);
                        end;
                    "Source Type"::"Service Order":
                        begin
                            ServLine.Get("Source Subtype", "Source ID", "Source Line No.");
                            "Requested Shipment Date" := ServLine."Needed by Date";
                        end;
                    "Source Type"::Job:
                        begin
                            JobPlanningLine.SetRange("Job No.", "Source ID");
                            JobPlanningLine.SetRange("Job Contract Entry No.", "Source Line No.");
                            JobPlanningLine.FindFirst;
                            "Requested Shipment Date" := JobPlanningLine."Planning Date";
                        end;
                end;
            end;
        }
        field(41; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';

            trigger OnValidate()
            var
                SalesLine: Record "Sales Line";
            begin
                if "Planned Delivery Date" <> 0D then
                    case "Source Type" of
                        "Source Type"::Sales:
                            begin
                                SalesLine.Get("Source Subtype", "Source ID", "Source Line No.");
                                SalesLine."Planned Delivery Date" := "Planned Delivery Date";
                                SalesLine."Planned Shipment Date" := SalesLine.CalcPlannedDate;
                                SalesLine."Shipment Date" := SalesLine.CalcShipmentDate;
                                "Planned Delivery Date" := SalesLine."Planned Delivery Date";
                                "Earliest Shipment Date" := SalesLine."Shipment Date";
                                if "Earliest Shipment Date" > "Planned Delivery Date" then
                                    "Planned Delivery Date" := "Earliest Shipment Date";
                            end;
                        "Source Type"::"Service Order", "Source Type"::Job:
                            "Earliest Shipment Date" := "Planned Delivery Date";
                    end;
            end;
        }
        field(42; "Original Shipment Date"; Date)
        {
            Caption = 'Original Shipment Date';
        }
        field(43; "Earliest Shipment Date"; Date)
        {
            Caption = 'Earliest Shipment Date';

            trigger OnValidate()
            var
                SalesLine: Record "Sales Line";
            begin
                case "Source Type" of
                    "Source Type"::Sales:
                        if "Earliest Shipment Date" <> 0D then begin
                            SalesLine.Get("Source Subtype", "Source ID", "Source Line No.");
                            SalesLine.Validate("Shipment Date", "Earliest Shipment Date");
                            "Planned Delivery Date" := SalesLine."Planned Delivery Date";
                        end;
                    "Source Type"::"Service Order":
                        if "Earliest Shipment Date" <> 0D then
                            "Planned Delivery Date" := "Earliest Shipment Date";
                    "Source Type"::Job:
                        if "Earliest Shipment Date" <> 0D then
                            "Planned Delivery Date" := "Earliest Shipment Date";
                end;
            end;
        }
        field(44; "Requested Shipment Date"; Date)
        {
            Caption = 'Requested Shipment Date';
            Editable = false;
        }
        field(45; "Unavailability Date"; Date)
        {
            Caption = 'Unavailability Date';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Requested Shipment Date")
        {
        }
    }

    fieldgroups
    {
    }

    procedure TransferFromSalesLine(var SalesLine: Record "Sales Line")
    begin
        "Source Type" := "Source Type"::Sales;
        "Source Subtype" := SalesLine."Document Type";
        "Source ID" := SalesLine."Document No.";
        "Source Line No." := SalesLine."Line No.";

        "Item No." := SalesLine."No.";
        "Variant Code" := SalesLine."Variant Code";
        "Location Code" := SalesLine."Location Code";
        Validate("Requested Delivery Date", SalesLine."Requested Delivery Date");
        "Original Shipment Date" := SalesLine."Shipment Date";
        Description := SalesLine.Description;
        Quantity := SalesLine."Outstanding Quantity";
        "Unit of Measure Code" := SalesLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
        "Quantity (Base)" := SalesLine."Outstanding Qty. (Base)";

        OnAfterTransferFromSalesLine(Rec, SalesLine);
    end;

    procedure TransferFromServLine(var ServLine: Record "Service Line")
    begin
        "Source Type" := "Source Type"::"Service Order";
        "Source Subtype" := ServLine."Document Type";
        "Source ID" := ServLine."Document No.";
        "Source Line No." := ServLine."Line No.";

        "Item No." := ServLine."No.";
        "Variant Code" := ServLine."Variant Code";
        "Location Code" := ServLine."Location Code";
        Validate("Requested Delivery Date", ServLine."Requested Delivery Date");
        "Original Shipment Date" := ServLine."Needed by Date";
        Description := ServLine.Description;
        Quantity := ServLine."Outstanding Quantity";
        "Unit of Measure Code" := ServLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := ServLine."Qty. per Unit of Measure";
        "Quantity (Base)" := ServLine."Outstanding Qty. (Base)";

        OnAfterTransferFromServLine(Rec, ServLine);
    end;

    procedure TransferFromJobPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    begin
        "Source Type" := "Source Type"::Job;
        "Source Subtype" := JobPlanningLine.Status;
        "Source ID" := JobPlanningLine."Job No.";
        "Source Line No." := JobPlanningLine."Job Contract Entry No.";

        "Item No." := JobPlanningLine."No.";
        "Variant Code" := JobPlanningLine."Variant Code";
        "Location Code" := JobPlanningLine."Location Code";
        Validate("Requested Delivery Date", JobPlanningLine."Requested Delivery Date");
        "Original Shipment Date" := JobPlanningLine."Planning Date";
        Description := JobPlanningLine.Description;
        Quantity := JobPlanningLine."Remaining Qty.";
        "Unit of Measure Code" := JobPlanningLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := JobPlanningLine."Qty. per Unit of Measure";
        "Quantity (Base)" := JobPlanningLine."Remaining Qty. (Base)";

        OnAfterTransferFromJobPlanningLine(Rec, JobPlanningLine);
    end;

    local procedure CalcReqShipDate(SalesLine: Record "Sales Line"): Date
    begin
        if (SalesLine."Requested Delivery Date" <> 0D) and
           (SalesLine."Promised Delivery Date" = 0D)
        then begin
            SalesLine.SuspendStatusCheck(true);
            SalesLine.Validate("Requested Delivery Date", SalesLine."Requested Delivery Date");
        end;
        exit(SalesLine."Shipment Date");
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure CalcAvailability(): Decimal
    var
        Item: Record Item;
        AvailableToPromise: Codeunit "Available to Promise";
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        PeriodType: Option Day,Week,Month,Quarter,Year;
        LookaheadDateformula: DateFormula;
        AvailabilityDate: Date;
    begin
        if Item.Get("Item No.") then begin
            if "Original Shipment Date" > 0D then
                AvailabilityDate := "Original Shipment Date"
            else
                AvailabilityDate := WorkDate;

            Item.Reset();
            Item.SetRange("Date Filter", 0D, AvailabilityDate);
            Item.SetRange("Variant Filter", "Variant Code");
            Item.SetRange("Location Filter", "Location Code");
            Item.SetRange("Drop Shipment Filter", false);
            exit(
              AvailableToPromise.QtyAvailabletoPromise(
                Item,
                GrossRequirement,
                ScheduledReceipt,
                AvailabilityDate,
                PeriodType,
                LookaheadDateformula));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromSalesLine(var OrderPromisingLine: Record "Order Promising Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromServLine(var OrderPromisingLine: Record "Order Promising Line"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromJobPlanningLine(var OrderPromisingLine: Record "Order Promising Line"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;
}

