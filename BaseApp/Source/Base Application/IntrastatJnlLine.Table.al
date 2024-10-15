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
                "Statistic Indication" := ''; // NAVCZ
            end;
        }
        field(7; "Item Description"; Text[250])
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
            trigger OnValidate()
            begin
                if Type = Type::Shipment then begin
                    "Country/Region of Origin Code" := GetCountryOfOriginCode();
                    "Partner VAT ID" := GetPartnerID();
                end;
            end;
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
                // NAVCZ
                if Item.Get("Item No.") then
                    if "Supplementary Units" then
                        "Supplem. UoM Net Weight" := "Net Weight" *
                           UnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, "Supplem. UoM Code");
                // NAVCZ
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
            DecimalPlaces = 0 : 3;

            trigger OnValidate()
            begin
                // NAVCZ
                // IF (Quantity <> 0) AND Item.GET("Item No.") THEN
                // VALIDATE("Net Weight",Item."Net Weight")
                // ELSE
                // VALIDATE("Net Weight",0);
                "Total Weight" := RoundValue("Net Weight" * Quantity);
                if Item.Get("Item No.") then
                    if "Supplementary Units" then
                        "Supplem. UoM Quantity" := Quantity /
                           UnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, "Supplem. UoM Code");
                // NAVCZ
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
                Validate("Statistical Value", Amount + "Indirect Cost"); // NAVCZ
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
                // NAVCZ
                // "Tariff No." := Item."Tariff No.";
                Validate("Net Weight", Item."Net Weight");
                Validate("Tariff No.", Item."Tariff No.");
                "Base Unit of Measure" := Item."Base Unit of Measure";
                // NAVCZ
                "Country/Region of Origin Code" := Item."Country/Region of Origin Code";
                GetItemDescription;
                // NAVCZ
                "Statistic Indication" := Item."Statistic Indication";
                "Specific Movement" := Item."Specific Movement";
                // NAVCZ
            end;
        }
        field(21; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(22; "Total Weight"; Decimal)
        {
            Caption = 'Total Weight';
            DecimalPlaces = 2 : 5;
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
        field(30; "Partner VAT ID"; Text[50])
        {
            Caption = 'Partner VAT ID';
        }
        field(31060; "Additional Costs"; Boolean)
        {
            Caption = 'Additional Costs';
            Editable = false;
        }
        field(31061; "Source Entry Date"; Date)
        {
            Caption = 'Source Entry Date';
            Editable = false;
        }
        field(31062; "Statistic Indication"; Code[10])
        {
            Caption = 'Statistic Indication';
            TableRelation = "Statistic Indication".Code WHERE("Tariff No." = FIELD("Tariff No."));
        }
        field(31063; "Statistics Period"; Code[10])
        {
            Caption = 'Statistics Period';
            Editable = false;
        }
        field(31065; "Declaration No."; Code[10])
        {
            Caption = 'Declaration No.';
            Editable = false;
        }
        field(31066; "Statement Type"; Option)
        {
            Caption = 'Statement Type';
            Editable = false;
            OptionCaption = 'Primary,Null,Replacing,Deleting';
            OptionMembers = Primary,Null,Replacing,Deleting;
        }
        field(31067; "Prev. Declaration No."; Code[10])
        {
            Caption = 'Prev. Declaration No.';

            trigger OnLookup()
            var
                IntrastatJnlLine: Record "Intrastat Jnl. Line";
                IntrastatJnlLines: Page "Intrastat Journal Lines";
                IntrastatJnlLine2: Record "Intrastat Jnl. Line";
            begin
                Clear(IntrastatJnlLines);
                IntrastatJnlLine.Reset;
                IntrastatJnlLine.FilterGroup(2);
                IntrastatJnlLine.SetFilter("Declaration No.", '<>%1', '');
                IntrastatJnlLine.FilterGroup(0);
                IntrastatJnlLines.LookupMode := true;
                IntrastatJnlLines.SetTableView(IntrastatJnlLine);
                if IntrastatJnlLines.RunModal = ACTION::LookupOK then begin
                    IntrastatJnlLines.GetRecord(IntrastatJnlLine2);
                    "Prev. Declaration No." := IntrastatJnlLine2."Declaration No.";
                end;
            end;
        }
        field(31068; "Prev. Declaration Line No."; Integer)
        {
            Caption = 'Prev. Declaration Line No.';

            trigger OnLookup()
            var
                IntrastatJnlLine: Record "Intrastat Jnl. Line";
                IntrastatJnlLines: Page "Intrastat Journal Lines";
                IntrastatJnlLine2: Record "Intrastat Jnl. Line";
            begin
                Clear(IntrastatJnlLines);
                IntrastatJnlLine.Reset;
                IntrastatJnlLine.FilterGroup(2);
                if "Prev. Declaration No." <> '' then
                    IntrastatJnlLine.SetRange("Declaration No.", "Prev. Declaration No.")
                else
                    IntrastatJnlLine.SetFilter("Declaration No.", '<>%1', '');
                IntrastatJnlLine.FilterGroup(0);
                IntrastatJnlLines.LookupMode := true;
                IntrastatJnlLines.SetTableView(IntrastatJnlLine);
                if IntrastatJnlLines.RunModal = ACTION::LookupOK then begin
                    IntrastatJnlLines.GetRecord(IntrastatJnlLine2);
                    IntrastatJnlLine2."Journal Template Name" := "Journal Template Name";
                    IntrastatJnlLine2."Journal Batch Name" := "Journal Batch Name";
                    IntrastatJnlLine2.Type := Type;
                    IntrastatJnlLine2."Internal Ref. No." := "Internal Ref. No.";
                    IntrastatJnlLine2."Prev. Declaration No." := IntrastatJnlLine2."Declaration No.";
                    IntrastatJnlLine2."Prev. Declaration Line No." := IntrastatJnlLine2."Line No.";
                    IntrastatJnlLine2."Declaration No." := "Declaration No.";
                    IntrastatJnlLine2."Line No." := "Line No.";
                    IntrastatJnlLine2."Statistics Period" := "Statistics Period";
                    TransferFields(IntrastatJnlLine2, false);
                end;
            end;
        }
        field(31069; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            ObsoleteReason = 'Merge to W1';
            ObsoleteState = Pending;
            TableRelation = "Shipment Method";
            ObsoleteTag = '15.0';
        }
        field(31070; "Specific Movement"; Code[10])
        {
            Caption = 'Specific Movement';
            TableRelation = "Specific Movement".Code;
        }
        field(31071; "Supplem. UoM Code"; Code[10])
        {
            Caption = 'Supplem. UoM Code';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(31072; "Supplem. UoM Quantity"; Decimal)
        {
            Caption = 'Supplem. UoM Quantity';
            DecimalPlaces = 0 : 3;
            Editable = false;
        }
        field(31073; "Supplem. UoM Net Weight"; Decimal)
        {
            Caption = 'Supplem. UoM Net Weight';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(31074; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
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
        key(Key3; Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method")
        {
        }
        key(Key4; "Internal Ref. No.")
        {
        }
        key(Key5; Type, "Country/Region Code", "Tariff No.", "Statistic Indication", "Transaction Type", "Shpt. Method Code", "Area", "Transport Method")
        {
        }
        key(Key6; Type, "Tariff No.", "Country/Region Code", "Country/Region of Origin Code", "Statistic Indication", "Transaction Type", "Shpt. Method Code", "Area", "Transport Method")
        {
        }
        key(Key7; "Document No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ErrorMessage: Record "Error Message";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        ErrorMessage.SetContext(IntrastatJnlBatch);
        ErrorMessage.ClearLogRec(Rec);
    end;

    trigger OnInsert()
    begin
        IntraJnlTemplate.Get("Journal Template Name");
        IntrastatJnlBatch.Get("Journal Template Name", "Journal Batch Name");
    end;

    trigger OnModify()
    begin
        IntrastatJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        IntrastatJnlBatch.TestField(Reported, false);
    end;

    trigger OnRename()
    begin
        IntrastatJnlBatch.Get(xRec."Journal Template Name", xRec."Journal Batch Name");
        IntrastatJnlBatch.TestField(Reported, false);
    end;

    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";

    local procedure GetItemDescription()
    begin
        if "Tariff No." <> '' then begin
            TariffNumber.Get("Tariff No.");
            // NAVCZ
            TariffNumber.CalcFields("Supplementary Units");
            if TariffNumber."Supplementary Units" then begin
                TariffNumber.TestField("Supplem. Unit of Measure Code");
                "Supplem. UoM Code" := TariffNumber."Supplem. Unit of Measure Code";
            end else
                "Supplem. UoM Code" := '';
            // NAVCZ
            "Item Description" := TariffNumber.Description;
            "Supplementary Units" := TariffNumber."Supplementary Units";
        end else begin // NAVCZ
            "Item Description" := '';
            "Supplementary Units" := false;
            "Supplem. UoM Code" := '';
        end; // NAVCZ
    end;

    [Scope('OnPrem')]
    procedure RoundValue(Value: Decimal): Decimal
    begin
        // NAVCZ
        if Value >= 1 then
            exit(Round(Value, 1));
        exit(Value);
    end;

    [Scope('OnPrem')]
    procedure GetQuantityStr(): Text[30]
    var
        TariffNumber: Record "Tariff Number";
    begin
        // NAVCZ
        TariffNumber.Get("Tariff No.");
        TariffNumber.CalcFields("Supplementary Units");
        if not TariffNumber."Supplementary Units" then
            exit(Format(0.0, 0, PrecisionFormat));
        exit(Format("Supplem. UoM Quantity", 0, PrecisionFormat));
    end;

    [Scope('OnPrem')]
    procedure GetDeliveryGroupCode(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        // NAVCZ
        ShipmentMethod.Get("Shpt. Method Code");
        exit(ShipmentMethod."Intrastat Delivery Group Code");
    end;

    [Scope('OnPrem')]
    procedure GetTotalWeightStr(): Text[30]
    begin
        // NAVCZ
        if "Total Weight" <= 1 then
            exit(Format("Total Weight", 0, PrecisionFormat));
        exit(Format(Round("Total Weight", 1, '>'), 0, PrecisionFormat));
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

    procedure GetCountryOfOriginCode(): Code[10]
    begin
        if not Item.Get("Item No.") then
            exit('');
        exit(Item."Country/Region of Origin Code");
    end;

    procedure GetPartnerID(): Text[50]
    begin
        case "Source Type" of
            "Source Type"::"Job Entry":
                exit(GetPartnerIDFromJobEntry());
            "Source Type"::"Item Entry":
                exit(GetPartnerIDFromItemEntry());
        end;
    end;

    local procedure GetPartnerIDFromItemEntry(): Text[50]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        Customer: Record Customer;
    begin
        ItemLedgerEntry.Get("Source Entry No.");
        case ItemLedgerEntry."Document Type" of
            ItemLedgerEntry."Document Type"::"Sales Invoice":
                begin
                    SalesInvoiceHeader.Get(ItemLedgerEntry."Document No.");
                    exit(
                      GetPartnerIDForCountry(
                        SalesInvoiceHeader."Bill-to Country/Region Code", SalesInvoiceHeader."VAT Registration No."));
                end;
            ItemLedgerEntry."Document Type"::"Sales Shipment":
                begin
                    SalesShipmentHeader.Get(ItemLedgerEntry."Document No.");
                    exit(
                      GetPartnerIDForCountry(
                        SalesShipmentHeader."Bill-to Country/Region Code", SalesShipmentHeader."VAT Registration No."));
                end;
            ItemLedgerEntry."Document Type"::"Sales Return Receipt":
                begin
                    ReturnReceiptHeader.Get(ItemLedgerEntry."Document No.");
                    exit(
                      GetPartnerIDForCountry(
                        ReturnReceiptHeader."Bill-to Country/Region Code", ReturnReceiptHeader."VAT Registration No."));
                end;
            ItemLedgerEntry."Document Type"::"Purchase Credit Memo":
                begin
                    PurchCrMemoHdr.Get(ItemLedgerEntry."Document No.");
                    exit(
                      GetPartnerIDForCountry(
                        PurchCrMemoHdr."Pay-to Country/Region Code", PurchCrMemoHdr."VAT Registration No."));
                end;
            ItemLedgerEntry."Document Type"::"Purchase Return Shipment":
                begin
                    ReturnShipmentHeader.Get(ItemLedgerEntry."Document No.");
                    exit(
                      GetPartnerIDForCountry(
                        ReturnShipmentHeader."Pay-to Country/Region Code", ReturnShipmentHeader."VAT Registration No."));
                end;
            ItemLedgerEntry."Document Type"::"Purchase Receipt":
                begin
                    PurchRcptHeader.Get(ItemLedgerEntry."Document No.");
                    exit(
                      GetPartnerIDForCountry(
                        PurchRcptHeader."Pay-to Country/Region Code", PurchRcptHeader."VAT Registration No."));
                end;
            ItemLedgerEntry."Document Type"::"Service Shipment":
                begin
                    ServiceShipmentHeader.Get(ItemLedgerEntry."Document No.");
                    Customer.Get(ServiceShipmentHeader."Bill-to Customer No.");
                    exit(
                      GetPartnerIDForCountry(
                        ServiceShipmentHeader."Bill-to Country/Region Code", ServiceShipmentHeader."VAT Registration No."));
                end;
            ItemLedgerEntry."Document Type"::"Service Invoice":
                begin
                    ServiceInvoiceHeader.Get(ItemLedgerEntry."Document No.");
                    Customer.Get(ServiceInvoiceHeader."Bill-to Customer No.");
                    exit(
                      GetPartnerIDForCountry(
                        ServiceInvoiceHeader."Bill-to Country/Region Code", ServiceInvoiceHeader."VAT Registration No."));
                end;
        end;
    end;

    local procedure GetPartnerIDFromJobEntry(): Text[50]
    var
        Job: Record Job;
        JobLedgerEntry: Record "Job Ledger Entry";
        Customer: Record Customer;
    begin
        JobLedgerEntry.Get("Source Entry No.");
        Job.Get(JobLedgerEntry."Job No.");
        Customer.Get(Job."Bill-to Customer No.");
        exit(
          GetPartnerIDForCountry(Customer."Country/Region Code", Customer."VAT Registration No."));
    end;

    local procedure GetPartnerIDForCountry(CountryRegionCode: Code[10]; VATRegistrationNo: Code[20]): Text[50]
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.Get(CountryRegionCode) then
            if CountryRegion.IsEUCountry(CountryRegionCode) then
                if VATRegistrationNo <> '' then
                    exit(VATRegistrationNo);
        exit('QV999999999999');
    end;

    local procedure PrecisionFormat(): Text
    begin
        // NAVCZ
        exit('<Precision,3:3><Standard Format,9>');
    end;

    procedure CheckIntrastatJnlLineUserRestriction()
    begin
        // NAVCZ
        OnCheckIntrastatJnlTemplateUserRestrictions(GetRangeMax("Journal Template Name"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIntrastatJnlTemplateUserRestrictions(JournalTemplateName: Code[10])
    begin
    end;
}

