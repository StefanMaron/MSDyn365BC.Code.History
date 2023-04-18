table 5970 "Filed Service Contract Header"
{
    Caption = 'Filed Service Contract Header';
    DrillDownPageID = "Filed Service Contract List";
    LookupPageID = "Filed Service Contract List";
    Permissions = TableData "Filed Service Contract Header" = rimd,
                  TableData "Filed Contract Line" = rimd;

    fields
    {
        field(1; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
        }
        field(2; "Contract Type"; Option)
        {
            Caption = 'Contract Type';
            OptionCaption = 'Quote,Contract';
            OptionMembers = Quote,Contract;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            Editable = true;
            OptionCaption = ' ,Signed,Canceled';
            OptionMembers = " ",Signed,Canceled;
        }
        field(6; "Change Status"; Option)
        {
            Caption = 'Change Status';
            OptionCaption = 'Open,Locked';
            OptionMembers = Open,Locked;
        }
        field(7; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            NotBlank = true;
            TableRelation = Customer;
        }
        field(8; Name; Text[100])
        {
            Caption = 'Name';
            Editable = false;
        }
        field(9; Address; Text[100])
        {
            Caption = 'Address';
            Editable = false;
        }
        field(10; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            Editable = false;
        }
        field(11; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            Editable = false;
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(12; City; Text[30])
        {
            Caption = 'City';
            Editable = false;
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(13; "Contact Name"; Text[100])
        {
            Caption = 'Contact Name';
        }
        field(14; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(15; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));
        }
        field(16; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            TableRelation = Customer;
        }
        field(17; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            Editable = false;
        }
        field(18; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
            Editable = false;
        }
        field(19; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
            Editable = false;
        }
        field(20; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            Editable = false;
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(21; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            Editable = false;
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(22; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code WHERE("Customer No." = FIELD("Customer No."));
        }
        field(23; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            Editable = false;
        }
        field(24; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            Editable = false;
        }
        field(25; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            Editable = false;
        }
        field(26; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            Editable = false;
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(27; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            Editable = false;
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(28; "Serv. Contract Acc. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Contract Acc. Gr. Code';
            TableRelation = "Service Contract Account Group".Code;
        }
        field(32; "Invoice Period"; Option)
        {
            Caption = 'Invoice Period';
            OptionCaption = 'Month,Two Months,Quarter,Half Year,Year,None';
            OptionMembers = Month,"Two Months",Quarter,"Half Year",Year,"None";
        }
        field(33; "Last Invoice Date"; Date)
        {
            Caption = 'Last Invoice Date';
            Editable = false;
        }
        field(34; "Next Invoice Date"; Date)
        {
            Caption = 'Next Invoice Date';
        }
        field(35; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(36; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(38; "First Service Date"; Date)
        {
            Caption = 'First Service Date';
        }
        field(39; "Max. Labor Unit Price"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Max. Labor Unit Price';
        }
        field(40; "Calcd. Annual Amount"; Decimal)
        {
            Caption = 'Calcd. Annual Amount';
        }
        field(42; "Annual Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Annual Amount';
        }
        field(43; "Amount per Period"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount per Period';
            Editable = false;
        }
        field(44; "Combine Invoices"; Boolean)
        {
            Caption = 'Combine Invoices';
        }
        field(45; Prepaid; Boolean)
        {
            Caption = 'Prepaid';
        }
        field(46; "Next Invoice Period"; Text[30])
        {
            Caption = 'Next Invoice Period';
            Editable = false;
        }
        field(47; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            TableRelation = "Service Zone";
        }
        field(48; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(50; "Cancel Reason Code"; Code[10])
        {
            Caption = 'Cancel Reason Code';
            TableRelation = "Reason Code";
        }
        field(51; "Last Price Update Date"; Date)
        {
            Caption = 'Last Price Update Date';
            Editable = false;
        }
        field(52; "Next Price Update Date"; Date)
        {
            Caption = 'Next Price Update Date';
        }
        field(53; "Last Price Update %"; Decimal)
        {
            Caption = 'Last Price Update %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(55; "Response Time (Hours)"; Decimal)
        {
            Caption = 'Response Time (Hours)';
            DecimalPlaces = 0 : 5;
        }
        field(56; "Contract Lines on Invoice"; Boolean)
        {
            Caption = 'Contract Lines on Invoice';
        }
        field(59; "Service Period"; DateFormula)
        {
            Caption = 'Service Period';
        }
        field(60; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(62; "Invoice after Service"; Boolean)
        {
            Caption = 'Invoice after Service';
        }
        field(63; "Quote Type"; Option)
        {
            Caption = 'Quote Type';
            OptionCaption = 'Quote 1.,Quote 2.,Quote 3.,Quote 4.,Quote 5.,Quote 6.,Quote 7.,Quote 8.';
            OptionMembers = "Quote 1.","Quote 2.","Quote 3.","Quote 4.","Quote 5.","Quote 6.","Quote 7.","Quote 8.";
        }
        field(64; "Allow Unbalanced Amounts"; Boolean)
        {
            Caption = 'Allow Unbalanced Amounts';
        }
        field(65; "Contract Group Code"; Code[10])
        {
            Caption = 'Contract Group Code';
            TableRelation = "Contract Group";
        }
        field(66; "Service Order Type"; Code[10])
        {
            Caption = 'Service Order Type';
            TableRelation = "Service Order Type";
        }
        field(67; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(68; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(69; "Accept Before"; Date)
        {
            Caption = 'Accept Before';
        }
        field(71; "Automatic Credit Memos"; Boolean)
        {
            Caption = 'Automatic Credit Memos';
        }
        field(74; "Template No."; Code[20])
        {
            Caption = 'Template No.';
        }
        field(75; "Price Update Period"; DateFormula)
        {
            Caption = 'Price Update Period';
            InitValue = '1Y';
        }
        field(79; "Price Inv. Increase Code"; Code[20])
        {
            Caption = 'Price Inv. Increase Code';
            TableRelation = "Standard Text";
        }
        field(80; "Print Increase Text"; Boolean)
        {
            Caption = 'Print Increase Text';
        }
        field(81; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(82; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(83; Probability; Decimal)
        {
            Caption = 'Probability';
            DecimalPlaces = 0 : 5;
            InitValue = 100;
        }
        field(85; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(86; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(87; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(88; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(89; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
        }
        field(90; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(91; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        field(92; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(93; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(94; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(95; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
            Editable = false;
        }
        field(96; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
            Editable = false;
        }
        field(97; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
            Editable = false;
        }
        field(98; "Next Invoice Period Start"; Date)
        {
            Caption = 'Next Invoice Period Start';
            Editable = false;
        }
        field(99; "Next Invoice Period End"; Date)
        {
            Caption = 'Next Invoice Period End';
            Editable = false;
        }
        field(100; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(101; "File Date"; Date)
        {
            Caption = 'File Date';
        }
        field(102; "File Time"; Time)
        {
            Caption = 'File Time';
        }
        field(103; "Filed By"; Code[50])
        {
            Caption = 'Filed By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(104; "Reason for Filing"; Option)
        {
            Caption = 'Reason for Filing';
            OptionCaption = ' ,Contract Signed,Contract Canceled';
            OptionMembers = " ","Contract Signed","Contract Canceled";
        }
        field(105; "Contract Type Relation"; Enum "Service Contract Type")
        {
            Caption = 'Contract Type Relation';
        }
        field(106; "Contract No. Relation"; Code[20])
        {
            Caption = 'Contract No. Relation';
            TableRelation = "Service Contract Header"."Contract No." WHERE("Contract Type" = FIELD("Contract Type Relation"));
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
        field(5050; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
        }
        field(5051; "Bill-to Contact No."; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Bill-to Contact No.';
        }
        field(5052; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Contract Type Relation", "Contract No. Relation", "File Date", "File Time")
        {
        }
        key(Key3; "Contract Type", "Contract No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        FiledContractLine.Reset();
        FiledContractLine.SetRange("Entry No.", "Entry No.");
        FiledContractLine.DeleteAll();
    end;

    var
        FiledServContractHeader: Record "Filed Service Contract Header";
        FiledContractLine: Record "Filed Contract Line";
        DimMgt: Codeunit DimensionManagement;
        SigningQuotation: Boolean;
        CancelContract: Boolean;
        Text027: Label '%1 to %2';

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure FileContract(ServContractHeader: Record "Service Contract Header")
    var
        ServContractLine: Record "Service Contract Line";
        NextEntryNo: Integer;
    begin
        with ServContractHeader do begin
            TestField("Contract No.");

            FiledContractLine.LockTable();
            FiledServContractHeader.LockTable();

            FiledServContractHeader.Reset();
            NextEntryNo := FiledServContractHeader.GetLastEntryNo() + 1;

            FiledServContractHeader.Init();
            CalcFields(
              Name, Address, "Address 2", "Post Code", City, County, "Country/Region Code", "Name 2",
              "Bill-to Name", "Bill-to Address", "Bill-to Address 2", "Bill-to Post Code",
              "Bill-to City", "Bill-to County", "Bill-to Country/Region Code", "Bill-to Name 2",
              "Calcd. Annual Amount");
            if "Ship-to Code" = '' then begin
                "Ship-to Name" := Name;
                "Ship-to Address" := Address;
                "Ship-to Address 2" := "Address 2";
                "Ship-to Post Code" := "Post Code";
                "Ship-to City" := City;
                "Ship-to County" := County;
                "Ship-to Country/Region Code" := "Country/Region Code";
                "Ship-to Name 2" := "Name 2";
            end else
                CalcFields(
                  "Ship-to Name", "Ship-to Address", "Ship-to Address 2", "Ship-to Post Code", "Ship-to City",
                  "Ship-to County", "Ship-to Country/Region Code", "Ship-to Name 2");

            FiledServContractHeader.TransferFields(ServContractHeader);

            if SigningQuotation then
                FiledServContractHeader."Reason for Filing" :=
                  FiledServContractHeader."Reason for Filing"::"Contract Signed";

            if CancelContract then
                FiledServContractHeader."Reason for Filing" :=
                  FiledServContractHeader."Reason for Filing"::"Contract Canceled";

            FiledServContractHeader."Contract Type Relation" := "Contract Type";
            FiledServContractHeader."Contract No. Relation" := "Contract No.";
            FiledServContractHeader."Entry No." := NextEntryNo;
            FiledServContractHeader."File Date" := Today;
            FiledServContractHeader."File Time" := Time;
            FiledServContractHeader."Filed By" := UserId;
            FiledServContractHeader.Name := Name;
            FiledServContractHeader.Address := Address;
            FiledServContractHeader."Address 2" := "Address 2";
            FiledServContractHeader."Post Code" := "Post Code";
            FiledServContractHeader.City := City;
            FiledServContractHeader."Bill-to Name" := "Bill-to Name";
            FiledServContractHeader."Bill-to Address" := "Bill-to Address";
            FiledServContractHeader."Bill-to Address 2" := "Bill-to Address 2";
            FiledServContractHeader."Bill-to Post Code" := "Bill-to Post Code";
            FiledServContractHeader."Bill-to City" := "Bill-to City";
            FiledServContractHeader."Ship-to Name" := "Ship-to Name";
            FiledServContractHeader."Ship-to Address" := "Ship-to Address";
            FiledServContractHeader."Ship-to Address 2" := "Ship-to Address 2";
            FiledServContractHeader."Ship-to Post Code" := "Ship-to Post Code";
            FiledServContractHeader."Ship-to City" := "Ship-to City";
            FiledServContractHeader."Calcd. Annual Amount" := "Calcd. Annual Amount";
            FiledServContractHeader."Bill-to County" := "Bill-to County";
            FiledServContractHeader.County := County;
            FiledServContractHeader."Ship-to County" := "Ship-to County";
            FiledServContractHeader."Country/Region Code" := "Country/Region Code";
            FiledServContractHeader."Bill-to Country/Region Code" := "Bill-to Country/Region Code";
            FiledServContractHeader."Ship-to Country/Region Code" := "Ship-to Country/Region Code";
            FiledServContractHeader."Name 2" := "Name 2";
            FiledServContractHeader."Bill-to Name 2" := "Bill-to Name 2";
            FiledServContractHeader."Ship-to Name 2" := "Ship-to Name 2";
            OnFileContractOnBeforeFiledServContractHeaderInsert(ServContractHeader, FiledServContractHeader);
            FiledServContractHeader.Insert();

            ServContractLine.Reset();
            ServContractLine.SetRange("Contract Type", "Contract Type");
            ServContractLine.SetRange("Contract No.", "Contract No.");
            if ServContractLine.Find('-') then
                repeat
                    FiledContractLine.Init();
                    FiledContractLine."Entry No." := FiledServContractHeader."Entry No.";
                    FiledContractLine.TransferFields(ServContractLine);
                    FiledContractLine.Insert();
                until ServContractLine.Next() = 0;
        end;

        OnAfterFileContract(FiledServContractHeader, ServContractHeader);
    end;

    procedure FileQuotationBeforeSigning(ServContract: Record "Service Contract Header")
    begin
        SigningQuotation := true;
        FileContract(ServContract);
        SigningQuotation := false;
    end;

    procedure FileContractBeforeCancellation(ServContract: Record "Service Contract Header")
    begin
        CancelContract := true;
        FileContract(ServContract);
        CancelContract := false;
    end;

    procedure NextInvoicePeriod(): Text[250]
    begin
        if ("Next Invoice Period Start" <> 0D) and ("Next Invoice Period End" <> 0D) then
            exit(StrSubstNo(Text027, "Next Invoice Period Start", "Next Invoice Period End"));
    end;

    local procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Contract No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFileContract(var FiledServiceContractHeader: Record "Filed Service Contract Header"; ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFileContractOnBeforeFiledServContractHeaderInsert(var ServiceContractHeader: Record "Service Contract Header"; var FiledServiceContractHeader: Record "Filed Service Contract Header")
    begin
    end;
}

