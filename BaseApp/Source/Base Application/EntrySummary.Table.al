table 338 "Entry Summary"
{
    Caption = 'Entry Summary';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(3; "Summary Type"; Text[80])
        {
            Caption = 'Summary Type';
        }
        field(4; "Total Quantity"; Decimal)
        {
            Caption = 'Total Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(5; "Total Reserved Quantity"; Decimal)
        {
            Caption = 'Total Reserved Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(6; "Total Available Quantity"; Decimal)
        {
            Caption = 'Total Available Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(7; "Current Reserved Quantity"; Decimal)
        {
            Caption = 'Current Reserved Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(8; "Source Subtype"; Integer)
        {
            Caption = 'Source Subtype';
        }
        field(15; "Qty. Alloc. in Warehouse"; Decimal)
        {
            Caption = 'Qty. Alloc. in Warehouse';
            DecimalPlaces = 0 : 5;
        }
        field(16; "Res. Qty. on Picks & Shipmts."; Decimal)
        {
            Caption = 'Res. Qty. on Picks & Shipmts.';
            DecimalPlaces = 0 : 5;
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            Editable = false;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            Editable = false;
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
            Editable = false;
        }
        field(6503; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            Editable = false;
        }
        field(6504; "Total Requested Quantity"; Decimal)
        {
            Caption = 'Total Requested Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(6505; "Selected Quantity"; Decimal)
        {
            BlankZero = true;
            Caption = 'Selected Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Bin Active" and ("Total Available Quantity" > "Bin Content") then begin
                    if "Selected Quantity" > "Bin Content" then
                        Error(Text001, "Bin Content");
                end else
                    if "Selected Quantity" > "Total Available Quantity" then
                        Error(Text001, "Total Available Quantity");
            end;
        }
        field(6506; "Current Pending Quantity"; Decimal)
        {
            Caption = 'Current Pending Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(6507; "Current Requested Quantity"; Decimal)
        {
            Caption = 'Current Requested Quantity';
        }
        field(6508; "Bin Content"; Decimal)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Bin Content';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(6509; "Bin Active"; Boolean)
        {
            Caption = 'Bin Active';
            Editable = false;
        }
        field(6510; "Non-specific Reserved Qty."; Decimal)
        {
            Caption = 'Non-specific Reserved Qty.';
            Editable = false;
        }
        field(6511; "Double-entry Adjustment"; Decimal)
        {
            Caption = 'Double-entry Adjustment';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Lot No.", "Serial No.")
        {
        }
        key(Key3; "Expiration Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label 'You cannot select more than %1 units.';

    procedure UpdateAvailable()
    begin
        "Total Available Quantity" :=
          "Total Quantity" -
          "Total Requested Quantity" -
          "Current Pending Quantity" +
          "Double-entry Adjustment";
    end;

    procedure HasQuantity(): Boolean
    begin
        exit(("Total Quantity" <> 0) or
          ("Qty. Alloc. in Warehouse" <> 0) or
          ("Total Requested Quantity" <> 0) or
          ("Current Pending Quantity" <> 0) or
          ("Double-entry Adjustment" <> 0));
    end;

    procedure SetTrackingFilter(SerialNo: Code[50]; LotNo: Code[50])
    begin
        SetRange("Serial No.", SerialNo);
        SetRange("Lot No.", LotNo);
    end;

    procedure SetTrackingFilterFromEntrySummary(EntrySummary: Record "Entry Summary")
    begin
        SetRange("Serial No.", EntrySummary."Serial No.");
        SetRange("Lot No.", EntrySummary."Lot No.");
    end;

    procedure SetTrackingFilterFromReservEntry(ReservationEntry: Record "Reservation Entry")
    begin
        SetRange("Serial No.", ReservationEntry."Serial No.");
        SetRange("Lot No.", ReservationEntry."Lot No.");
    end;

    procedure SetTrackingFilterFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        SetRange("Serial No.", TrackingSpecification."Serial No.");
        SetRange("Lot No.", TrackingSpecification."Lot No.");
    end;
}

