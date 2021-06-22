codeunit 130640 "Library - Graph Mock"
{

    trigger OnRun()
    var
        ExchangeContactMock: Record ExchangeContactMock;
        MarketingSetup: Record "Marketing Setup";
    begin
        ClearMockTables;
        RemoveComplexTypes;
        RegisterComplexTypes;
        ExchangeContactMock.DeleteAll;

        MarketingSetup.Get;
        MarketingSetup."Sync with Microsoft Graph" := true;
        MarketingSetup.Modify;
    end;

    [Scope('OnPrem')]
    procedure GetGetCount() "Count": Integer
    var
        ODataTestMetrics: Record "OData Test Metrics";
    begin
        EnsureRecordsCreated;
        ODataTestMetrics.Get;
        Count := ODataTestMetrics.GetCount
    end;

    [Scope('OnPrem')]
    procedure IncrementGetCount()
    var
        ODataTestMetrics: Record "OData Test Metrics";
    begin
        EnsureRecordsCreated;
        ODataTestMetrics.Get;
        ODataTestMetrics.GetCount += 1;
        ODataTestMetrics.Modify;
    end;

    [Scope('OnPrem')]
    procedure GetInsertCount() "Count": Integer
    var
        ODataTestMetrics: Record "OData Test Metrics";
    begin
        EnsureRecordsCreated;
        ODataTestMetrics.Get;
        Count := ODataTestMetrics.InsertCount
    end;

    [Scope('OnPrem')]
    procedure IncrementInsertCount()
    var
        ODataTestMetrics: Record "OData Test Metrics";
    begin
        EnsureRecordsCreated;
        ODataTestMetrics.Get;
        ODataTestMetrics.InsertCount += 1;
        ODataTestMetrics.Modify;
    end;

    [Scope('OnPrem')]
    procedure GetDeleteCount() "Count": Integer
    var
        ODataTestMetrics: Record "OData Test Metrics";
    begin
        EnsureRecordsCreated;
        ODataTestMetrics.Get;
        Count := ODataTestMetrics.DeleteCount
    end;

    [Scope('OnPrem')]
    procedure IncrementDeleteCount()
    var
        ODataTestMetrics: Record "OData Test Metrics";
    begin
        EnsureRecordsCreated;
        ODataTestMetrics.Get;
        ODataTestMetrics.DeleteCount += 1;
        ODataTestMetrics.Modify;
    end;

    [Scope('OnPrem')]
    procedure GetModifyCount() "Count": Integer
    var
        ODataTestMetrics: Record "OData Test Metrics";
    begin
        EnsureRecordsCreated;
        ODataTestMetrics.Get;
        Count := ODataTestMetrics.ModifyCount
    end;

    [Scope('OnPrem')]
    procedure IncrementModifyCount()
    var
        ODataTestMetrics: Record "OData Test Metrics";
    begin
        EnsureRecordsCreated;
        ODataTestMetrics.Get;
        ODataTestMetrics.ModifyCount += 1;
        ODataTestMetrics.Modify;
    end;

    [Scope('OnPrem')]
    procedure GetWebhooksCount() "Count": Integer
    var
        WebhookTestMetrics: Record "Webhook Test Metrics";
    begin
        EnsureRecordsCreated;
        WebhookTestMetrics.Get;
        Count := WebhookTestMetrics.CreatedCount;
    end;

    [Scope('OnPrem')]
    procedure ResetCounters()
    var
        ODataTestMetrics: Record "OData Test Metrics";
        WebhookTestMetrics: Record "Webhook Test Metrics";
    begin
        ODataTestMetrics.DeleteAll(true);
        WebhookTestMetrics.DeleteAll(true);
        EnsureRecordsCreated;
    end;

    local procedure ClearMockTables()
    var
        ExchangeContactMock: Record ExchangeContactMock;
    begin
        ExchangeContactMock.DeleteAll(true);
        ResetCounters;
    end;

    local procedure EnsureRecordsCreated()
    var
        ODataTestMetrics: Record "OData Test Metrics";
        WebhookTestMetrics: Record "Webhook Test Metrics";
    begin
        if ODataTestMetrics.IsEmpty then begin
            ODataTestMetrics.Init;
            ODataTestMetrics.Insert(true);
            Commit;
        end;

        if WebhookTestMetrics.IsEmpty then begin
            WebhookTestMetrics.Init;
            WebhookTestMetrics.Insert(true);
            Commit;
        end;
    end;

    [Scope('OnPrem')]
    procedure RegisterComplexTypes()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        // Nullable MUST be defined on each property. The value doesn't matter, but it must be present.
        GraphMgtGeneralTools.InsertOrUpdateODataType('OutlookEmailAddress', 'EmailAddress - Outlook Mock',
          '<ComplexType Name="OutlookEmailAddress">' +
          '  <Property Name="Name" Type="Edm.String" Nullable="True" />' +
          '  <Property Name="Address" Type="Edm.String" Nullable="True" />' +
          '</ComplexType>');

        GraphMgtGeneralTools.InsertOrUpdateODataType('OutlookPhysicalAddress', 'PhysicalAddress - Outlook Mock',
          '<ComplexType Name="OutlookPhysicalAddress">' +
          '  <Property Name="Type" Type="Edm.String" Nullable="True" />' +
          '  <Property Name="Street" Type="Edm.String" Nullable="True" />' +
          '  <Property Name="City" Type="Edm.String" Nullable="True" />' +
          '  <Property Name="State" Type="Edm.String" Nullable="True" />' +
          '  <Property Name="CountryOrRegion" Type="Edm.String" Nullable="True" />' +
          '  <Property Name="PostalCode" Type="Edm.String" Nullable="True" />' +
          '</ComplexType>');

        GraphMgtGeneralTools.InsertOrUpdateODataType('SingleValueExtProp', 'Single Value Extended Property - Extended Property Mock',
          '<ComplexType Name="SingleValueLegacyExtendedProperty">' +
          '  <Property Name="Value" Type="Edm.String" Nullable="True" />' +
          '  <Property Name="PropertyId" Type="Edm.String" Nullable="True" />' +
          '</ComplexType>');

        GraphMgtGeneralTools.InsertOrUpdateODataType('OutlookPhone', 'Phone Number - Property Mock',
          '<ComplexType Name="OutlookPhone">' +
          '  <Property Name="Type" Type="Edm.String" Nullable="True" />' +
          '  <Property Name="Number" Type="Edm.String" Nullable="True" />' +
          '</ComplexType>');

        GraphMgtGeneralTools.InsertOrUpdateODataType('OutlookWebsite', 'Website - Property Mock',
          '<ComplexType Name="OutlookWebsite">' +
          '  <Property Name="Type" Type="Edm.String" Nullable="True" />' +
          '  <Property Name="Address" Type="Edm.String" Nullable="True" />' +
          '  <Property Name="DisplayName" Type="Edm.String" Nullable="True" />' +
          '  <Property Name="Name" Type="Edm.String" Nullable="True" />' +
          '</ComplexType>');
    end;

    local procedure RemoveComplexTypes()
    var
        ODataEdmType: Record "OData Edm Type";
    begin
        if ODataEdmType.Get('OutlookEmailAddress') then
            ODataEdmType.Delete;
        if ODataEdmType.Get('OutlookPhysicalAddress') then
            ODataEdmType.Delete;
        if ODataEdmType.Get('SingleValueExtProp') then
            ODataEdmType.Delete;
        if ODataEdmType.Get('OutlookPhone') then
            ODataEdmType.Delete;
        if ODataEdmType.Get('OutlookWebsite') then
            ODataEdmType.Delete;
    end;

    [Scope('OnPrem')]
    procedure SendContactUpdateWebhook(var ExchangeContactMock: Record ExchangeContactMock)
    var
        WebhookTestMetrics: Record "Webhook Test Metrics";
        LibraryGraphSync: Codeunit "Library - Graph Sync";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        EnsureRecordsCreated;
        LibraryGraphSync.MockIncomingContactIdAsync(ExchangeContactMock.Id, GraphWebhookSyncToNAV.GetGraphSubscriptionUpdatedChangeType);
        WebhookTestMetrics.FindLast;
        WebhookTestMetrics.UpdatedCount += 1;
        WebhookTestMetrics.Modify(true);
        Commit;
    end;

    [Scope('OnPrem')]
    procedure SendContactInsertWebhook(var ExchangeContactMock: Record ExchangeContactMock)
    var
        WebhookTestMetrics: Record "Webhook Test Metrics";
        LibraryGraphSync: Codeunit "Library - Graph Sync";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        EnsureRecordsCreated;
        LibraryGraphSync.MockIncomingContactIdAsync(ExchangeContactMock.Id, GraphWebhookSyncToNAV.GetGraphSubscriptionCreatedChangeType);
        WebhookTestMetrics.FindLast;
        WebhookTestMetrics.CreatedCount += 1;
        WebhookTestMetrics.Modify(true);
        Commit;
    end;

    [Scope('OnPrem')]
    procedure SendContactDeleteWebhook(var ExchangeContactMock: Record ExchangeContactMock)
    var
        WebhookTestMetrics: Record "Webhook Test Metrics";
        LibraryGraphSync: Codeunit "Library - Graph Sync";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        EnsureRecordsCreated;
        LibraryGraphSync.MockIncomingContactId(ExchangeContactMock.Id, GraphWebhookSyncToNAV.GetGraphSubscriptionDeletedChangeType);
        WebhookTestMetrics.FindLast;
        WebhookTestMetrics.DeletedCount += 1;
        WebhookTestMetrics.Modify(true);
        Commit;
    end;

    [Scope('OnPrem')]
    procedure SendContactMissedWebhook(var ExchangeContactMock: Record ExchangeContactMock)
    var
        WebhookTestMetrics: Record "Webhook Test Metrics";
        LibraryGraphSync: Codeunit "Library - Graph Sync";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        EnsureRecordsCreated;
        LibraryGraphSync.MockIncomingContactIdAsync(ExchangeContactMock.Id, GraphWebhookSyncToNAV.GetGraphSubscriptionMissedChangeType);
        WebhookTestMetrics.FindLast;
        WebhookTestMetrics.MissedCount += 1;
        WebhookTestMetrics.Modify(true);
        Commit;
    end;
}

