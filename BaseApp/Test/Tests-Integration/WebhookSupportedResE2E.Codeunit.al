codeunit 135546 "Webhook Supported Res. E2E"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [API] [Webhook]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        WebhookSupportedResourcesTxt: Label 'webhookSupportedResources', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetSupportedResourcesMany()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET returns many resources in the payload when webhook subscriptions are enabled
        // [GIVEN] webhookSupportedResources URI without filters
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Webhook Supported Resources", WebhookSupportedResourcesTxt);

        // [WHEN] User sends a GET request
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Response code is 200 and response body contains resources
        Assert.IsTrue(StrPos(ResponseText, '"resource":') > 0, 'Response does not contain resources');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetSupportedResourcesSingle()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET returns single resource in the payload when webhook subscriptions are enabled
        // [GIVEN] webhookSupportedResources URI for a single resource
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            '''beta/items''', PAGE::"Webhook Supported Resources", WebhookSupportedResourcesTxt);

        // [WHEN] User sends a GET request
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Response code is 200 and response body contains the specified resource
        Assert.IsTrue(StrPos(ResponseText, '"beta/items"') > 0, 'Resource "resource":"beta/items" is not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostSupportedResourcesNotAllowed()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] POST is not allowed for webhookSupportedResources
        // [GIVEN] webhookSupportedResources URI for a single resource
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Webhook Supported Resources", WebhookSupportedResourcesTxt);

        // [WHEN] User send a POST request
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '{"resource":"new"}', ResponseText, 405);

        // [THEN] Expecting response code 405
        Assert.ExpectedError('405 (MethodNotAllowed)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchSupportedResourcesNotAllowed()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] PATCH is not allowed for webhookSupportedResources
        // [GIVEN] webhookSupportedResources URI for a single resource
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            '''beta/items''', PAGE::"Webhook Supported Resources", WebhookSupportedResourcesTxt);

        // [WHEN] User send a PATCH request
        asserterror LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(TargetURL, '{"resource":"new"}', ResponseText, 405);

        // [THEN] Expecting response code 405
        Assert.ExpectedError('405 (MethodNotAllowed)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteSupportedResourcesNotAllowed()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] DELETE is not allowed for webhookSupportedResources
        // [GIVEN] webhookSupportedResources URI for a single resource
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            '''beta/items''', PAGE::"Webhook Supported Resources", WebhookSupportedResourcesTxt);

        // [WHEN] User send a DELETE request
        asserterror LibraryGraphMgt.DeleteFromWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 400);

        // [THEN] Expecting response code 400
        Assert.ExpectedError('400 (BadRequest)');
    end;
}

