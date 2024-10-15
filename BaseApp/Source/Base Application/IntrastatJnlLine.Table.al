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
        field(30; "Partner VAT ID"; Text[50])
        {
            Caption = 'Partner VAT ID';
        }
        field(31;"Location Code";Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
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
            ObsoleteState = Pending;
            ObsoleteReason = 'Merged to W1';
            ObsoleteTag = '18.0';
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
    procedure GetCountryOfOriginCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        if not Item.Get("Item No.") then
            exit('');
        if Item."Country/Region of Origin Code" <> '' then
            exit(Item."Country/Region of Origin Code");
        CompanyInformation.Get();
        if CompanyInformation."Country/Region Code" <> '' then
            exit(CompanyInformation."Country/Region Code");
        exit('QU');
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
    begin
        ItemLedgerEntry.Get("Source Entry No.");
        case ItemLedgerEntry."Document Type" of
            ItemLedgerEntry."Document Type"::"Sales Invoice":
                if SalesInvoiceHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        SalesInvoiceHeader."Bill-to Country/Region Code",
                        SalesInvoiceHeader."VAT Registration No.", SalesInvoiceHeader."Enterprise No.",
                        IsCustomerPrivatePerson(SalesInvoiceHeader."Bill-to Customer No."), SalesInvoiceHeader."EU 3-Party Trade"));
            ItemLedgerEntry."Document Type"::"Sales Credit Memo":
                if SalesCrMemoHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        SalesCrMemoHeader."Bill-to Country/Region Code",
                        SalesCrMemoHeader."VAT Registration No.", SalesCrMemoHeader."Enterprise No.",
                        IsCustomerPrivatePerson(SalesCrMemoHeader."Bill-to Customer No."), SalesCrMemoHeader."EU 3-Party Trade"));
            ItemLedgerEntry."Document Type"::"Sales Shipment":
                if SalesShipmentHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        SalesShipmentHeader."Bill-to Country/Region Code",
                        SalesShipmentHeader."VAT Registration No.", SalesShipmentHeader."Enterprise No.",
                        IsCustomerPrivatePerson(SalesShipmentHeader."Bill-to Customer No."), SalesShipmentHeader."EU 3-Party Trade"));
            ItemLedgerEntry."Document Type"::"Sales Return Receipt":
                if ReturnReceiptHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        ReturnReceiptHeader."Bill-to Country/Region Code",
                        ReturnReceiptHeader."VAT Registration No.", ReturnReceiptHeader."Enterprise No.",
                        IsCustomerPrivatePerson(ReturnReceiptHeader."Bill-to Customer No."), ReturnReceiptHeader."EU 3-Party Trade"));
            ItemLedgerEntry."Document Type"::"Purchase Credit Memo":
                if PurchCrMemoHdr.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        PurchCrMemoHdr."Pay-to Country/Region Code",
                        PurchCrMemoHdr."VAT Registration No.", PurchCrMemoHdr."Enterprise No.",
                        IsVendorPrivatePerson(PurchCrMemoHdr."Pay-to Vendor No."), false));
            ItemLedgerEntry."Document Type"::"Purchase Return Shipment":
                if ReturnShipmentHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        ReturnShipmentHeader."Pay-to Country/Region Code",
                        ReturnShipmentHeader."VAT Registration No.", ReturnShipmentHeader."Enterprise No.",
                        IsVendorPrivatePerson(ReturnShipmentHeader."Pay-to Vendor No."), false));
            ItemLedgerEntry."Document Type"::"Purchase Receipt":
                if PurchRcptHeader.Get(ItemLedgerEntry."Document No.") then
                    exit(
                      GetPartnerIDForCountry(
                        PurchRcptHeader."Pay-to Country/Region Code",
                        PurchRcptHeader."VAT Registration No.", PurchRcptHeader."Enterprise No.",
                        IsVendorPrivatePerson(PurchRcptHeader."Pay-to Vendor No."), false));
            ItemLedgerEntry."Document Type"::"Service Shipment":
                if ServiceShipmentHeader.Get(ItemLedgerEntry."Document No.") then begin
                    Customer.Get(ServiceShipmentHeader."Bill-to Customer No.");
                    exit(
                      GetPartnerIDForCountry(
                        ServiceShipmentHeader."Bill-to Country/Region Code",
                        ServiceShipmentHeader."VAT Registration No.", Customer."Enterprise No.",
                        IsCustomerPrivatePerson(ServiceShipmentHeader."Bill-to Customer No."), ServiceShipmentHeader."EU 3-Party Trade"));
                end;
            ItemLedgerEntry."Document Type"::"Service Invoice":
                if ServiceInvoiceHeader.Get(ItemLedgerEntry."Document No.") then begin
                    Customer.Get(ServiceInvoiceHeader."Bill-to Customer No.");
                    exit(
                      GetPartnerIDForCountry(
                        ServiceInvoiceHeader."Bill-to Country/Region Code",
                        ServiceInvoiceHeader."VAT Registration No.", Customer."Enterprise No.",
                        IsCustomerPrivatePerson(ServiceInvoiceHeader."Bill-to Customer No."), ServiceInvoiceHeader."EU 3-Party Trade"));
                end;
            ItemLedgerEntry."Document Type"::"Service Credit Memo":
                if ServiceCrMemoHeader.Get(ItemLedgerEntry."Document No.") then begin
                    Customer.Get(ServiceCrMemoHeader."Bill-to Customer No.");
                    exit(
                      GetPartnerIDForCountry(
                        ServiceCrMemoHeader."Bill-to Country/Region Code",
                        ServiceCrMemoHeader."VAT Registration No.", Customer."Enterprise No.",
                        IsCustomerPrivatePerson(ServiceCrMemoHeader."Bill-to Customer No."), ServiceCrMemoHeader."EU 3-Party Trade"));
                end;
        end;

        case ItemLedgerEntry."Source Type" of
            ItemLedgerEntry."Source Type"::Customer:
                begin
                    Customer.Get(ItemLedgerEntry."Source No.");
                    exit(
                      GetPartnerIDForCountry(
                        ItemLedgerEntry."Country/Region Code", Customer."VAT Registration No.", Customer."Enterprise No.",
                        Customer."Partner Type" = Customer."Partner Type"::Person, false));
                end;
            ItemLedgerEntry."Source Type"::Vendor:
                begin
                    Vendor.Get(ItemLedgerEntry."Source No.");
                    exit(
                      GetPartnerIDForCountry(
                        ItemLedgerEntry."Country/Region Code", Vendor."VAT Registration No.", Vendor."Enterprise No.",
                        Vendor."Partner Type" = Vendor."Partner Type"::Person, false));
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
          GetPartnerIDForCountry(
            Customer."Country/Region Code", Customer."VAT Registration No.", Customer."Enterprise No.",
            Customer."Partner Type" = Customer."Partner Type"::Person, false));
    end;

    local procedure GetPartnerIDForCountry(CountryRegionCode: Code[10]; VATRegistrationNo: Code[20]; EnterpriseNo: Text[50]; IsPrivatePerson: Boolean; IsThirdPartyTrade: Boolean): Text[50]
    var
        CountryRegion: Record "Country/Region";
    begin
        if IsPrivatePerson then
            exit('QV999999999999');

        CountryRegion.Get(CountryRegionCode);
        if CountryRegion.IsEUCountry(CountryRegionCode) then begin
            if VATRegistrationNo <> '' then
                exit(VATRegistrationNo);
            if EnterpriseNo <> '' then
                exit(EnterpriseNo);
        end;
        if IsThirdPartyTrade then
            exit('QV999999999999');

        exit('QV999999999999');
    end;

    local procedure IsCustomerPrivatePerson(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            exit(Customer."Partner Type" = Customer."Partner Type"::Person);
        exit(false);
    end;

    local procedure IsVendorPrivatePerson(VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then
            exit(Vendor."Partner Type" = Vendor."Partner Type"::Person);
        exit(false);
    end;

}

