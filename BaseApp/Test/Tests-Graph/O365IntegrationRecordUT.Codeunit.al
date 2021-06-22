codeunit 139319 "O365 Integration Record UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Integration Record] [Integration Management]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure EntityTablesAreNotEmpty()
    begin
        // this test must run in O365 buckets only and because it verifies demo data of O365 copmany
        VerifySalesQuoteEntityTable;
        VerifySalesInvoiceEntityTable;
        VerifySalesOrderEntityTable;
        VerifyPurchaseInvoiceEntityTable;
    end;

    local procedure VerifySalesQuoteEntityTable()
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SalesHeader: Record "Sales Header";
        IntegrationRecord: Record "Integration Record";
    begin
        SalesQuoteEntityBuffer.SetRange("Document Type", SalesQuoteEntityBuffer."Document Type"::Quote);
        SalesQuoteEntityBuffer.FindSet;
        repeat
            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
            SalesHeader.SetRange("No.", SalesQuoteEntityBuffer."No.");
            SalesHeader.SetRange(Id, SalesQuoteEntityBuffer.Id);
            Assert.RecordIsNotEmpty(SalesHeader);

            IntegrationRecord.Get(SalesQuoteEntityBuffer.Id);
            IntegrationRecord.TestField("Table ID", DATABASE::"Sales Header");
        until SalesQuoteEntityBuffer.Next = 0;
    end;

    local procedure VerifySalesInvoiceEntityTable()
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesHeader: Record "Sales Header";
        IntegrationRecord: Record "Integration Record";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindSet;
        repeat
            SalesInvoiceEntityAggregate.SetRange("Document Type", SalesInvoiceEntityAggregate."Document Type"::Invoice);
            SalesInvoiceEntityAggregate.SetRange("No.", SalesHeader."No.");
            SalesInvoiceEntityAggregate.SetRange(Id, SalesHeader.Id);
            Assert.RecordIsNotEmpty(SalesInvoiceEntityAggregate);

            IntegrationRecord.Get(SalesHeader.Id);
            IntegrationRecord.TestField("Table ID", DATABASE::"Sales Header");
        until SalesHeader.Next = 0;
    end;

    local procedure VerifySalesOrderEntityTable()
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SalesHeader: Record "Sales Header";
        IntegrationRecord: Record "Integration Record";
    begin
        SalesOrderEntityBuffer.FindSet;
        repeat
            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
            SalesHeader.SetRange("No.", SalesOrderEntityBuffer."No.");
            SalesHeader.SetRange(Id, SalesOrderEntityBuffer.Id);
            Assert.RecordIsNotEmpty(SalesHeader);

            IntegrationRecord.Get(SalesOrderEntityBuffer.Id);
            IntegrationRecord.TestField("Table ID", DATABASE::"Sales Header");
        until SalesOrderEntityBuffer.Next = 0;
    end;

    local procedure VerifyPurchaseInvoiceEntityTable()
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchaseHeader: Record "Purchase Header";
        IntegrationRecord: Record "Integration Record";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.FindSet;
        repeat
            PurchInvEntityAggregate.SetRange("Document Type", PurchInvEntityAggregate."Document Type"::Invoice);
            PurchInvEntityAggregate.SetRange("No.", PurchaseHeader."No.");
            PurchInvEntityAggregate.SetRange(Id, PurchaseHeader.Id);
            Assert.RecordIsNotEmpty(PurchInvEntityAggregate);

            IntegrationRecord.Get(PurchaseHeader.Id);
            IntegrationRecord.TestField("Table ID", DATABASE::"Purchase Header");
        until PurchaseHeader.Next = 0;
    end;
}

