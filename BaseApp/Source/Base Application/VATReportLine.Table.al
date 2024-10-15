table 741 "VAT Report Line"
{
    Caption = 'VAT Report Line';

    fields
    {
        field(1; "VAT Report No."; Code[20])
        {
            Caption = 'VAT Report No.';
            Editable = false;
            TableRelation = "VAT Report Header"."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(3; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            Editable = false;
            TableRelation = "Gen. Product Posting Group";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        field(7; Type; Option)
        {
            Caption = 'Type';
            Editable = false;
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;
        }
        field(8; Base; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base';

            trigger OnValidate()
            begin
                TestStatusOpen;
                CheckLineType;

                Base := RoundBase(Base);
            end;
        }
        field(9; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                TestStatusOpen;
                CheckLineType;

                Amount := RoundBase(Amount);
            end;
        }
        field(10; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(12; "Bill-to/Pay-to No."; Code[20])
        {
            Caption = 'Bill-to/Pay-to No.';
            Editable = false;
            TableRelation = IF (Type = CONST(Purchase)) Vendor
            ELSE
            IF (Type = CONST(Sale)) Customer;
        }
        field(13; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            Editable = false;
        }
        field(15; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(16; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            Editable = false;
            TableRelation = "Reason Code";
        }
        field(17; "EU Service"; Boolean)
        {
            Caption = 'EU Service';
            Editable = false;
        }
        field(19; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            Editable = false;
            TableRelation = "Country/Region";
        }
        field(20; "Internal Ref. No."; Text[30])
        {
            Caption = 'Internal Ref. No.';
            Editable = false;
        }
        field(22; "Unrealized Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unrealized Amount';
            Editable = false;
        }
        field(23; "Unrealized Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unrealized Base';
            Editable = false;
        }
        field(24; "Number of Supplies"; Decimal)
        {
            BlankNumbers = DontBlank;
            Caption = 'Number of Supplies';
            DecimalPlaces = 0 : 0;
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen;
                CheckLineType;
            end;
        }
        field(26; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            Editable = false;
        }
        field(30; "Trade Type"; Option)
        {
            Caption = 'Trade Type';
            Editable = false;
            OptionCaption = 'Purchase,Sale';
            OptionMembers = Purchase,Sale;

            trigger OnValidate()
            begin
                TestStatusOpen;
                CheckLineType;
            end;
        }
        field(31; "Line Type"; Option)
        {
            Caption = 'Line Type';
            Editable = false;
            OptionCaption = 'New,Cancellation,Correction';
            OptionMembers = New,Cancellation,Correction;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(32; "Related Line No."; Integer)
        {
            Caption = 'Related Line No.';
            Editable = false;
        }
        field(33; "Trade Role Type"; Option)
        {
            Caption = 'Trade Role Type';
            Editable = false;
            OptionCaption = 'Direct Trade,Intermediate Trade,Property Movement';
            OptionMembers = "Direct Trade","Intermediate Trade","Property Movement";

            trigger OnValidate()
            begin
                TestStatusOpen;
                CheckLineType;
            end;
        }
        field(39; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            Editable = false;
            TableRelation = "VAT Business Posting Group";
        }
        field(40; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            Editable = false;
            TableRelation = "VAT Product Posting Group";
        }
        field(50; "Corrected Reg. No."; Boolean)
        {
            Caption = 'Corrected Reg. No.';
            Editable = false;
        }
        field(51; "Corrected Amount"; Boolean)
        {
            Caption = 'Corrected Amount';
            Editable = false;
        }
        field(54; "Registration No."; Text[20])
        {
            Caption = 'Registration No.';
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen;
                CheckLineType;
            end;
        }
        field(55; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            Editable = false;
        }
        field(56; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            Editable = false;
            TableRelation = "Gen. Business Posting Group";
        }
        field(99; "System-Created"; Boolean)
        {
            Caption = 'System-Created';
            Editable = false;
        }
        field(100; "Record Identifier"; Code[30])
        {
            Caption = 'Record Identifier';
            Editable = false;
        }
        field(101; "VAT Report to Correct"; Code[20])
        {
            Caption = 'VAT Report to Correct';
        }
        field(102; "Able to Correct Line"; Boolean)
        {
            Caption = 'Able to Correct Line';
        }
    }

    keys
    {
        key(Key1; "VAT Report No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Trade Type", "Country/Region Code", "VAT Registration No.", "Registration No.", "EU 3-Party Trade")
        {
        }
        key(Key3; "VAT Report to Correct", "Able to Correct Line")
        {
        }
        key(Key4; "VAT Report No.", "Line Type")
        {
            SumIndexFields = Base, Amount, "Number of Supplies";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        CheckEditingAllowed;

        VATReportLineRelation.Reset();
        VATReportLineRelation.SetRange("VAT Report No.", "VAT Report No.");
        VATReportLineRelation.SetRange("VAT Report Line No.", "Line No.");
        VATReportLineRelation.DeleteAll();
    end;

    trigger OnInsert()
    begin
        VATReportHeader.Get("VAT Report No.");
        if VATReportHeader."Original Report No." = '' then
            Validate("VAT Report to Correct", VATReportHeader."No.")
        else
            Validate("VAT Report to Correct", VATReportHeader."Original Report No.");
    end;

    trigger OnModify()
    begin
        CheckEditingAllowed;
    end;

    var
        VATReportHeader: Record "VAT Report Header";
        LineCannotBeEditedErr: Label 'Cancellation line cannot be changed.';
        CorrectionEntryExistsErr: Label 'A correction entry already exists for this entry in report %1.';

    local procedure TestStatusOpen()
    begin
        VATReportHeader.Get("VAT Report No.");
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
    end;

    [Scope('OnPrem')]
    procedure GetTradeRole(): Code[10]
    begin
        case "Trade Role Type" of
            "Trade Role Type"::"Direct Trade":
                case "Trade Type" of
                    "Trade Type"::Sale:
                        exit('0');
                    "Trade Type"::Purchase:
                        exit('0');
                end;
            "Trade Role Type"::"Property Movement":
                exit('1');
            "Trade Role Type"::"Intermediate Trade":
                exit('2');
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCancelCode(): Code[10]
    begin
        if "Line Type" = "Line Type"::Cancellation then
            exit('1');

        exit('0');
    end;

    [Scope('OnPrem')]
    procedure GetNextLineNo(VATReportNo: Code[20]): Integer
    var
        VATReportLine2: Record "VAT Report Line";
    begin
        VATReportLine2.SetRange("VAT Report No.", VATReportNo);
        if VATReportLine2.FindLast then
            exit(VATReportLine2."Line No." + 10000);

        exit(10000);
    end;

    [Scope('OnPrem')]
    procedure RoundBase(AmountToRound: Decimal): Decimal
    begin
        exit(Round(AmountToRound, 1));
    end;

    [Scope('OnPrem')]
    procedure CheckLineType()
    begin
        if "Line Type" = "Line Type"::Cancellation then
            Error(LineCannotBeEditedErr);
    end;

    [Scope('OnPrem')]
    procedure CheckEditingAllowed()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportHeader.Get("VAT Report No.");
        VATReportHeader.CheckEditingAllowed;
    end;

    [Scope('OnPrem')]
    procedure InsertCorrLine(VATReportHeader: Record "VAT Report Header"; CancellationVATReportLine: Record "VAT Report Line"; CorrectionVATReportLine: Record "VAT Report Line"; var TempVATReportLineRelation: Record "VAT Report Line Relation" temporary)
    var
        VATReportLine2: Record "VAT Report Line";
        VATReportLineRelation: Record "VAT Report Line Relation";
        CancellationLineNo: Integer;
    begin
        CheckLineAlreadyCorrected(VATReportHeader, CorrectionVATReportLine);
        with VATReportLine2 do begin
            Init;
            "VAT Report No." := VATReportHeader."No.";
            "Line No." := GetNextLineNo(VATReportHeader."No.");
            "Trade Type" := CancellationVATReportLine."Trade Type";
            "Line Type" := "Line Type"::Cancellation;
            "Related Line No." := CancellationVATReportLine."Line No.";
            "Country/Region Code" := CancellationVATReportLine."Country/Region Code";
            "VAT Registration No." := CancellationVATReportLine."VAT Registration No.";
            "EU 3-Party Trade" := CancellationVATReportLine."EU 3-Party Trade";
            "EU Service" := CancellationVATReportLine."EU Service";
            "Trade Role Type" := CancellationVATReportLine."Trade Role Type";
            "Number of Supplies" := CancellationVATReportLine."Number of Supplies";
            Base := -CancellationVATReportLine.Base;
            Amount := -CancellationVATReportLine.Amount;
            "System-Created" := true;
            Insert(true);
            CancellationLineNo := "Line No.";

            Init;
            "VAT Report No." := VATReportHeader."No.";
            "Line No." += 10000;
            "Trade Type" := CorrectionVATReportLine."Trade Type";
            "Line Type" := "Line Type"::Correction;
            "Related Line No." := CorrectionVATReportLine."Line No.";
            "Country/Region Code" := CorrectionVATReportLine."Country/Region Code";
            "VAT Registration No." := CorrectionVATReportLine."VAT Registration No.";
            "EU 3-Party Trade" := CorrectionVATReportLine."EU 3-Party Trade";
            "EU Service" := CorrectionVATReportLine."EU Service";
            "Trade Role Type" := CorrectionVATReportLine."Trade Role Type";
            "Number of Supplies" := CorrectionVATReportLine."Number of Supplies";
            Base := RoundBase(CorrectionVATReportLine.Base);
            Amount := RoundBase(CorrectionVATReportLine.Amount);
            "System-Created" := true;
            Insert(true);

            TempVATReportLineRelation.SetRange("VAT Report No.", "VAT Report No.");
            TempVATReportLineRelation.SetRange("VAT Report Line No.", CorrectionVATReportLine."Line No.");
            if TempVATReportLineRelation.FindSet then
                repeat
                    VATReportLineRelation := TempVATReportLineRelation;
                    VATReportLineRelation."VAT Report Line No." := "Line No.";
                    VATReportLineRelation.Insert();
                    VATReportLineRelation."VAT Report Line No." := CancellationLineNo;
                    VATReportLineRelation.Insert();
                until TempVATReportLineRelation.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckLineAlreadyCorrected(VATReportHeader: Record "VAT Report Header"; VATReportLine: Record "VAT Report Line")
    var
        VATReportLine1: Record "VAT Report Line";
    begin
        with VATReportLine1 do begin
            SetRange("VAT Report No.", VATReportHeader."No.");
            SetRange("VAT Registration No.", VATReportLine."VAT Registration No.");
            SetRange("Country/Region Code", VATReportLine."Country/Region Code");
            SetRange("Registration No.", VATReportLine."Registration No.");
            SetRange("Trade Role Type", VATReportLine."Trade Role Type");
            SetRange("EU 3-Party Trade", VATReportLine."EU 3-Party Trade");
            SetRange("EU Service", VATReportLine."EU Service");
            if FindFirst then
                Error(CorrectionEntryExistsErr, VATReportHeader."No.");
        end;
    end;
}

