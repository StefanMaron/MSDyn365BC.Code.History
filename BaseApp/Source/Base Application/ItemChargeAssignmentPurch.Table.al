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
                    if PurchLineInvoiced() then
                        Error(CannotAssignToInvoicedErr, PurchLine.TableCaption());
                Validate("Qty. to Handle", "Qty. to Assign");
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
                GetCurrency();
                "Amount to Assign" := Round("Qty. to Assign" * "Unit Cost", Currency."Amount Rounding Precision");
                ItemChargeAssgntPurch.SuggestAssgntFromLine(Rec);
            end;
        }
        field(12; "Applies-to Doc. Type"; Enum "Purchase Applies-to Document Type")
        {
            Caption = 'Applies-to Doc. Type';
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
        field(16; "Qty. to Handle"; Decimal)
        {
            BlankZero = true;
            Caption = 'Qty. to Handle';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Qty. to Handle" <> 0 then
                    TestField("Qty. to Handle", "Qty. to Assign");
                Validate("Amount to Handle");
            end;
        }
        field(17; "Amount to Handle"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount to Handle';

            trigger OnValidate()
            begin
                GetCurrency();
                "Amount to Handle" := Round("Qty. to Handle" * "Unit Cost", Currency."Amount Rounding Precision");
            end;
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
        Validate("Qty. to Assign", 0);
    end;

    var
        PurchLine: Record "Purchase Line";
        Currency: Record Currency;
        CannotAssignToInvoicedErr: Label 'You cannot assign item charges to the %1 because it has been invoiced. Instead you can get the posted document line and then assign the item charge to that line.';
        ItemChargeDeletionErr: Label 'You cannot delete posted documents that are applied as item charges to purchase lines. This document applied to %1 %2 %3.', Comment = '%1 - Document Type; %2 - Document No., %3 - Item No.';

    local procedure GetCurrency()
    begin
        PurchLine.Get("Document Type", "Document No.", "Document Line No.");
        if not Currency.Get(PurchLine."Currency Code") then
            Currency.InitRoundingPrecision;
    end;

    procedure PurchLineInvoiced(): Boolean
    begin
        if "Applies-to Doc. Type" <> "Document Type" then
            exit(false);
        PurchLine.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        exit(PurchLine.Quantity = PurchLine."Quantity Invoiced");
    end;

    procedure CheckAssignment(AppliesToDocumentType: Enum "Purchase Applies-to Document Type"; AppliesToDocumentNo: Code[20]; AppliesToDocumentLineNo: Integer)
    begin
        Reset();
        SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        SetRange("Applies-to Doc. Type", AppliesToDocumentType);
        SetRange("Applies-to Doc. No.", AppliesToDocumentNo);
        SetRange("Applies-to Doc. Line No.", AppliesToDocumentLineNo);
        if FindFirst() then
            error(ItemChargeDeletionErr, "Document Type", "Document No.", "Item No.");
    end;
}

