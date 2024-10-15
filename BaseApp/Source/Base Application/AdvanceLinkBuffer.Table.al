table 31018 "Advance Link Buffer"
{
    Caption = 'Advance Link Buffer';
#if not CLEAN19
    ObsoleteState = Pending;
#else
    ObsoleteState = Removed;
#endif
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    fields
    {
        field(1; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Payment,Letter Line';
            OptionMembers = " ",Payment,"Letter Line";
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
#if not CLEAN19
            TableRelation = IF ("Entry Type" = CONST("Letter Line")) "Sales Advance Letter Line"."Line No." WHERE("Letter No." = FIELD("Document No."))
            ELSE
            IF ("Entry Type" = CONST(Payment),
                                     Type = CONST(Customer)) "Cust. Ledger Entry"."Entry No."
            ELSE
            IF ("Entry Type" = CONST(Payment),
                                              Type = CONST(Vendor)) "Vendor Ledger Entry"."Entry No.";
#endif
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            Editable = false;
            OptionCaption = 'G/L Account,Customer,Vendor';
            OptionMembers = "G/L Account",Customer,Vendor;
        }
        field(5; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = IF (Type = CONST("G/L Account")) "G/L Account"."No."
            ELSE
            IF (Type = CONST(Customer)) Customer."No."
            ELSE
            IF (Type = CONST(Vendor)) Vendor."No.";
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(7; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8; "Amount To Link"; Decimal)
        {
            Caption = 'Amount To Link';
            DataClassification = SystemMetadata;
#if not CLEAN19

            trigger OnValidate()
            begin
                if "Amount To Link" * "Remaining Amount" < 0 then
                    FieldError("Amount To Link", StrSubstNo(Text000Err, FieldCaption("Remaining Amount")));

                if Abs("Amount To Link") > Abs("Remaining Amount") then
                    FieldError("Amount To Link", StrSubstNo(Text001Err, FieldCaption("Remaining Amount")));
            end;
#endif
        }
        field(9; "Due Date"; Date)
        {
            Caption = 'Due Date';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(10; "Links-To ID"; Code[50])
        {
            Caption = 'Links-To ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(11; "Linking Entry"; Boolean)
        {
            Caption = 'Linking Entry';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(12; "CV No."; Code[20])
        {
            Caption = 'CV No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(14; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
        field(15; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(20; "Source Type"; Option)
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
            Editable = false;
            OptionCaption = 'G/L Account,Customer,Vendor';
            OptionMembers = "G/L Account",Customer,Vendor;
        }
        field(21; "Link Code"; Code[30])
        {
            Caption = 'Link Code';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry Type", "Document No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Links-To ID", "Linking Entry")
        {
            SumIndexFields = "Amount To Link";
        }
        key(Key3; "Link Code", "Linking Entry")
        {
            SumIndexFields = "Amount To Link";
        }
    }

    fieldgroups
    {
    }
#if not CLEAN19

    var
        Text000Err: Label 'must have the same sign as %1';
        Text001Err: Label 'must not be larger than %1';

    [Scope('OnPrem')]
    procedure ShowDimensions()
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if "Entry Type" = "Entry Type"::Payment then
            if Type = Type::"G/L Account" then
                case "Source Type" of
                    "Source Type"::Customer:
                        begin
                            if CustLedgEntry.Get("Entry No.") then
                                CustLedgEntry.ShowDimensions();
                        end;
                    "Source Type"::Vendor:
                        begin
                            if VendLedgEntry.Get("Entry No.") then
                                VendLedgEntry.ShowDimensions();
                        end;
                end
            else
                case Type of
                    Type::Customer:
                        if CustLedgEntry.Get("Entry No.") then
                            CustLedgEntry.ShowDimensions();
                    Type::Vendor:
                        if VendLedgEntry.Get("Entry No.") then
                            VendLedgEntry.ShowDimensions();
                end
        else
            if Type = Type::"G/L Account" then
                case "Source Type" of
                    "Source Type"::Customer:
                        begin
                            SalesAdvanceLetterLine.Get("Document No.", "Entry No.");
                            SalesAdvanceLetterLine.ShowDimensions();
                        end;
                    "Source Type"::Vendor:
                        begin
                            PurchAdvanceLetterLine.Get("Document No.", "Entry No.");
                            PurchAdvanceLetterLine.ShowDimensions();
                        end;
                end
            else
                case Type of
                    Type::Customer:
                        begin
                            SalesAdvanceLetterLine.Get("Document No.", "Entry No.");
                            SalesAdvanceLetterLine.ShowDimensions();
                        end;
                    Type::Vendor:
                        begin
                            PurchAdvanceLetterLine.Get("Document No.", "Entry No.");
                            PurchAdvanceLetterLine.ShowDimensions();
                        end;
                end;
    end;

    [Scope('OnPrem')]
    procedure ShowLinkedEntries()
    var
        AdvanceLink: Record "Advance Link";
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        SalesPostAdvances: Codeunit "Sales-Post Advances";
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
        LinkedPrepayments: Page "Linked Prepayments";
    begin
        if "Entry Type" = "Entry Type"::Payment then begin
            AdvanceLink.FilterGroup(0);
            AdvanceLink.SetCurrentKey("CV Ledger Entry No.");
            AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
            AdvanceLink.SetRange("CV Ledger Entry No.", "Entry No.");
            AdvanceLink.FilterGroup(2);
            PAGE.Run(PAGE::"Links to Advance Letter", AdvanceLink);
        end else begin
            if Type = Type::"G/L Account" then
                case "Source Type" of
                    "Source Type"::Customer:
                        begin
                            SalesAdvanceLetterLine.Get("Document No.", "Entry No.");
                            SalesPostAdvances.CalcLinkedAmount(SalesAdvanceLetterLine, TempCustLedgEntry);
                            LinkedPrepayments.InsertCustEntries(TempCustLedgEntry);
                        end;
                    "Source Type"::Vendor:
                        begin
                            PurchAdvanceLetterLine.Get("Document No.", "Entry No.");
                            PurchPostAdvances.CalcLinkedAmount(PurchAdvanceLetterLine, TempVendLedgEntry);
                            LinkedPrepayments.InsertVendEntries(TempVendLedgEntry);
                        end;
                end
            else
                if Type = Type::Customer then begin
                    SalesAdvanceLetterLine.Get("Document No.", "Entry No.");
                    SalesPostAdvances.CalcLinkedAmount(SalesAdvanceLetterLine, TempCustLedgEntry);
                    LinkedPrepayments.InsertCustEntries(TempCustLedgEntry);
                end else begin
                    PurchAdvanceLetterLine.Get("Document No.", "Entry No.");
                    PurchPostAdvances.CalcLinkedAmount(PurchAdvanceLetterLine, TempVendLedgEntry);
                    LinkedPrepayments.InsertVendEntries(TempVendLedgEntry);
                end;
            LinkedPrepayments.Run;
        end;
    end;
#endif
}

