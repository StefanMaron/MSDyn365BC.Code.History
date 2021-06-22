table 5809 "Item Charge Assignment (Sales)"
{
    Caption = 'Item Charge Assignment (Sales)';

    fields
    {
        field(1; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Sales Header"."No." WHERE("Document Type" = FIELD("Document Type"));
        }
        field(3; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            TableRelation = "Sales Line"."Line No." WHERE("Document Type" = FIELD("Document Type"),
                                                           "Document No." = FIELD("Document No."));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Item Charge No."; Code[20])
        {
            Caption = 'Item Charge No.';
            NotBlank = true;
            TableRelation = "Item Charge";
        }
        field(6; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Qty. to Assign"; Decimal)
        {
            BlankZero = true;
            Caption = 'Qty. to Assign';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                SalesLine.Get("Document Type", "Document No.", "Document Line No.");
                SalesLine.TestField("Qty. to Invoice");
                TestField("Applies-to Doc. Line No.");
                if ("Qty. to Assign" <> 0) and ("Applies-to Doc. Type" = "Document Type") then
                    if SalesLineInvoiced then
                        Error(Text000, SalesLine.TableCaption);
                Validate("Amount to Assign");
            end;
        }
        field(9; "Qty. Assigned"; Decimal)
        {
            BlankZero = true;
            Caption = 'Qty. Assigned';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(10; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';

            trigger OnValidate()
            begin
                Validate("Amount to Assign");
            end;
        }
        field(11; "Amount to Assign"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount to Assign';

            trigger OnValidate()
            var
                ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
            begin
                SalesLine.Get("Document Type", "Document No.", "Document Line No.");
                if not Currency.Get(SalesLine."Currency Code") then
                    Currency.InitRoundingPrecision;
                "Amount to Assign" := Round("Qty. to Assign" * "Unit Cost", Currency."Amount Rounding Precision");
                ItemChargeAssgntSales.SuggestAssignmentFromLine(Rec);
            end;
        }
        field(12; "Applies-to Doc. Type"; Option)
        {
            Caption = 'Applies-to Doc. Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order,Shipment,Return Receipt';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Shipment,"Return Receipt";
        }
        field(13; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
            TableRelation = IF ("Applies-to Doc. Type" = CONST(Order)) "Sales Header"."No." WHERE("Document Type" = CONST(Order))
            ELSE
            IF ("Applies-to Doc. Type" = CONST(Invoice)) "Sales Header"."No." WHERE("Document Type" = CONST(Invoice))
            ELSE
            IF ("Applies-to Doc. Type" = CONST("Return Order")) "Sales Header"."No." WHERE("Document Type" = CONST("Return Order"))
            ELSE
            IF ("Applies-to Doc. Type" = CONST("Credit Memo")) "Sales Header"."No." WHERE("Document Type" = CONST("Credit Memo"))
            ELSE
            IF ("Applies-to Doc. Type" = CONST(Shipment)) "Sales Shipment Header"."No."
            ELSE
            IF ("Applies-to Doc. Type" = CONST("Return Receipt")) "Return Receipt Header"."No.";
        }
        field(14; "Applies-to Doc. Line No."; Integer)
        {
            Caption = 'Applies-to Doc. Line No.';
            TableRelation = IF ("Applies-to Doc. Type" = CONST(Order)) "Sales Line"."Line No." WHERE("Document Type" = CONST(Order),
                                                                                                    "Document No." = FIELD("Applies-to Doc. No."))
            ELSE
            IF ("Applies-to Doc. Type" = CONST(Invoice)) "Sales Line"."Line No." WHERE("Document Type" = CONST(Invoice),
                                                                                                                                                                                   "Document No." = FIELD("Applies-to Doc. No."))
            ELSE
            IF ("Applies-to Doc. Type" = CONST("Return Order")) "Sales Line"."Line No." WHERE("Document Type" = CONST("Return Order"),
                                                                                                                                                                                                                                                                         "Document No." = FIELD("Applies-to Doc. No."))
            ELSE
            IF ("Applies-to Doc. Type" = CONST("Credit Memo")) "Sales Line"."Line No." WHERE("Document Type" = CONST("Credit Memo"),
                                                                                                                                                                                                                                                                                                                                                              "Document No." = FIELD("Applies-to Doc. No."))
            ELSE
            IF ("Applies-to Doc. Type" = CONST(Shipment)) "Sales Shipment Line"."Line No." WHERE("Document No." = FIELD("Applies-to Doc. No."))
            ELSE
            IF ("Applies-to Doc. Type" = CONST("Return Receipt")) "Return Receipt Line"."Line No." WHERE("Document No." = FIELD("Applies-to Doc. No."));
        }
        field(15; "Applies-to Doc. Line Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Applies-to Doc. Line Amount';
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Document Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.")
        {
        }
        key(Key3; "Applies-to Doc. Type")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField("Qty. Assigned", 0);
    end;

    var
        Text000: Label 'You cannot assign item charges to the %1 because it has been invoiced. Instead you can get the posted document line and then assign the item charge to that line.';
        SalesLine: Record "Sales Line";
        Currency: Record Currency;

    procedure SalesLineInvoiced(): Boolean
    begin
        if "Applies-to Doc. Type" <> "Document Type" then
            exit(false);
        SalesLine.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        exit(SalesLine.Quantity = SalesLine."Quantity Invoiced");
    end;
}

