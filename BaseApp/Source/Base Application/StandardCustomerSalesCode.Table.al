﻿table 172 "Standard Customer Sales Code"
{
    Caption = 'Standard Customer Sales Code';

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            NotBlank = true;
            TableRelation = Customer;
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = "Standard Sales Code";

            trigger OnValidate()
            var
                StdSalesCode: Record "Standard Sales Code";
            begin
                if Code = '' then
                    exit;
                StdSalesCode.Get(Code);
                Description := StdSalesCode.Description;
                "Currency Code" := StdSalesCode."Currency Code";
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Valid From Date"; Date)
        {
            Caption = 'Valid From Date';
        }
        field(5; "Valid To date"; Date)
        {
            Caption = 'Valid To date';
        }
        field(6; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(7; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(8; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" WHERE("Customer No." = FIELD("Customer No."),
                                                               Blocked = CONST(false),
                                                               Closed = CONST(false));
        }
        field(9; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(13; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(15; "Insert Rec. Lines On Quotes"; Option)
        {
            Caption = 'Insert Rec. Lines On Quotes';
            DataClassification = SystemMetadata;
            OptionCaption = 'Manual,Automatic,Always Ask';
            OptionMembers = Manual,Automatic,"Always Ask";
        }
        field(16; "Insert Rec. Lines On Orders"; Option)
        {
            Caption = 'Insert Rec. Lines On Orders';
            DataClassification = SystemMetadata;
            OptionCaption = 'Manual,Automatic,Always Ask';
            OptionMembers = Manual,Automatic,"Always Ask";
        }
        field(17; "Insert Rec. Lines On Invoices"; Option)
        {
            Caption = 'Insert Rec. Lines On Invoices';
            DataClassification = SystemMetadata;
            OptionCaption = 'Manual,Automatic,Always Ask';
            OptionMembers = Manual,Automatic,"Always Ask";
        }
        field(18; "Insert Rec. Lines On Cr. Memos"; Option)
        {
            Caption = 'Insert Rec. Lines On Cr. Memos';
            DataClassification = SystemMetadata;
            OptionCaption = 'Manual,Automatic,Always Ask';
            OptionMembers = Manual,Automatic,"Always Ask";
        }
    }

    keys
    {
        key(Key1; "Customer No.", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnRename()
    begin
        Error(RenameErr);
    end;

    var
        RenameErr: Label 'You cannot rename the line.';

    procedure CreateSalesInvoice(OrderDate: Date; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        TestField(Blocked, false);
        SalesHeader.Init();
        SalesHeader."No." := '';
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        OnCreateSalesInvoiceOnBeforeSalesHeaderInsert(SalesHeader, Rec);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", "Customer No.");
        SalesHeader.Validate("Order Date", OrderDate);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Document Date", OrderDate);
        if "Payment Method Code" <> '' then
            SalesHeader.Validate("Payment Method Code", "Payment Method Code");
        if "Payment Terms Code" <> '' then
            SalesHeader.Validate("Payment Terms Code", "Payment Terms Code");
        if "Direct Debit Mandate ID" <> '' then
            SalesHeader.Validate("Direct Debit Mandate ID", "Direct Debit Mandate ID");
        OnCreateSalesInvoiceOnBeforeSalesHeaderModify(SalesHeader, Rec);
        SalesHeader.Modify();
        ApplyStdCodesToSalesLines(SalesHeader, Rec);

        OnAfterCreateSalesInvoice(SalesHeader, Rec);
    end;

    procedure InsertSalesLines(var SalesHeader: Record "Sales Header")
    var
        StdCustSalesCode: Record "Standard Customer Sales Code";
        StdCustSalesCodes: Page "Standard Customer Sales Codes";
    begin
        SalesHeader.TestField("No.");
        SalesHeader.TestField("Sell-to Customer No.");

        StdCustSalesCode.FilterGroup := 2;
        StdCustSalesCode.SetRange("Customer No.", SalesHeader."Sell-to Customer No.");
        StdCustSalesCode.FilterGroup := 0;

        OnBeforeStdCustSalesCodesSetTableView(StdCustSalesCode, SalesHeader);
        StdCustSalesCodes.SetTableView(StdCustSalesCode);
        StdCustSalesCodes.LookupMode(true);
        if StdCustSalesCodes.RunModal = ACTION::LookupOK then begin
            StdCustSalesCodes.GetSelected(StdCustSalesCode);
            if StdCustSalesCode.FindSet then
                repeat
                    ApplyStdCodesToSalesLines(SalesHeader, StdCustSalesCode);
                until StdCustSalesCode.Next = 0;
        end;
    end;

    procedure ApplyStdCodesToSalesLines(var SalesHeader: Record "Sales Header"; StdCustSalesCode: Record "Standard Customer Sales Code")
    var
        Currency: Record Currency;
        StdSalesLine: Record "Standard Sales Line";
        StdSalesCode: Record "Standard Sales Code";
        SalesLine: Record "Sales Line";
        Factor: Integer;
    begin
        Currency.Initialize(SalesHeader."Currency Code");

        StdCustSalesCode.TestField(Code);
        StdCustSalesCode.TestField("Customer No.", SalesHeader."Sell-to Customer No.");
        StdSalesCode.Get(StdCustSalesCode.Code);
        StdSalesCode.TestField("Currency Code", SalesHeader."Currency Code");
        StdSalesLine.SetRange("Standard Sales Code", StdCustSalesCode.Code);
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesHeader."Prices Including VAT" then
            Factor := 1
        else
            Factor := 0;

        OnBeforeApplyStdCodesToSalesLinesLoop(StdSalesLine, SalesLine, SalesHeader, StdSalesCode);

        SalesLine.LockTable();
        StdSalesLine.LockTable();
        if StdSalesLine.Find('-') then
            repeat
                SalesLine.Init();
                SalesLine.SetSalesHeader(SalesHeader);
                SalesLine."Line No." := 0;
                SalesLine.Validate(Type, StdSalesLine.Type);
                if StdSalesLine.Type = StdSalesLine.Type::" " then begin
                    SalesLine.Validate("No.", StdSalesLine."No.");
                    SalesLine.Description := StdSalesLine.Description;
                    SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                end else
                    if not StdSalesLine.EmptyLine then begin
                        StdSalesLine.TestField("No.");
                        SalesLine.Validate("No.", StdSalesLine."No.");
                        if StdSalesLine."Variant Code" <> '' then
                            SalesLine.Validate("Variant Code", StdSalesLine."Variant Code");
                        SalesLine.Validate(Quantity, StdSalesLine.Quantity);
                        if StdSalesLine."Unit of Measure Code" <> '' then
                            SalesLine.Validate("Unit of Measure Code", StdSalesLine."Unit of Measure Code");
                        if StdSalesLine.Description <> '' then
                            SalesLine.Validate(Description, StdSalesLine.Description);
                        if (StdSalesLine.Type = StdSalesLine.Type::"G/L Account") or
                           (StdSalesLine.Type = StdSalesLine.Type::"Charge (Item)")
                        then
                            SalesLine.Validate(
                              "Unit Price",
                              Round(StdSalesLine."Amount Excl. VAT" *
                                (SalesLine."VAT %" / 100 * Factor + 1), Currency."Unit-Amount Rounding Precision"));
                    end;

                SalesLine."Shortcut Dimension 1 Code" := StdSalesLine."Shortcut Dimension 1 Code";
                SalesLine."Shortcut Dimension 2 Code" := StdSalesLine."Shortcut Dimension 2 Code";

                CombineDimensions(SalesLine, StdSalesLine);
                OnBeforeApplyStdCodesToSalesLines(SalesLine, StdSalesLine);
                if StdSalesLine.InsertLine then begin
                    SalesLine."Line No." := GetNextLineNo(SalesLine);
                    SalesLine.Insert(true);
                    SalesLine.AutoAsmToOrder;
                    InsertExtendedText(SalesLine, SalesHeader);
                end;
            until StdSalesLine.Next = 0;

        OnAfterApplyStdCodesToSalesLinesLoop(StdSalesLine, SalesLine, SalesHeader, StdSalesCode);
    end;

    local procedure CombineDimensions(var SalesLine: Record "Sales Line"; StdSalesLine: Record "Standard Sales Line")
    var
        DimensionManagement: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
    begin
        DimensionSetIDArr[1] := SalesLine."Dimension Set ID";
        DimensionSetIDArr[2] := StdSalesLine."Dimension Set ID";

        SalesLine."Dimension Set ID" :=
          DimensionManagement.GetCombinedDimensionSetID(
            DimensionSetIDArr, SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
    end;

    procedure InsertExtendedText(SalesLine: Record "Sales Line")
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        if SalesLine.Type = SalesLine.Type::" " then
            exit;
        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false) then
            TransferExtendedText.InsertSalesExtText(SalesLine);
    end;

    procedure InsertExtendedText(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false, SalesHeader) then
            TransferExtendedText.InsertSalesExtText(SalesLine);
    end;

    procedure GetNextLineNo(SalesLine: Record "Sales Line"): Integer
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        if SalesLine.FindLast then
            exit(SalesLine."Line No." + 10000);

        exit(10000);
    end;

    procedure SetFilterByAutomaticAndAlwaysAskCodes(SalesHeader: Record "Sales Header")
    begin
        SetRange("Customer No.", SalesHeader."Sell-to Customer No.");
        SetRange("Currency Code", SalesHeader."Currency Code");
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Quote:
                SetFilter("Insert Rec. Lines On Quotes", '<>%1', "Insert Rec. Lines On Quotes"::Manual);
            SalesHeader."Document Type"::Order:
                SetFilter("Insert Rec. Lines On Orders", '<>%1', "Insert Rec. Lines On Orders"::Manual);
            SalesHeader."Document Type"::Invoice:
                SetFilter("Insert Rec. Lines On Invoices", '<>%1', "Insert Rec. Lines On Invoices"::Manual);
            SalesHeader."Document Type"::"Credit Memo":
                SetFilter("Insert Rec. Lines On Cr. Memos", '<>%1', "Insert Rec. Lines On Cr. Memos"::Manual);
        end;
    end;

    procedure IsInsertRecurringLinesOnDocumentAutomatic(SalesHeader: Record "Sales Header"): Boolean
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Quote:
                exit("Insert Rec. Lines On Quotes" = "Insert Rec. Lines On Quotes"::Automatic);
            SalesHeader."Document Type"::Order:
                exit("Insert Rec. Lines On Orders" = "Insert Rec. Lines On Orders"::Automatic);
            SalesHeader."Document Type"::Invoice:
                exit("Insert Rec. Lines On Invoices" = "Insert Rec. Lines On Invoices"::Automatic);
            SalesHeader."Document Type"::"Credit Memo":
                exit("Insert Rec. Lines On Cr. Memos" = "Insert Rec. Lines On Cr. Memos"::Automatic);
            else
                exit(false);
        end;
    end;

    procedure ShouldAutoInsertRecurringLinesOnDocument(SalesHeader: Record "Sales Header"): Boolean
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Quote:
                exit("Insert Rec. Lines On Quotes" <> "Insert Rec. Lines On Quotes"::Manual);
            SalesHeader."Document Type"::Order:
                exit("Insert Rec. Lines On Orders" <> "Insert Rec. Lines On Orders"::Manual);
            SalesHeader."Document Type"::Invoice:
                exit("Insert Rec. Lines On Invoices" <> "Insert Rec. Lines On Invoices"::Manual);
            SalesHeader."Document Type"::"Credit Memo":
                exit("Insert Rec. Lines On Cr. Memos" <> "Insert Rec. Lines On Cr. Memos"::Manual);
            else
                exit(false);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesInvoice(var SalesHeader: Record "Sales Header"; StandardCustomerSalesCode: Record "Standard Customer Sales Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyStdCodesToSalesLinesLoop(var StdSalesLine: Record "Standard Sales Line"; var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; StdSalesCode: Record "Standard Sales Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyStdCodesToSalesLines(var SalesLine: Record "Sales Line"; StdSalesLine: Record "Standard Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyStdCodesToSalesLinesLoop(var StdSalesLine: Record "Standard Sales Line"; var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; StdSalesCode: Record "Standard Sales Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStdCustSalesCodesSetTableView(var StandardCustomerSalesCode: Record "Standard Customer Sales Code"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceOnBeforeSalesHeaderInsert(var SalesHeader: Record "Sales Header"; StandardCustomerSalesCode: Record "Standard Customer Sales Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceOnBeforeSalesHeaderModify(var SalesHeader: Record "Sales Header"; StandardCustomerSalesCode: Record "Standard Customer Sales Code")
    begin
    end;
}

