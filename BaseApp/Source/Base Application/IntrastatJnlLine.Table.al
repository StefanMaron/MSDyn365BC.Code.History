table 263 "Intrastat Jnl. Line"
{
    Caption = 'Intrastat Jnl. Line';

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Intrastat Jnl. Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Intrastat Jnl. Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Receipt,Shipment';
            OptionMembers = Receipt,Shipment;
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
        }
        field(6; "Tariff No."; Code[20])
        {
            Caption = 'Tariff No.';
            NotBlank = true;
            TableRelation = "Tariff Number";

            trigger OnValidate()
            begin
                GetItemDescription;
                Validate("Conversion Factor");
            end;
        }
        field(7; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
        }
        field(8; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(9; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(10; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(11; "Source Type"; Option)
        {
            BlankZero = true;
            Caption = 'Source Type';
            OptionCaption = ',Item Entry,Job Entry';
            OptionMembers = ,"Item Entry","Job Entry";
        }
        field(12; "Source Entry No."; Integer)
        {
            Caption = 'Source Entry No.';
            Editable = false;
            TableRelation = IF ("Source Type" = CONST("Item Entry")) "Item Ledger Entry"
            ELSE
            IF ("Source Type" = CONST("Job Entry")) "Job Ledger Entry";
        }
        field(13; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 2 : 5;

            trigger OnValidate()
            begin
                if Quantity <> 0 then
                    "Total Weight" := Round("Net Weight" * Quantity, 0.00001)
                else
                    "Total Weight" := 0;
            end;
        }
        field(14; Amount; Decimal)
        {
            Caption = 'Amount';
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                if "Cost Regulation %" <> 0 then
                    Validate("Cost Regulation %")
                else
                    "Statistical Value" := Amount + "Indirect Cost";
            end;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                if (Quantity <> 0) and Item.Get("Item No.") then
                    Validate("Net Weight", Item."Net Weight")
                else
                    Validate("Net Weight", 0);
                Validate("Conversion Factor");
            end;
        }
        field(16; "Cost Regulation %"; Decimal)
        {
            Caption = 'Cost Regulation %';
            DecimalPlaces = 2 : 2;
            MaxValue = 100;
            MinValue = -100;

            trigger OnValidate()
            begin
                "Indirect Cost" := Round(Amount * "Cost Regulation %" / 100, 1);
                "Statistical Value" := Round(Amount + "Indirect Cost", 1);
            end;
        }
        field(17; "Indirect Cost"; Decimal)
        {
            Caption = 'Indirect Cost';
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                "Cost Regulation %" := 0;
                "Statistical Value" := Amount + "Indirect Cost";
            end;
        }
        field(18; "Statistical Value"; Decimal)
        {
            Caption = 'Statistical Value';
            DecimalPlaces = 0 : 0;
        }
        field(19; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            begin
                TestField("Source Type", 0);

                if "Item No." = '' then
                    Clear(Item)
                else
                    Item.Get("Item No.");

                Name := Item.Description;
                "Tariff No." := Item."Tariff No.";
                "Country/Region of Origin Code" := Item."Country/Region of Origin Code";
                GetItemDescription;
                Validate("Conversion Factor");
            end;
        }
        field(21; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(22; "Total Weight"; Decimal)
        {
            Caption = 'Total Weight';
            DecimalPlaces = 0 : 0;
            Editable = false;
        }
        field(23; "Supplementary Units"; Boolean)
        {
            Caption = 'Supplementary Units';
            Editable = false;
        }
        field(24; "Internal Ref. No."; Text[10])
        {
            Caption = 'Internal Ref. No.';
            Editable = false;
        }
        field(25; "Country/Region of Origin Code"; Code[10])
        {
            Caption = 'Country/Region of Origin Code';
            TableRelation = "Country/Region";
        }
        field(26; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(27; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(28; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(29; "Shpt. Method Code"; Code[10])
        {
            Caption = 'Shpt. Method Code';
            TableRelation = "Shipment Method";
        }
        field(11315; "Conversion Factor"; Decimal)
        {
            Caption = 'Conversion Factor';
            Editable = false;

            trigger OnValidate()
            begin
                "No. of Supplementary Units" := Round(Quantity * "Conversion Factor", 0.00001);
            end;
        }
        field(11316; "Unit of Measure"; Text[10])
        {
            Caption = 'Unit of Measure';
            Editable = false;
        }
        field(11317; "No. of Supplementary Units"; Decimal)
        {
            Caption = 'No. of Supplementary Units';
            Editable = false;
        }
        field(11318; "Partner ID"; Text[50])
        {
            Caption = 'Partner ID';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Source Type", "Source Entry No.")
        {
        }
        key(Key3; Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", "Transaction Specification", "Area")
        {
        }
        key(Key4; "Internal Ref. No.")
        {
        }
        key(Key5; "Document No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        IntrastatJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        if Type = Type::Receipt then
            IntrastatJnlBatch.TestField("System 19 reported", false)
        else
            IntrastatJnlBatch.TestField("System 29 reported", false);
    end;

    trigger OnInsert()
    begin
        IntraJnlTemplate.Get("Journal Template Name");
        IntrastatJnlBatch.Get("Journal Template Name", "Journal Batch Name");
    end;

    trigger OnModify()
    begin
        IntrastatJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        if xRec.Type = Type::Receipt then
            IntrastatJnlBatch.TestField("System 19 reported", false)
        else
            IntrastatJnlBatch.TestField("System 29 reported", false);
    end;

    trigger OnRename()
    begin
        IntrastatJnlBatch.Get(xRec."Journal Template Name", xRec."Journal Batch Name");
        if Type = Type::Receipt then
            IntrastatJnlBatch.TestField("System 19 reported", false)
        else
            IntrastatJnlBatch.TestField("System 29 reported", false);
    end;

    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
        Text11300: Label 'Please enter a conversion factor for tariffno. %1.', Comment = '%1 = Tariff No';

    local procedure GetItemDescription()
    begin
        if "Tariff No." <> '' then begin
            TariffNumber.Get("Tariff No.");
            "Item Description" := TariffNumber.Description;
            "Supplementary Units" := TariffNumber."Supplementary Units";
            "Conversion Factor" := TariffNumber."Conversion Factor";
            "Unit of Measure" := TariffNumber."Unit of Measure";
        end else begin
            "Item Description" := '';
            "Supplementary Units" := false;
            "Conversion Factor" := 0;
            "Unit of Measure" := ''
        end;
        if "Supplementary Units" then
            if "Conversion Factor" = 0 then
                Error(Text11300, "Tariff No.");
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                IntrastatJnlBatch.SetFilter("Journal Template Name", TemplateFilter);
            IntrastatJnlBatch.SetFilter(Name, BatchFilter);
            IntrastatJnlBatch.FindFirst;
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;
}

