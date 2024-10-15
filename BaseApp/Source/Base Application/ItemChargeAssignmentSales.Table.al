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
        field(12; "Applies-to Doc. Type"; Enum "Sales Applies-to Document Type")
        {
            Caption = 'Applies-to Doc. Type';
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
        Validate("Qty. to Assign", 0);
    end;

    var
        Text000: Label 'You cannot assign item charges to the %1 because it has been invoiced. Instead you can get the posted document line and then assign the item charge to that line.';
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
        ItemChargeDeletionErr: Label 'You cannot delete posted documents that are applied as item charges to sales lines. This document applied to item %3 in %1 %2.', Comment = '%1 - Document Type; %2 - Document No., %3 - Item No.';

    procedure SalesLineInvoiced(): Boolean
    begin
        if "Applies-to Doc. Type" <> "Document Type" then
            exit(false);
        SalesLine.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        exit(SalesLine.Quantity = SalesLine."Quantity Invoiced");
    end;

    procedure CheckAssignment(AppliesToDocumentType: Enum "Sales Applies-to Document Type"; AppliesToDocumentNo: Code[20]; AppliesToDocumentLineNo: Integer)
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
    [Obsolete('Unused function discontinued.', '19.0')]
    procedure SetIncludeAmount(): Boolean
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // NAVCZ
        if SalesHeader.Get("Document Type", "Document No.") then begin
            CustomerNo := GetCustomer;

            if (CustomerNo <> '') and (SalesHeader."Sell-to Customer No." = CustomerNo) then
                exit(true);
        end;

        exit(false);
    end;

    local procedure GetCustomer(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        SalesShptHeader: Record "Sales Shipment Header";
        CustomerNo: Code[20];
    begin
        // NAVCZ
        case "Applies-to Doc. Type" of
            "Applies-to Doc. Type"::Order, "Applies-to Doc. Type"::Invoice,
            "Applies-to Doc. Type"::"Return Order", "Applies-to Doc. Type"::"Credit Memo":
                begin
                    SalesHeader.Get("Applies-to Doc. Type", "Applies-to Doc. No.");
                    CustomerNo := SalesHeader."Sell-to Customer No.";
                end;
            "Applies-to Doc. Type"::Shipment:
                begin
                    SalesShptHeader.Get("Applies-to Doc. No.");
                    CustomerNo := SalesShptHeader."Sell-to Customer No.";
                end;
            "Applies-to Doc. Type"::"Return Receipt":
                begin
                    ReturnRcptHeader.Get("Applies-to Doc. No.");
                    CustomerNo := ReturnRcptHeader."Sell-to Customer No.";
                end;
        end;

        exit(CustomerNo);
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

