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
#if not CLEAN18
                "Statistic Indication" := ''; // NAVCZ
#endif
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
        field(11; "Source Type"; Enum "Intrastat Source Type")
        {
            BlankZero = true;
            Caption = 'Source Type';

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
#if not CLEAN18
                // NAVCZ
                if Item.Get("Item No.") then
                    if "Supplementary Units" then
                        "Supplem. UoM Net Weight" := "Net Weight" *
                           UnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, "Supplem. UoM Code");
                // NAVCZ
#endif
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
#if CLEAN18
                if (Quantity <> 0) and Item.Get("Item No.") then
                    Validate("Net Weight", Item."Net Weight")
                else
                    Validate("Net Weight", 0);
#else
                // NAVCZ
                "Total Weight" := RoundValue("Net Weight" * Quantity);
                if Item.Get("Item No.") then
                    if "Supplementary Units" then
                        "Supplem. UoM Quantity" := Quantity /
                           UnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, "Supplem. UoM Code");
                // NAVCZ
#endif
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
#if CLEAN18
                "Tariff No." := Item."Tariff No.";
#else
                // NAVCZ
                Validate("Net Weight", Item."Net Weight");
                Validate("Tariff No.", Item."Tariff No.");
                "Base Unit of Measure" := Item."Base Unit of Measure";
                // NAVCZ
                "Country/Region of Origin Code" := Item."Country/Region of Origin Code";
                GetItemDescription;
                // NAVCZ
                "Specific Movement" := Item."Specific Movement";
                // NAVCZ
