table 5989 "Service Shipment Item Line"
{
    Caption = 'Service Shipment Item Line';
    DrillDownPageID = "Posted Shpt. Item Line List";
    LookupPageID = "Posted Shpt. Item Line List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
            TableRelation = "Service Shipment Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            TableRelation = "Service Item";
        }
        field(4; "Service Item Group Code"; Code[10])
        {
            Caption = 'Service Item Group Code';
            TableRelation = "Service Item Group";
        }
        field(5; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(6; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(10; Priority; Option)
        {
            Caption = 'Priority';
            OptionCaption = 'Low,Medium,High';
            OptionMembers = Low,Medium,High;
        }
        field(11; "Response Time (Hours)"; Decimal)
        {
            Caption = 'Response Time (Hours)';
            DecimalPlaces = 0 : 5;
        }
        field(12; "Response Date"; Date)
        {
            Caption = 'Response Date';
        }
        field(13; "Response Time"; Time)
        {
            Caption = 'Response Time';
        }
        field(14; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            Editable = false;
        }
        field(15; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
            Editable = false;
        }
        field(16; "Finishing Date"; Date)
        {
            Caption = 'Finishing Date';
            Editable = false;
        }
        field(17; "Finishing Time"; Time)
        {
            Caption = 'Finishing Time';
            Editable = false;
        }
        field(18; "Service Shelf No."; Code[10])
        {
            Caption = 'Service Shelf No.';
            TableRelation = "Service Shelf";
        }
        field(19; "Warranty Starting Date (Parts)"; Date)
        {
            Caption = 'Warranty Starting Date (Parts)';
        }
        field(20; "Warranty Ending Date (Parts)"; Date)
        {
            Caption = 'Warranty Ending Date (Parts)';
        }
        field(21; Warranty; Boolean)
        {
            Caption = 'Warranty';
        }
        field(22; "Warranty % (Parts)"; Decimal)
        {
            Caption = 'Warranty % (Parts)';
            DecimalPlaces = 0 : 5;
        }
        field(23; "Warranty % (Labor)"; Decimal)
        {
            Caption = 'Warranty % (Labor)';
            DecimalPlaces = 0 : 5;
        }
        field(24; "Warranty Starting Date (Labor)"; Date)
        {
            Caption = 'Warranty Starting Date (Labor)';
        }
        field(25; "Warranty Ending Date (Labor)"; Date)
        {
            Caption = 'Warranty Ending Date (Labor)';
        }
        field(26; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            Editable = false;
            TableRelation = "Service Contract Header"."Contract No." WHERE("Contract Type" = CONST(Contract));
        }
        field(27; "Location of Service Item"; Text[30])
        {
            CalcFormula = Lookup ("Service Item"."Location of Service Item" WHERE("No." = FIELD("Service Item No.")));
            Caption = 'Location of Service Item';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Loaner No."; Code[20])
        {
            Caption = 'Loaner No.';
            TableRelation = Loaner;
        }
        field(29; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(30; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(31; "Fault Reason Code"; Code[10])
        {
            Caption = 'Fault Reason Code';
            TableRelation = "Fault Reason Code";
        }
        field(32; "Service Price Group Code"; Code[10])
        {
            Caption = 'Service Price Group Code';
            TableRelation = "Service Price Group";
        }
        field(33; "Fault Area Code"; Code[10])
        {
            Caption = 'Fault Area Code';
            TableRelation = "Fault Area";
        }
        field(34; "Symptom Code"; Code[10])
        {
            Caption = 'Symptom Code';
            TableRelation = "Symptom Code";
        }
        field(35; "Fault Code"; Code[10])
        {
            Caption = 'Fault Code';
            TableRelation = "Fault Code".Code WHERE("Fault Area Code" = FIELD("Fault Area Code"),
                                                     "Symptom Code" = FIELD("Symptom Code"));
        }
        field(36; "Resolution Code"; Code[10])
        {
            Caption = 'Resolution Code';
            TableRelation = "Resolution Code";
        }
        field(37; "Fault Comment"; Boolean)
        {
            CalcFormula = Exist ("Service Comment Line" WHERE("Table Name" = CONST("Service Shipment Header"),
                                                              "Table Subtype" = CONST("0"),
                                                              "No." = FIELD("No."),
                                                              Type = CONST(Fault),
                                                              "Table Line No." = FIELD("Line No.")));
            Caption = 'Fault Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(38; "Resolution Comment"; Boolean)
        {
            CalcFormula = Exist ("Service Comment Line" WHERE("Table Name" = CONST("Service Shipment Header"),
                                                              "Table Subtype" = CONST("0"),
                                                              "No." = FIELD("No."),
                                                              Type = CONST(Resolution),
                                                              "Table Line No." = FIELD("Line No.")));
            Caption = 'Resolution Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(39; "Accessory Comment"; Boolean)
        {
            CalcFormula = Exist ("Service Comment Line" WHERE("Table Name" = CONST("Service Shipment Header"),
                                                              "Table Subtype" = CONST("0"),
                                                              "No." = FIELD("No."),
                                                              Type = CONST(Accessory),
                                                              "Table Line No." = FIELD("Line No.")));
            Caption = 'Accessory Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(42; "Actual Response Time (Hours)"; Decimal)
        {
            Caption = 'Actual Response Time (Hours)';
            DecimalPlaces = 0 : 5;
        }
        field(44; "Service Price Adjmt. Gr. Code"; Code[10])
        {
            Caption = 'Service Price Adjmt. Gr. Code';
            Editable = false;
            TableRelation = "Service Price Adjustment Group";
        }
        field(45; "Adjustment Type"; Option)
        {
            Caption = 'Adjustment Type';
            Editable = false;
            OptionCaption = 'Fixed,Maximum,Minimum';
            OptionMembers = "Fixed",Maximum,Minimum;
        }
        field(46; "Base Amount to Adjust"; Decimal)
        {
            Caption = 'Base Amount to Adjust';
            Editable = false;
        }
        field(60; "No. of Active/Finished Allocs"; Integer)
        {
            CalcFormula = Count ("Service Order Allocation" WHERE("Document Type" = CONST(Order),
                                                                  "Document No." = FIELD("No."),
                                                                  "Service Item Line No." = FIELD("Line No."),
                                                                  "Resource No." = FIELD("Resource Filter"),
                                                                  "Allocation Date" = FIELD("Allocation Date Filter"),
                                                                  Status = FILTER(Active | Finished)));
            Caption = 'No. of Active/Finished Allocs';
            Editable = false;
            FieldClass = FlowField;
        }
        field(64; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            Editable = false;
            TableRelation = "Ship-to Address".Code;
        }
        field(65; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            Editable = false;
            TableRelation = Customer."No.";
        }
        field(91; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(92; "Resource Filter"; Code[20])
        {
            Caption = 'Resource Filter';
            FieldClass = FlowFilter;
            TableRelation = Resource;
        }
        field(93; "Allocation Date Filter"; Date)
        {
            Caption = 'Allocation Date Filter';
            FieldClass = FlowFilter;
        }
        field(95; "Resource Group Filter"; Code[20])
        {
            Caption = 'Resource Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "Resource Group";
        }
        field(97; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            Editable = false;
            TableRelation = "Responsibility Center";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
            end;
        }
    }

    keys
    {
        key(Key1; "No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Service Item No.")
        {
        }
        key(Key3; "Item No.", "Serial No.", "Loaner No.")
        {
        }
        key(Key4; "Service Price Group Code", "Adjustment Type", "Base Amount to Adjust", "Customer No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;

    procedure ShowComments(Type: Option General,Fault,Resolution,Accessory,Internal,"Service Item Loaner")
    var
        ServShipmentHeader: Record "Service Shipment Header";
        ServCommentLine: Record "Service Comment Line";
    begin
        ServShipmentHeader.Get("No.");
        ServShipmentHeader.TestField("Customer No.");
        TestField("Line No.");

        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Shipment Header");
        ServCommentLine.SetRange("Table Subtype", 0);
        ServCommentLine.SetRange("No.", "No.");
        case Type of
            Type::Fault:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Fault);
            Type::Resolution:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Resolution);
            Type::Accessory:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Accessory);
            Type::Internal:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Internal);
            Type::"Service Item Loaner":
                ServCommentLine.SetRange(Type, ServCommentLine.Type::"Service Item Loaner");
        end;
        ServCommentLine.SetRange("Table Line No.", "Line No.");
        PAGE.RunModal(PAGE::"Service Comment Sheet", ServCommentLine);
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID",
          StrSubstNo('%1 %2 %3', TableCaption, "No.", "Line No."));
    end;
}

