namespace Microsoft.Inventory.Availability;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Requisition;

table 99000875 "Order Promising Setup"
{
    Caption = 'Order Promising Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            Editable = false;
        }
        field(2; "Offset (Time)"; DateFormula)
        {
            Caption = 'Offset (Time)';
        }
        field(8; "Order Promising Nos."; Code[20])
        {
            Caption = 'Order Promising Nos.';
            TableRelation = "No. Series";
        }
        field(9; "Order Promising Template"; Code[10])
        {
            Caption = 'Order Promising Template';
            TableRelation = "Req. Wksh. Template";
        }
        field(10; "Order Promising Worksheet"; Code[10])
        {
            Caption = 'Order Promising Worksheet';
            TableRelation = "Requisition Wksh. Name".Name where("Worksheet Template Name" = field("Order Promising Template"));
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