#endif
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
        field(31; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(32; Counterparty; Boolean)
        {
            Caption = 'Counterparty';
        }
        field(31060; "Additional Costs"; Boolean)
        {
            Caption = 'Additional Costs';
            Editable = false;
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
        }
        field(31061; "Source Entry Date"; Date)
        {
            Caption = 'Source Entry Date';
            Editable = false;
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
        }
        field(31062; "Statistic Indication"; Code[10])
        {
            Caption = 'Statistic Indication';
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
        }
        field(31063; "Statistics Period"; Code[10])
        {
            Caption = 'Statistics Period';
            Editable = false;
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
        }
        field(31065; "Declaration No."; Code[10])
        {
            Caption = 'Declaration No.';
            Editable = false;
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
        }
        field(31066; "Statement Type"; Option)
        {
            Caption = 'Statement Type';
            Editable = false;
            OptionCaption = 'Primary,Null,Replacing,Deleting';
            OptionMembers = Primary,Null,Replacing,Deleting;
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
        }
        field(31067; "Prev. Declaration No."; Code[10])
        {
            Caption = 'Prev. Declaration No.';
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
#if not CLEAN18

            trigger OnLookup()
            var
                IntrastatJnlLine: Record "Intrastat Jnl. Line";
                IntrastatJnlLines: Page "Intrastat Journal Lines";
                IntrastatJnlLine2: Record "Intrastat Jnl. Line";
            begin
                Clear(IntrastatJnlLines);
                IntrastatJnlLine.Reset();
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
#endif
        }
        field(31068; "Prev. Declaration Line No."; Integer)
        {
            Caption = 'Prev. Declaration Line No.';
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
#if not CLEAN18

            trigger OnLookup()
            var
                IntrastatJnlLine: Record "Intrastat Jnl. Line";
                IntrastatJnlLines: Page "Intrastat Journal Lines";
                IntrastatJnlLine2: Record "Intrastat Jnl. Line";
            begin
                Clear(IntrastatJnlLines);
                IntrastatJnlLine.Reset();
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
#endif
        }
        field(31069; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            ObsoleteReason = 'Merge to W1';
            ObsoleteState = Removed;
            TableRelation = "Shipment Method";
            ObsoleteTag = '18.0';
        }
        field(31070; "Specific Movement"; Code[10])
        {
            Caption = 'Specific Movement';
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            TableRelation = "Specific Movement".Code;
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
        }
        field(31071; "Supplem. UoM Code"; Code[10])
        {
            Caption = 'Supplem. UoM Code';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
        }
        field(31072; "Supplem. UoM Quantity"; Decimal)
        {
            Caption = 'Supplem. UoM Quantity';
            DecimalPlaces = 0 : 3;
            Editable = false;
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
        }
        field(31073; "Supplem. UoM Net Weight"; Decimal)
        {
            Caption = 'Supplem. UoM Net Weight';
            DecimalPlaces = 2 : 5;
            Editable = false;
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
        }
        field(31074; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
#if CLEAN18
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
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
        key(Key3; Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", "Country/Region of Origin Code", "Partner VAT ID")
        {
        }
        key(Key4; "Internal Ref. No.")
        {
        }
#if not CLEAN18
        key(Key5; Type, "Country/Region Code", "Tariff No.", "Statistic Indication", "Transaction Type", "Shpt. Method Code", "Area", "Transport Method")
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Field "Statistic Indication" is removed and cannot be used in an active key.';
            ObsoleteTag = '18.0';
        }
        key(Key6; Type, "Tariff No.", "Country/Region Code", "Country/Region of Origin Code", "Statistic Indication", "Transaction Type", "Shpt. Method Code", "Area", "Transport Method")
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Field "Statistic Indication" is removed and cannot be used in an active key.';
            ObsoleteTag = '18.0';
        }
#endif
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
    begin
        AssertBatchIsNotReported(Rec);
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
        AssertBatchIsNotReported(Rec);
    end;

    trigger OnRename()
    begin
        AssertBatchIsNotReported(xRec);
    end;

    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";

    local procedure GetItemDescription()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemDescription(IsHandled, Rec);
        if IsHandled then
            exit;

        if "Tariff No." <> '' then begin
            TariffNumber.Get("Tariff No.");
#if not CLEAN18
            // NAVCZ
            TariffNumber.CalcFields("Supplementary Units");
            if TariffNumber."Supplementary Units" then begin
                TariffNumber.TestField("Supplem. Unit of Measure Code");
                "Supplem. UoM Code" := TariffNumber."Supplem. Unit of Measure Code";
            end else
                "Supplem. UoM Code" := '';
            // NAVCZ
#endif
            "Item Description" := TariffNumber.Description;
            "Supplementary Units" := TariffNumber."Supplementary Units";
#if CLEAN18
        end else
            "Item Description" := '';
#else
        end else begin // NAVCZ
            "Item Description" := '';
            "Supplementary Units" := false;
            "Supplem. UoM Code" := '';
        end; // NAVCZ
#endif            
    end;

#if not CLEAN18
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure RoundValue(Value: Decimal): Decimal
    begin
        // NAVCZ
        if Value >= 1 then
            exit(Round(Value, 1));
        exit(Value);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
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

    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure GetDeliveryGroupCode(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        // NAVCZ
        ShipmentMethod.Get("Shpt. Method Code");
        exit(ShipmentMethod."Intrastat Delivery Group Code");
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure GetTotalWeightStr(): Text[30]
    begin
        // NAVCZ
        if "Total Weight" <= 1 then
            exit(Format("Total Weight", 0, PrecisionFormat));
        exit(Format(Round("Total Weight", 1, '>'), 0, PrecisionFormat));
    end;

#endif
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
            IntrastatJnlBatch.FindFirst();
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    local procedure AssertBatchIsNotReported(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        CheckBatchIsNotReported(IntrastatJnlBatch);
    end;

    local procedure CheckBatchIsNotReported(IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBatchIsNotReported(xRec, IntrastatJnlBatch, IsHandled);
        if IsHandled then
            exit;

        IntrastatJnlBatch.TestField(Reported, false);
    end;

    procedure GetCountryOfOriginCode() CountryOfOriginCode: Code[10]
    begin
        if Item.Get("Item No.") then
            CountryOfOriginCode := Item."Country/Region of Origin Code";
        OnAfterGetCountryOfOriginCode(Rec, CountryOfOriginCode);
    end;

    procedure GetPartnerID() PartnerID: Text[50]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPartnerID(Rec, PartnerID, IsHandled);
        if IsHandled then
            exit(PartnerID);

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
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        Customer: Record Customer;
        Vendor: Record Vendor;
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        EU3rdPartyTrade: Boolean;
    begin
        if not ItemLedgerEntry.Get("Source Entry No.") then
            exit('');
        case ItemLedgerEntry."Document Type" of
            ItemLedgerEntry."Document Type"::"Sales Invoice":
                if SalesInvoiceHeader.Get(ItemLedgerEntry."Document No.") then
                    EU3rdPartyTrade := SalesInvoiceHeader."EU 3-Party Trade";
            ItemLedgerEntry."Document Type"::"Sales Credit Memo":
                if SalesCrMemoHeader.Get(ItemLedgerEntry."Document No.") then
                    EU3rdPartyTrade := SalesCrMemoHeader."EU 3-Party Trade";
            ItemLedgerEntry."Document Type"::"Sales Shipment":
                if SalesShipmentHeader.Get(ItemLedgerEntry."Document No.") then
                    EU3rdPartyTrade := SalesShipmentHeader."EU 3-Party Trade";
            ItemLedgerEntry."Document Type"::"Sales Return Receipt":
                if ReturnReceiptHeader.Get(ItemLedgerEntry."Document No.") then
                    EU3rdPartyTrade := ReturnReceiptHeader."EU 3-Party Trade";
            ItemLedgerEntry."Document Type"::"Purchase Credit Memo":
                if PurchCrMemoHdr.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        PurchCrMemoHdr."Pay-to Country/Region Code", PurchCrMemoHdr."VAT Registration No.",
                        IsVendorPrivatePerson(PurchCrMemoHdr."Pay-to Vendor No."), false));
            ItemLedgerEntry."Document Type"::"Purchase Return Shipment":
                if ReturnShipmentHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        ReturnShipmentHeader."Pay-to Country/Region Code", ReturnShipmentHeader."VAT Registration No.",
                        IsVendorPrivatePerson(ReturnShipmentHeader."Pay-to Vendor No."), false));
            ItemLedgerEntry."Document Type"::"Purchase Receipt":
                if PurchRcptHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        PurchRcptHeader."Pay-to Country/Region Code", PurchRcptHeader."VAT Registration No.",
                        IsVendorPrivatePerson(PurchRcptHeader."Pay-to Vendor No."), false));
            ItemLedgerEntry."Document Type"::"Service Shipment":
                if ServiceShipmentHeader.Get(ItemLedgerEntry."Document No.") then begin
                    if not Customer.Get(ServiceShipmentHeader."Bill-to Customer No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ServiceShipmentHeader."Bill-to Country/Region Code", ServiceShipmentHeader."VAT Registration No.",
                        IsCustomerPrivatePerson(ServiceShipmentHeader."Bill-to Customer No."), ServiceShipmentHeader."EU 3-Party Trade"));
                end;
            ItemLedgerEntry."Document Type"::"Service Invoice":
                if ServiceInvoiceHeader.Get(ItemLedgerEntry."Document No.") then begin
                    if not Customer.Get(ServiceInvoiceHeader."Bill-to Customer No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ServiceInvoiceHeader."Bill-to Country/Region Code", ServiceInvoiceHeader."VAT Registration No.",
                        IsCustomerPrivatePerson(ServiceInvoiceHeader."Bill-to Customer No."), ServiceInvoiceHeader."EU 3-Party Trade"));
                end;
            ItemLedgerEntry."Document Type"::"Service Credit Memo":
                if ServiceCrMemoHeader.Get(ItemLedgerEntry."Document No.") then begin
                    if not Customer.Get(ServiceCrMemoHeader."Bill-to Customer No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ServiceCrMemoHeader."Bill-to Country/Region Code", ServiceCrMemoHeader."VAT Registration No.",
                        IsCustomerPrivatePerson(ServiceCrMemoHeader."Bill-to Customer No."), ServiceCrMemoHeader."EU 3-Party Trade"));
                end;
            ItemLedgerEntry."Document Type"::"Transfer Receipt":
                if TransferReceiptHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                        GetPartnerIDForCountry(
                            ItemLedgerEntry."Country/Region Code", TransferReceiptHeader."Partner VAT ID", false, false));
            ItemLedgerEntry."Document Type"::"Transfer Shipment":
                if TransferShipmentHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                        GetPartnerIDForCountry(
                            ItemLedgerEntry."Country/Region Code", TransferShipmentHeader."Partner VAT ID", false, false));
        end;

        if not IntrastatSetup.Get() then
            IntrastatSetup.Init();
        case ItemLedgerEntry."Source Type" of
            ItemLedgerEntry."Source Type"::Customer:
                begin
                    if not Customer.Get(ItemLedgerEntry."Source No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ItemLedgerEntry."Country/Region Code",
                        IntraJnlManagement.GetVATRegNo(
                          Customer."Country/Region Code", Customer."VAT Registration No.", IntrastatSetup."Cust. VAT No. on File"),
                        Customer."Partner Type" = Customer."Partner Type"::Person, EU3rdPartyTrade));
                end;
            ItemLedgerEntry."Source Type"::Vendor:
                begin
                    if not Vendor.Get(ItemLedgerEntry."Source No.") then
                        exit('');
                    exit(
                      GetPartnerIDForCountry(
                        ItemLedgerEntry."Country/Region Code",
                        IntraJnlManagement.GetVATRegNo(
                          Vendor."Country/Region Code", Vendor."VAT Registration No.", IntrastatSetup."Vend. VAT No. on File"),
                        Vendor."Partner Type" = Vendor."Partner Type"::Person, false));
                end;
        end;
    end;

    local procedure GetPartnerIDFromJobEntry(): Text[50]
    var
        Job: Record Job;
        JobLedgerEntry: Record "Job Ledger Entry";
        Customer: Record Customer;
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
    begin
        if not JobLedgerEntry.Get("Source Entry No.") then
            exit('');
        if not Job.Get(JobLedgerEntry."Job No.") then
            exit('');
        if not Customer.Get(Job."Bill-to Customer No.") then
            exit('');
        if not IntrastatSetup.Get() then
            IntrastatSetup.Init();
        exit(
          GetPartnerIDForCountry(
            Customer."Country/Region Code",
            IntraJnlManagement.GetVATRegNo(
              Customer."Country/Region Code", Customer."VAT Registration No.", IntrastatSetup."Cust. VAT No. on File"),
            Customer."Partner Type" = Customer."Partner Type"::Person, false));
    end;

    local procedure GetPartnerIDForCountry(CountryRegionCode: Code[10]; VATRegistrationNo: Text[50]; IsPrivatePerson: Boolean; IsThirdPartyTrade: Boolean): Text[50]
    var
        CountryRegion: Record "Country/Region";
    begin
        if IsPrivatePerson then
            exit('QV999999999999');

        if IsThirdPartyTrade then
            exit('QV999999999999');

        if (CountryRegionCode <> '') and CountryRegion.Get(CountryRegionCode) then
            if CountryRegion.IsEUCountry(CountryRegionCode) then
                if VATRegistrationNo <> '' then
                    exit(VATRegistrationNo);

        exit('QV999999999999');
    end;

    protected procedure IsCustomerPrivatePerson(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            exit(Customer."Partner Type" = Customer."Partner Type"::Person);
        exit(false);
    end;

    protected procedure IsVendorPrivatePerson(VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then
            exit(Vendor."Partner Type" = Vendor."Partner Type"::Person);
        exit(false);
    end;

#if not CLEAN18
    [Obsolete('Moved to Core Localization Pack for Czech.', '18.0')]
    local procedure PrecisionFormat(): Text
    begin
        // NAVCZ
        exit('<Precision,3:3><Standard Format,9>');
    end;

    [Obsolete('This procedure is discontinued. Use IntraJnlManagement event OnBeforeOpenJnl.', '18.0')]
    procedure CheckIntrastatJnlLineUserRestriction()
    begin
        // NAVCZ
        OnCheckIntrastatJnlTemplateUserRestrictions(GetRangeMax("Journal Template Name"));
    end;

#endif
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCountryOfOriginCode(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; var CountryOfOriginCode: Code[10])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBatchIsNotReported(xIntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetItemDescription(var IsHandled: Boolean; var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPartnerID(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; var PartnerID: Text[50]; var IsHandled: Boolean)
    begin
    end;
#if not CLEAN18

    [Obsolete('This Integration Event is discontinued. Use IntraJnlManagement event OnBeforeOpenJnl.', '18.1')]
    [IntegrationEvent(false, false)]
    local procedure OnCheckIntrastatJnlTemplateUserRestrictions(JournalTemplateName: Code[10])
    begin
    end;
#endif
}
