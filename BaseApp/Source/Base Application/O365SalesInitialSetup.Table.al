table 2110 "O365 Sales Initial Setup"
{
    Caption = 'O365 Sales Initial Setup';
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Payment Reg. Template Name"; Code[10])
        {
            Caption = 'Payment Reg. Template Name';
            TableRelation = "Gen. Journal Template".Name;
        }
        field(3; "Payment Reg. Batch Name"; Code[10])
        {
            Caption = 'Payment Reg. Batch Name';
            TableRelation = "Gen. Journal Batch".Name WHERE("Journal Template Name" = FIELD("Payment Reg. Template Name"));
        }
        field(4; "Is initialized"; Boolean)
        {
            Caption = 'Is initialized';
        }
        field(5; "Default Customer Template"; Code[10])
        {
            Caption = 'Default Customer Template';
            TableRelation = "Config. Template Header".Code WHERE("Table ID" = CONST(18));
        }
        field(6; "Default Item Template"; Code[10])
        {
            Caption = 'Default Item Template';
            TableRelation = "Config. Template Header".Code WHERE("Table ID" = CONST(27));
        }
        field(7; "Default Payment Terms Code"; Code[10])
        {
            Caption = 'Default Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(8; "Default Payment Method Code"; Code[10])
        {
            Caption = 'Default Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(9; "Sales Invoice No. Series"; Code[20])
        {
            Caption = 'Sales Invoice No. Series';
            TableRelation = "No. Series";
        }
        field(10; "Posted Sales Inv. No. Series"; Code[20])
        {
            Caption = 'Posted Sales Inv. No. Series';
            TableRelation = "No. Series";
        }
        field(11; "Tax Type"; Option)
        {
            Caption = 'Tax Type';
            OptionCaption = 'VAT,Sales Tax';
            OptionMembers = VAT,"Sales Tax";
        }
        field(12; "Default VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Default VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(13; "Normal VAT Prod. Posting Gr."; Code[20])
        {
            Caption = 'Normal VAT Prod. Posting Gr.';
            TableRelation = "VAT Product Posting Group";
        }
        field(14; "Reduced VAT Prod. Posting Gr."; Code[20])
        {
            Caption = 'Reduced VAT Prod. Posting Gr.';
            TableRelation = "VAT Product Posting Group";
        }
        field(15; "Zero VAT Prod. Posting Gr."; Code[20])
        {
            Caption = 'Zero VAT Prod. Posting Gr.';
            TableRelation = "VAT Product Posting Group";
        }
        field(16; "C2Graph Endpoint"; Text[250])
        {
            Caption = 'C2Graph Endpoint';
        }
        field(17; "Sales Quote No. Series"; Code[20])
        {
            Caption = 'Sales Quote No. Series';
            TableRelation = "No. Series";
        }
        field(18; "Engage Endpoint"; Text[250])
        {
            Caption = 'Engage Endpoint';
        }
        field(19; "Coupons Integration Enabled"; Boolean)
        {
            Caption = 'Coupons Integration Enabled';
        }
        field(20; "Graph Enablement Reminder"; Boolean)
        {
            Caption = 'Graph Enablement Reminder';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure IsUsingSalesTax(): Boolean
    begin
        if Get then;
        exit("Tax Type" = "Tax Type"::"Sales Tax");
    end;

    procedure IsUsingVAT(): Boolean
    begin
        if Get then;
        exit("Tax Type" = "Tax Type"::VAT);
    end;

    procedure UpdateDefaultPaymentTerms(PaymentTermsCode: Code[10])
    var
        Customer: Record Customer;
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        PaymentTerms: Record "Payment Terms";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        if not O365SalesInitialSetup.Get then
            O365SalesInitialSetup.Insert(true);

        ConfigTemplateManagement.ReplaceDefaultValueForAllTemplates(
          DATABASE::Customer, Customer.FieldNo("Payment Terms Code"), PaymentTermsCode);
        O365SalesInitialSetup."Default Payment Terms Code" := PaymentTermsCode;
        O365SalesInitialSetup.Modify(true);

        // Update last modified date time, so users of web services can pick up an update
        if PaymentTerms.Get(PaymentTermsCode) then begin
            PaymentTerms."Last Modified Date Time" := CurrentDateTime;
            PaymentTerms.Modify(true);
        end;
    end;

    procedure UpdateDefaultPaymentMethod(PaymentMethodCode: Code[10])
    var
        PaymentMethod: Record "Payment Method";
    begin
        if PaymentMethod.Get(PaymentMethodCode) then
            UpdateDefaultPaymentMethodFromRec(PaymentMethod);
    end;

    procedure UpdateDefaultPaymentMethodFromRec(var PaymentMethod: Record "Payment Method")
    var
        Customer: Record Customer;
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        LocalPaymentMethod: Record "Payment Method";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        if not O365SalesInitialSetup.Get then
            O365SalesInitialSetup.Insert(true);

        ConfigTemplateManagement.ReplaceDefaultValueForAllTemplates(
          DATABASE::Customer, Customer.FieldNo("Payment Method Code"), PaymentMethod.Code);
        O365SalesInitialSetup."Default Payment Method Code" := PaymentMethod.Code;
        O365SalesInitialSetup.Modify(true);

        // Update last modified date time, so users of web services can pick up an update
        if LocalPaymentMethod.Get(PaymentMethod.Code) then begin // Do only if the record still/already exists
            PaymentMethod."Last Modified Date Time" := CurrentDateTime;
            PaymentMethod.Modify(true);
        end;
    end;

    procedure IsDefaultPaymentMethod(var PaymentMethod: Record "Payment Method"): Boolean
    begin
        if not Get then
            Insert(true);

        exit("Default Payment Method Code" = PaymentMethod.Code);
    end;

    procedure IsDefaultPaymentTerms(var PaymentTerms: Record "Payment Terms"): Boolean
    begin
        if not Get then
            Insert(true);

        exit("Default Payment Terms Code" = PaymentTerms.Code);
    end;
}

