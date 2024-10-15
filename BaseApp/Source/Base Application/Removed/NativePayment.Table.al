table 2831 "Native - Payment"
{
    Caption = 'Native - Payment';
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'These objects will be removed';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Ledger Entry No."; Integer)
        {
            Caption = 'Ledger Entry No.';
        }
        field(2; "Payment No."; Integer)
        {
            Caption = 'Payment No.';
        }
        field(3; "Customer Id"; Guid)
        {
            Caption = 'Customer Id';
            TableRelation = Customer.SystemId;

            trigger OnValidate()
            var
                Customer: Record Customer;
            begin
                if Customer.GetBySystemId("Customer Id") then
                    "Customer No." := Customer."No.";
            end;
        }
        field(4; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            var
                Customer: Record Customer;
            begin
                if Customer.Get("Customer No.") then
                    "Customer Id" := Customer.SystemId;
            end;
        }
        field(5; "Payment Date"; Date)
        {
            Caption = 'Payment Date';
        }
        field(6; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(7; "Applies-to Invoice Id"; Guid)
        {
            Caption = 'Applies-to Invoice Id';

            trigger OnValidate()
            var
                SalesInvoiceHeader: Record "Sales Invoice Header";
            begin
                if not SalesInvoiceHeader.GetBySystemId("Applies-to Invoice Id") then
                    exit;

                "Applies-to Invoice No." := SalesInvoiceHeader."No.";

                if "Customer No." = '' then
                    if SalesInvoiceHeader."Bill-to Customer No." <> '' then
                        "Customer No." := SalesInvoiceHeader."Bill-to Customer No."
                    else
                        "Customer No." := SalesInvoiceHeader."Sell-to Customer No.";
            end;
        }
        field(8; "Applies-to Invoice No."; Code[20])
        {
            Caption = 'Applies-to Invoice No.';

            trigger OnValidate()
            var
                SalesInvoiceHeader: Record "Sales Invoice Header";
                SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
            begin
                if SalesInvoiceHeader.Get("Applies-to Invoice No.") then
                    "Applies-to Invoice Id" := SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader);
            end;
        }
        field(9; "Payment Method Id"; Guid)
        {
            Caption = 'Payment Method Id';

            trigger OnValidate()
            var
                PaymentMethod: Record "Payment Method";
            begin
                if PaymentMethod.GetBySystemId("Payment Method Id") then
                    "Payment Method Code" := PaymentMethod.Code;
            end;
        }
        field(10; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';

            trigger OnValidate()
            var
                PaymentMethod: Record "Payment Method";
            begin
                if PaymentMethod.Get("Payment Method Code") then
                    "Payment Method Id" := PaymentMethod.SystemId;
            end;
        }
    }

    keys
    {
        key(Key1; "Applies-to Invoice Id", "Payment No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

