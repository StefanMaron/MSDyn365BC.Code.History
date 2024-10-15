namespace Microsoft.Inventory.Tracking;

table 99000854 "Inventory Profile Track Buffer"
{
    Caption = 'Inventory Profile Track Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(2; Priority; Integer)
        {
            Caption = 'Priority';
            DataClassification = SystemMetadata;
        }
        field(3; "Demand Line No."; Integer)
        {
            Caption = 'Demand Line No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
            DataClassification = SystemMetadata;
        }
        field(21; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
        }
        field(23; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
            DataClassification = SystemMetadata;
        }
        field(72; "Quantity Tracked"; Decimal)
        {
            Caption = 'Quantity Tracked';
            DataClassification = SystemMetadata;
        }
        field(73; "Surplus Type"; Option)
        {
            Caption = 'Surplus Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'None,Forecast,BlanketOrder,SafetyStock,ReorderPoint,MaxInventory,FixedOrderQty,MaxOrder,MinOrder,OrderMultiple,DampenerQty,PlanningFlexibility,Undefined,EmergencyOrder';
            OptionMembers = "None",Forecast,BlanketOrder,SafetyStock,ReorderPoint,MaxInventory,FixedOrderQty,MaxOrder,MinOrder,OrderMultiple,DampenerQty,PlanningFlexibility,Undefined,EmergencyOrder;
        }
        field(75; "Warning Level"; Option)
        {
            Caption = 'Warning Level';
            DataClassification = SystemMetadata;
            OptionCaption = ',Emergency,Exception,Attention';
            OptionMembers = ,Emergency,Exception,Attention;
        }
    }

    keys
    {
        key(Key1; "Line No.", Priority, "Demand Line No.", "Sequence No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

