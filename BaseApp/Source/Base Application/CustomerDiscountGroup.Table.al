table 340 "Customer Discount Group"
{
    Caption = 'Customer Discount Group';
    LookupPageID = "Customer Disc. Groups";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code", Description)
        {
        }
    }

    trigger OnDelete()
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        SalesLineDiscount.SetCurrentKey("Sales Type", "Sales Code");
        SalesLineDiscount.SetRange("Sales Type", SalesLineDiscount."Sales Type"::"Customer Disc. Group");
        SalesLineDiscount.SetRange("Sales Code", Code);
        SalesLineDiscount.DeleteAll(true);
    end;
}

