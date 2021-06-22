codeunit 135970 "Integration Record Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Test Integration Record to System ID Upgrade]
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateIntegrationRecordIdMatchesSystemID()
    var
        IntegrationRecord: Record "Integration Record";
        IntegrationManagement: Codeunit "Integration Management";
        MissmatchingIntegrationRecords: Record "Integration Record" temporary;
        Assert: Codeunit "Library Assert";
        UpgradeStatus: Codeunit "Upgrade Status";
        BlankRecordId: RecordId;
    begin
        IntegrationRecord.SetFilter("Record ID", '<>%1', BlankRecordId);

        if not IntegrationManagement.GetIntegrationIsEnabledOnTheSystem() then
            exit;

        Assert.IsTrue(IntegrationRecord.FindSet(), 'Integration records must be present');
        repeat
            VerifyIntegrationRecord(IntegrationRecord, MissmatchingIntegrationRecords);
        until IntegrationRecord.next() = 0;

        Assert.AreEqual(0, MissmatchingIntegrationRecords.Count, 'Integration records are not matchin the SystemId');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateSalesInvoiceBufferTable()
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        Assert: Codeunit "Library Assert";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InvoiceFound: Boolean;
    begin
        Assert.IsTrue(SalesInvoiceEntityAggregate.FindSet(), 'Records should be present');
        repeat
            if (not SalesInvoiceEntityAggregate.Posted) then
                Assert.IsTrue(SalesHeader.GetBySystemId(SalesInvoiceEntityAggregate.Id), 'Could not find the Draft Invoice')
            else begin
                SalesInvoiceHeader.SetRange("Draft Invoice SystemId", SalesInvoiceEntityAggregate.Id);
                InvoiceFound := SalesInvoiceHeader.FindFirst();
                if not InvoiceFound then begin
                    SalesInvoiceHeader.SetRange("Draft Invoice SystemId");
                    InvoiceFound := SalesInvoiceHeader.GetBySystemId(SalesInvoiceEntityAggregate.Id);
                end;

                Assert.IsTrue(InvoiceFound, 'Could not find the invoice for the given ID')
            end;
        until SalesInvoiceEntityAggregate.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseInvoiceBufferTable()
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        Assert: Codeunit "Library Assert";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        InvoiceFound: Boolean;
    begin
        Assert.IsTrue(PurchInvEntityAggregate.FindSet(), 'Records should be present');
        repeat
            if (not PurchInvEntityAggregate.Posted) then
                Assert.IsTrue(PurchaseHeader.GetBySystemId(PurchInvEntityAggregate.Id), 'Could not find the Draft Invoice')
            else begin
                PurchInvHeader.SetRange("Draft Invoice SystemId", PurchInvEntityAggregate.Id);
                InvoiceFound := PurchInvHeader.FindFirst();
                if not InvoiceFound then begin
                    PurchInvHeader.SetRange("Draft Invoice SystemId");
                    InvoiceFound := PurchInvHeader.GetBySystemId(PurchInvEntityAggregate.Id);
                end;

                Assert.IsTrue(InvoiceFound, 'Could not find the invoice for the given ID')
            end;
        until PurchInvEntityAggregate.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCrMemoBufferTable()
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        Assert: Codeunit "Library Assert";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        InvoiceFound: Boolean;
    begin
        Assert.IsTrue(SalesCrMemoEntityBuffer.FindSet(), 'Records should be present');
        repeat
            if (not SalesCrMemoEntityBuffer.Posted) then
                Assert.IsTrue(SalesHeader.GetBySystemId(SalesCrMemoEntityBuffer.Id), 'Could not find the Draft Credit Memo')
            else begin
                SalesCrMemoHeader.SetRange("Draft Cr. Memo SystemId", SalesCrMemoEntityBuffer.Id);
                InvoiceFound := SalesCrMemoHeader.FindFirst();
                if not InvoiceFound then begin
                    SalesCrMemoHeader.SetRange("Draft Cr. Memo SystemId");
                    InvoiceFound := SalesCrMemoHeader.GetBySystemId(SalesCrMemoEntityBuffer.Id);
                end;

                Assert.IsTrue(InvoiceFound, 'Could not find the Credit Memo for the given ID')
            end;
        until SalesCrMemoEntityBuffer.Next() = 0;
    end;

    local procedure VerifyIntegrationRecord(IntegrationRecord: Record "Integration Record"; var MissmatchingIntegrationRecords: Record "Integration Record" temporary)
    var
        NonDuplicateIntegrationRecord: Record "Integration Record";
        Assert: Codeunit "Library Assert";
        SourceRecordRef: RecordRef;
        SystemFieldId: FieldRef;
        IDMatch: Boolean;
    begin
        Assert.IsTrue(SourceRecordRef.Get(IntegrationRecord."Record Id"), 'Could not find the integration record');
        IDMatch := FORMAT(IntegrationRecord."Integration ID") = FORMAT(SourceRecordRef.Field(SourceRecordRef.SystemIdNo).Value());
        if not IDMatch then
            if not NonDuplicateIntegrationRecord.GET(SourceRecordRef.Field(SourceRecordRef.SystemIdNo).Value()) then begin
                MissmatchingIntegrationRecords.TransferFields(IntegrationRecord, true);
                MissmatchingIntegrationRecords.Insert();
            end;
    end;
}