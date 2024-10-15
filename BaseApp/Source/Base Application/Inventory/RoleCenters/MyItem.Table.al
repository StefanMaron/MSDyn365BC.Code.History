namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Ledger;
using System.Security.AccessControl;

table 9152 "My Item"
{
    Caption = 'My Item';

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;

            trigger OnValidate()
            begin
                SetItemFields();
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(4; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            Editable = false;
        }
        field(5; Inventory; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("Item No.")));
            Caption = 'Inventory';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "User ID", "Item No.")
        {
            Clustered = true;
        }
        key(Key2; Description)
        {
        }
        key(Key3; "Unit Price")
        {
        }
    }

    fieldgroups
    {
    }

    local procedure SetItemFields()
    var
        Item: Record Item;
    begin
        if Item.Get("Item No.") then begin
            Description := Item.Description;
            "Unit Price" := Item."Unit Price";
        end;
    end;
}

