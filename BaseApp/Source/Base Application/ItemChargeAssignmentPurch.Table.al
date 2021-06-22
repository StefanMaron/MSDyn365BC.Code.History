table 5805 "Item Charge Assignment (Purch)"
{
    Caption = 'Item Charge Assignment (Purch)';

    fields
    {
        field(1; "Document Type"; Enum "Purchase Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Purchase Header"."No." WHERE("Document Type" = FIELD("Document Type"));
        }
        field(3; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            TableRelation = "Purchase Line"."Line No." WHERE("Document Type" = FIELD("Document Type"),
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
                PurchLine.Get("Document Type", "Document No.", "Document Line No.");
                PurchLine.TestField("Qty. to Invoice");

                TestField("Applies-to Doc. Line No.");
                if ("Qty. to Assign" <> 0) and ("Applies-to Doc. Type" = "Document Type") then
                    if PurchLineInvoiced then
                        Error(Text000, PurchLine.TableCaption);
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
                ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
            begin
                PurchLine.Get("Document Type", "Document No.", "Document Line No.");
                if not Currency.Get(PurchLine."Currency Code") then
                    Currency.InitRoundingPrecision;
                "Amount to Assign" := Round("Qty. to Assign" * "Unit Cost", Currency."Amount Rounding Precision");
                ItemChargeAssgntPurch.SuggestAssgntFromLine(Rec);
            end;
        }
        field(12; "Applies-to Doc. Type"; Option)
        {
            Caption = 'Applies-to Doc. Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order,Receipt,Transfer Receipt,Return Shipment,Sales Shipment,Return Receipt';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Receipt,"Transfer Receipt","Return Shipment","Sales Shipment","Return Receipt";
        }
        field(13; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
            TableRelation = IF ("Applies-to Doc. Type" = CONST(Order)) "Purchase Header"."No." WHERE("Document Type" = CONST(Order))
            ELSE
            IF ("Applies-to Doc. Type" = CONST(Invoice)) "Purchase Header"."No." WHERE("Document Type" = CONST(Invoice))
            ELSE
            IF ("Applies-to Doc. Type" = CONST("Return Order")) "Purchase Header"."No." WHERE("Document Type" = CONST("Return Order"))
            ELSE
            IF ("Applies-to Doc. Type" = CONST("Credit Memo")) "Purchase Header"."No." WHERE("Document Type" = CONST("Credit Memo"))
            ELSE
            IF ("Applies-to Doc. Type" = CONST(Receipt)) "Purch. Rcpt. Header"."No."
            ELSE
            IF ("Applies-to Doc. Type" = CONST("Return Shipment")) "Return Shipment Header"."No.";
        }
        field(14; "Applies-to Doc. Line No."; Integer)
        {
            Caption = 'Applies-to Doc. Line No.';
            TableRelation = IF ("Applies-to Doc. Type" = CONST(Order)) "Purchase Line"."Line No." WHERE("Document Type" = CONST(Order),
                                                                                                       "Document No." = FIELD("Applies-to Doc. No."))
            ELSE
            IF ("Applies-to Doc. Type" = CONST(Invoice)) "Purchase Line"."Line No." WHERE("Document Type" = CONST(Invoice),
                                                                                                                                                                                         "Document No." = FIELD("Applies-to Doc. No."))
            ELSE
            IF ("Applies-to Doc. Type" = CONST("Return Order")) "Purchase Line"."Line No." WHERE("Document Type" = CONST("Return Order"),
                                                                                                                                                                                                                                                                                  "Document No." = FIELD("Applies-to Doc. No."))
            ELSE
            IF ("Applies-to Doc. Type" = CONST("Credit Memo")) "Purchase Line"."Line No." WHERE("Document Type" = CONST("Credit Memo"),
                                                                                                                                                                                                                                                                                                                                                                          "Document No." = FIELD("Applies-to Doc. No."))
            ELSE
            IF ("Applies-to Doc. Type" = CONST(Receipt)) "Purch. Rcpt. Line"."Line No." WHERE("Document No." = FIELD("Applies-to Doc. No."))
            ELSE
            IF ("Applies-to Doc. Type" = CONST("Return Shipment")) "Return Shipment Line"."Line No." WHERE("Document No." = FIELD("Applies-to Doc. No."));
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
        PurchLine: Record "Purchase Line";
        Currency: Record Currency;

    procedure PurchLineInvoiced(): Boolean
    begin
        if "Applies-to Doc. Type" <> "Document Type" then
            exit(false);
        PurchLine.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        exit(PurchLine.Quantity = PurchLine."Quantity Invoiced");
    end;
}

