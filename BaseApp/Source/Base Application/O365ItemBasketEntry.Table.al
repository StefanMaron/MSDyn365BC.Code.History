table 2101 "O365 Item Basket Entry"
{
    Caption = 'O365 Item Basket Entry';
    ReplicateData = false;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(3; Quantity; Decimal)
        {
            Caption = 'Quantity';

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(4; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DecimalPlaces = 2 : 5;

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(5; "Line Total"; Decimal)
        {
            Caption = 'Line Total';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            TableRelation = "Unit of Measure";
            ValidateTableRelation = false;
        }
        field(92; Picture; MediaSet)
        {
            Caption = 'Picture';
        }
        field(150; "Brick Text 1"; Text[30])
        {
            Caption = 'Brick Text 1';
        }
        field(151; "Brick Text 2"; Text[30])
        {
            Caption = 'Line Amount';
        }
    }

    keys
    {
        key(Key1; "Item No.")
        {
            Clustered = true;
        }
        key(Key2; Description)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; Description, "Item No.", Quantity, "Unit Price", "Brick Text 2", Picture)
        {
        }
    }

    local procedure UpdateAmounts()
    begin
        "Line Total" := Round(Quantity * "Unit Price");
        "Brick Text 2" := Format("Line Total", 0, '<Precision,2><Standard Format,0>');
    end;

    procedure CreateSalesDocument(DocumentType: Option; CustomerNo: Code[20]; var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := DocumentType;
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Insert(true);

        if not FindSet then
            exit;
        repeat
            SalesLine.Init();
            SalesLine."Document Type" := SalesHeader."Document Type";
            SalesLine."Document No." := SalesHeader."No.";
            SalesLine."Line No." += 10000;
            SalesLine.Validate(Type, SalesLine.Type::Item);
            SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
            SalesLine.Validate("No.", "Item No.");
            SalesLine.Validate(Quantity, Quantity);
            SalesLine.Insert();
        until Next = 0;
        DeleteAll(true);
    end;
}

