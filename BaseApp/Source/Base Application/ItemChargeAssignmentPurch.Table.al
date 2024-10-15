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
        field(31060; "Incl. in Intrastat Amount"; Boolean)
        {
            Caption = 'Incl. in Intrastat Amount';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
#if not CLEAN18

            trigger OnValidate()
            begin
                CheckIncludeIntrastat;
            end;
#endif
        }
        field(31061; "Incl. in Intrastat Stat. Value"; Boolean)
        {
            Caption = 'Incl. in Intrastat Stat. Value';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
#if not CLEAN18

            trigger OnValidate()
            begin
                CheckIncludeIntrastat;
            end;
#endif
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
        ItemChargeDeletionErr: Label 'You cannot delete posted documents that are applied as item charges to purchase lines. This document applied to %1 %2 %3.', Comment = '%1 - Document Type; %2 - Document No., %3 - Item No.';

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

#if not CLEAN19

    [Scope('OnPrem')]
    [Obsolete('Moved to Core Localization Pack for Czech.', '19.0')]
    procedure SetIncludeAmount(): Boolean
    var
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        if PurchHeader.Get("Document Type", "Document No.") then begin
            VendorNo := GetVendor;

            if (VendorNo <> '') and (PurchHeader."Buy-from Vendor No." = VendorNo) then
                exit(true);
        end;

        exit(false);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '19.0')]
    local procedure GetVendor(): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReturnShptHeader: Record "Return Shipment Header";
        VendorNo: Code[20];
    begin
        case "Applies-to Doc. Type" of
            "Applies-to Doc. Type"::Order, "Applies-to Doc. Type"::Invoice,
            "Applies-to Doc. Type"::"Return Order", "Applies-to Doc. Type"::"Credit Memo":
                begin
                    PurchHeader.Get("Applies-to Doc. Type", "Applies-to Doc. No.");
                    VendorNo := PurchHeader."Buy-from Vendor No.";
                end;
            "Applies-to Doc. Type"::Receipt:
                begin
                    PurchRcptHeader.Get("Applies-to Doc. No.");
                    VendorNo := PurchRcptHeader."Buy-from Vendor No.";
                end;
            "Applies-to Doc. Type"::"Return Shipment":
                begin
                    ReturnShptHeader.Get("Applies-to Doc. No.");
                    VendorNo := ReturnShptHeader."Buy-from Vendor No.";
                end;
            "Applies-to Doc. Type"::"Transfer Receipt":
                VendorNo := '';
            "Applies-to Doc. Type"::"Sales Shipment":
                VendorNo := '';
            "Applies-to Doc. Type"::"Return Receipt":
                VendorNo := '';
        end;

        exit(VendorNo);
    end;
#endif
#if not CLEAN18

    [Scope('OnPrem')]
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    procedure CheckIncludeIntrastat()
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
    begin
        // NAVCZ
        StatReportingSetup.Get();
        StatReportingSetup.TestField("No Item Charges in Intrastat", false);
    end;
#endif
}

