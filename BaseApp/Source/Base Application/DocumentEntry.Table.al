table 265 "Document Entry"
{
    Caption = 'Document Entry';

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(2; "No. of Records"; Integer)
        {
            Caption = 'No. of Records';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            FieldClass = FlowFilter;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            FieldClass = FlowFilter;
        }
        field(5; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(6; "Table Name"; Text[100])
        {
            Caption = 'Table Name';
        }
        field(7; "No. of Records 2"; Integer)
        {
            Caption = 'No. of Records 2';
        }
        field(8; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order, ';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"," ";
        }
        field(9; "Lot No. Filter"; Code[50])
        {
            Caption = 'Lot No. Filter';
            FieldClass = FlowFilter;
        }
        field(10; "Serial No. Filter"; Code[50])
        {
            Caption = 'Serial No. Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

