table 99000765 "Manufacturing Setup"
{
    Caption = 'Manufacturing Setup';
    LookupPageID = "Manufacturing Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            Editable = false;
        }
        field(7; "Normal Starting Time"; Time)
        {
            Caption = 'Normal Starting Time';
        }
        field(8; "Normal Ending Time"; Time)
        {
            Caption = 'Normal Ending Time';
        }
        field(9; "Doc. No. Is Prod. Order No."; Boolean)
        {
            Caption = 'Doc. No. Is Prod. Order No.';
            InitValue = true;
        }
        field(11; "Cost Incl. Setup"; Boolean)
        {
            Caption = 'Cost Incl. Setup';
        }
        field(12; "Dynamic Low-Level Code"; Boolean)
        {
            Caption = 'Dynamic Low-Level Code';
        }
        field(18; "Planning Warning"; Boolean)
        {
            Caption = 'Planning Warning';
        }
        field(20; "Simulated Order Nos."; Code[20])
        {
            Caption = 'Simulated Order Nos.';
            TableRelation = "No. Series";
        }
        field(21; "Planned Order Nos."; Code[20])
        {
            Caption = 'Planned Order Nos.';
            TableRelation = "No. Series";
        }
        field(22; "Firm Planned Order Nos."; Code[20])
        {
            Caption = 'Firm Planned Order Nos.';
            TableRelation = "No. Series";
        }
        field(23; "Released Order Nos."; Code[20])
        {
            Caption = 'Released Order Nos.';
            TableRelation = "No. Series";
        }
        field(29; "Work Center Nos."; Code[20])
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Work Center Nos.';
            TableRelation = "No. Series";
        }
        field(30; "Machine Center Nos."; Code[20])
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Machine Center Nos.';
            TableRelation = "No. Series";
        }
        field(31; "Production BOM Nos."; Code[20])
        {
            AccessByPermission = TableData "Production BOM Header" = R;
            Caption = 'Production BOM Nos.';
            TableRelation = "No. Series";
        }
        field(32; "Routing Nos."; Code[20])
        {
            AccessByPermission = TableData "Calendar Absence Entry" = R;
            Caption = 'Routing Nos.';
            TableRelation = "No. Series";
        }
        field(35; "Current Production Forecast"; Code[10])
        {
            Caption = 'Current Demand Forecast';
            TableRelation = "Production Forecast Name".Name;
        }
        field(37; "Use Forecast on Locations"; Boolean)
        {
            Caption = 'Use Forecast on Locations';
        }
        field(38; "Combined MPS/MRP Calculation"; Boolean)
        {
            AccessByPermission = TableData "Planning Component" = R;
            Caption = 'Combined MPS/MRP Calculation';
        }
        field(39; "Components at Location"; Code[10])
        {
            Caption = 'Components at Location';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(40; "Default Dampener Period"; DateFormula)
        {
            Caption = 'Default Dampener Period';

            trigger OnValidate()
            var
                CalendarMgt: Codeunit "Calendar Management";
            begin
                CalendarMgt.CheckDateFormulaPositive("Default Dampener Period");
            end;
        }
        field(41; "Default Dampener %"; Decimal)
        {
            Caption = 'Default Dampener %';
            DecimalPlaces = 1 : 1;
            MinValue = 0;
        }
        field(42; "Default Safety Lead Time"; DateFormula)
        {
            Caption = 'Default Safety Lead Time';
        }
        field(43; "Blank Overflow Level"; Option)
        {
            Caption = 'Blank Overflow Level';
            OptionCaption = 'Allow Default Calculation,Use Item/SKU Values Only';
            OptionMembers = "Allow Default Calculation","Use Item/SKU Values Only";
        }
        field(50; "Show Capacity In"; Code[10])
        {
            Caption = 'Show Capacity In';
            TableRelation = "Capacity Unit of Measure".Code;
        }
        field(5500; "Preset Output Quantity"; Option)
        {
            Caption = 'Preset Output Quantity';
            OptionCaption = 'Expected Quantity,Zero on All Operations,Zero on Last Operation';
            OptionMembers = "Expected Quantity","Zero on All Operations","Zero on Last Operation";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

