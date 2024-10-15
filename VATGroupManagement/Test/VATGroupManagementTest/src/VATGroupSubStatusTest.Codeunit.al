codeunit 139743 "VAT Group Sub. Status Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";

    [Test]
    procedure TestQueryAPIEndpoint()
    var
        VATReportSetup: Record "VAT Report Setup";
        TargetURL: Text;
        ResponseText: Text;
        JsonResponse: JsonObject;
        ValueJsonToken: JsonToken;
    begin
        // [SCENARIO] Test that the Query API endpoint is returning the right values

        // [GIVEN] Tables that are populated only with test values 
        InitVATTablesAPIEndpoint();
        // [GIVEN] The VAT Group Role setup to Representative (otherwise the API Query will not return results)
        ChangeVATGroupRole(VATReportSetup."VAT Group Role"::Representative);

        // [GIVEN]
        // The Query API endpoint with filters to get a specific value 
        TargetURL := LibraryGraphMgt.CreateQueryTargetURL(Query::"VAT Group Submission Status", '?$filter=no eq ''TEST_NO_1'' and groupMemberId eq 00000000-0000-0000-0000-000000000000&$select=no,status');

        // [WHEN] Calling the Query API endpoint
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The result should be no = TEST_NO_1 and status = Rejected
        JsonResponse.ReadFrom(ResponseText);
        JsonResponse.SelectToken('$.value[0].no', ValueJsonToken);
        Assert.AreEqual('TEST_NO_1', ValueJsonToken.AsValue().AsText(), 'no should be TEST_NO_1');
        JsonResponse.SelectToken('$.value[0].status', ValueJsonToken);
        Assert.AreEqual('Rejected', ValueJsonToken.AsValue().AsText(), 'status should be Rejected');

        // [GIVEN]
        // The Query API endpoint with filters to get a specific value
        TargetURL := LibraryGraphMgt.CreateQueryTargetURL(Query::"VAT Group Submission Status", '?$filter=no eq ''TEST_NO_2'' and groupMemberId eq 00000000-0000-0000-0000-000000000000&$select=no,status');

        // [WHEN] Calling the Query API endpoint
        ResponseText := '';
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The result should be no = TEST_NO_2 and status = Canceled
        JsonResponse.ReadFrom(ResponseText);
        JsonResponse.SelectToken('$.value[0].no', ValueJsonToken);
        Assert.AreEqual('TEST_NO_2', ValueJsonToken.AsValue().AsText(), 'no should be TEST_NO_2');
        JsonResponse.SelectToken('$.value[0].status', ValueJsonToken);
        Assert.AreEqual('Canceled', ValueJsonToken.AsValue().AsText(), 'status should be Canceled');

        // [GIVEN]
        // The Query API endpoint with filters to get a specific value
        TargetURL := LibraryGraphMgt.CreateQueryTargetURL(Query::"VAT Group Submission Status", '?$filter=no eq ''TEST_NO_3'' and groupMemberId eq 00000000-0000-0000-0000-000000000000&$select=no,status');

        // [WHEN] Calling the Query API endpoint
        ResponseText := '';
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The result should be empty (there is no field "No." with value VAT_CODE_5 in the table "VAT Report Header")
        JsonResponse.ReadFrom(ResponseText);
        Assert.AreEqual(false, JsonResponse.SelectToken('$.value[0]', ValueJsonToken), 'the json property value should be empty');

        // [GIVEN]
        // The Query API endpoint with filters to get a specific value
        TargetURL := LibraryGraphMgt.CreateQueryTargetURL(Query::"VAT Group Submission Status", '?$filter=no eq ''TEST_NO_4'' and groupMemberId eq 00000000-0000-0000-0000-000000000000&$select=no,status');

        // [WHEN] Calling the Query API endpoint
        ResponseText := '';
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The result should be empty (there is a field "No." with value VAT_CODE_6 in the table "VAT Report Header" but the "VAT Report Config. Code" is not "VAT Return")
        JsonResponse.ReadFrom(ResponseText);
        Assert.AreEqual(false, JsonResponse.SelectToken('$.value[0]', ValueJsonToken), 'the json property value should be empty');

        // [GIVEN]
        // The Query API endpoint with filters to get a specific value
        TargetURL := LibraryGraphMgt.CreateQueryTargetURL(Query::"VAT Group Submission Status", '?$filter=no eq ''TEST_NO_5'' and groupMemberId eq 00000000-0000-0000-0000-000000000000&$select=no,status');

        // [WHEN] Calling the Query API endpoint
        ResponseText := '';
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The result should be empty (there is no row with "No." = TEST_NO_5 and "Group Member Id" = 00000000-0000-0000-0000-000000000000 in the table "VAT Group Submission Header"
        JsonResponse.ReadFrom(ResponseText);
        Assert.AreEqual(false, JsonResponse.SelectToken('$.value[0]', ValueJsonToken), 'the json property value should be empty');

        // [GIVEN]
        // The Query API endpoint with filters to get a specific value
        TargetURL := LibraryGraphMgt.CreateQueryTargetURL(Query::"VAT Group Submission Status", '?$filter=no eq ''TEST_NO_5'' and groupMemberId eq 00000000-0000-0000-0000-000000000001&$select=no,status');

        // [WHEN] Calling the Query API endpoint
        ResponseText := '';
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The result should be no = TEST_NO_5 and status = Partially Accepted
        JsonResponse.ReadFrom(ResponseText);
        JsonResponse.SelectToken('$.value[0].no', ValueJsonToken);
        Assert.AreEqual('TEST_NO_5', ValueJsonToken.AsValue().AsText(), 'no should be TEST_NO_5');
        JsonResponse.SelectToken('$.value[0].status', ValueJsonToken);
        Assert.AreEqual('Submitted', ValueJsonToken.AsValue().AsText(), 'status should be Submitted');
    end;

    /* Disabled until we can provide an actual good error message
    [Test]
    procedure TestQueryAPIEndpointWithMemberInstallation()
    var
        VATReportHeader: Record "VAT Report Header";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        VATReportSetup: Record "VAT Report Setup";
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Test that the Query API endpoint returns error if the current VAT Group Role is Member (only the Representative can run the query)

        // [GIVEN] The VAT Group Role setup to Member
        ChangeVATGroupRole(VATReportSetup."VAT Group Role"::Member);

        // [GIVEN]
        // The Query API endpoint with filters to get a specific value 
        TargetURL := LibraryGraphMgt.CreateQueryTargetURL(Query::"VAT Group Submission Status", '?$filter=no eq ''TEST_NO_1'' and groupMemberId eq 00000000-0000-0000-0000-000000000000&$select=no,status');

        // [WHEN] Calling the Query API endpoint
        // [THEN] An error is expected from the API Query endpoint
        asserterror LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);
    end;
    */

    [Test]
    procedure TestVATGroupSubmissionStatusNoStatusToCheckBatchRequest()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATGroupSubmissionStatus: Codeunit "VAT Group Submission Status";
    begin
        // [SCENARIO] When there are no status to check the Codeunit "VAT Group Submission Status" exits without errors

        // [GIVEN] The table without the configuration for the endpoint
        VATReportSetup.DeleteAll();
        Commit();
        // [GIVEN] The "VAT Report Header" table populated only with rows that do not need to check the status 
        InitVATTablesNoStatusToCheck();

        // [WHEN] Calling the procedure UpdateAllVATReportStatus
        VATGroupSubmissionStatus.UpdateAllVATReportStatus();

        // [THEN] The Codeunit "VAT Group Submission Status" exits without errors (the endpoint is not configured so if it tries to call the URL a failure will occur)
    end;

    [Test]
    procedure TestVATGroupSubmissionStatusBatchRequest()
    var
        VATReportHeader: Record "VAT Report Header";
        VATGroupSubmissionStatus: Codeunit "VAT Group Submission Status";
    begin
        // [SCENARIO] Check that all the requests inside the batch are correctly executed and
        // that the status values are successfully updated

        // [GIVEN] Tables that are populated only with test values 
        InitVATReportSetupTable();
        InitVATTables();

        // [WHEN] Calling the procedure UpdateAllVATReportStatus
        VATGroupSubmissionStatus.UpdateAllVATReportStatus();

        // [THEN] All the values that need to be updated are successfully updated

        // "No.": MEMBER_CODE_1 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_1');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_1');
        Assert.AreEqual('Closed', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Closed for the row with No. = MEMBER_CODE_1');

        // "No.": MEMBER_CODE_2 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_2');
        Assert.AreEqual(VATReportHeader.Status::Accepted, VATReportHeader.Status, 'The field "Status" should be Accepted for the row with No. = MEMBER_CODE_2');
        Assert.AreEqual('Accepted', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Accepted for the row with No. = MEMBER_CODE_2');

        // "No.": MEMBER_CODE_3 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_3');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_3');
        Assert.AreEqual('Canceled', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Canceled for the row with No. = MEMBER_CODE_3');

        // "No.": MEMBER_CODE_4 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_4');
        Assert.AreEqual(VATReportHeader.Status::Rejected, VATReportHeader.Status, 'The field "Status" should be Rejected for the row with No. = MEMBER_CODE_4');
        Assert.AreEqual('Rejected', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Rejected for the row with No. = MEMBER_CODE_4');

        // "No.": MEMBER_CODE_5 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_5');
        Assert.AreEqual(VATReportHeader.Status::Rejected, VATReportHeader.Status, 'The field "Status" should be Rejected for the row with No. = MEMBER_CODE_5');
        Assert.AreEqual('Rejected', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Rejected for the row with No. = MEMBER_CODE_5');

        // "No.": MEMBER_CODE_6 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_6');
        Assert.AreEqual(VATReportHeader.Status::Rejected, VATReportHeader.Status, 'The field "Status" should be Rejected for the row with No. = MEMBER_CODE_6');
        Assert.AreEqual('Rejected', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Rejected for the row with No. = MEMBER_CODE_6');

        // "No.": MEMBER_CODE_7 - "Group Member Id": randomId (no match)
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_7');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_7');
        Assert.AreEqual('Pending', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Pending for the row with No. = MEMBER_CODE_7');

        // "No.": MEMBER_CODE_8 - "Group Member Id": 00000000-0000-0000-0000-000000000000 - no match because "VAT Report Config. Code" = "EC Sales List" in master (should be "VAT Return")
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_8');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_8');
        Assert.AreEqual('Pending', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Pending for the row with No. = MEMBER_CODE_8');

        // "No.": MEMBER_CODE_9 - "Group Member Id": 00000000-0000-0000-0000-000000000000 match with VAT_CODE_10 (not VAT_CODE_9 because this one has older date)
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_9');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_9');
        Assert.AreEqual('Canceled', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Canceled for the row with No. = MEMBER_CODE_9');
    end;

    [Test]
    procedure TestVATGroupSubmissionStatusWrongBatchEndpoint()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATGroupSubmissionStatus: Codeunit "VAT Group Submission Status";
        TmpURL: Text;
    begin
        // [SCENARIO] 

        // [GIVEN] Tables that are populated only with test values 
        InitVATReportSetupTable();
        InitVATTables();

        // [ GIVEN] A wrong batch URL
        TmpURL := LibraryGraphMgt.CreateQueryTargetURL(Query::"VAT Group Submission Status", '');
        VATReportSetup.FindFirst();
        VATReportSetup."Group Representative API URL" := CopyStr(TmpURL, 1, StrPos(TmpURL, 'NAV') - 1);
        VATReportSetup.Modify();
        Commit();

        // [WHEN] Calling the procedure UpdateAllVATReportStatus
        asserterror VATGroupSubmissionStatus.UpdateAllVATReportStatus();

        // [THEN] The error is handled by the codeunit, a specific message is returned
        Assert.ExpectedError('Not Found: cannot locate the requested resource.');
    end;


    [Test]
    procedure TestVATGroupSubmissionStatusErrorSingleGETRequestInBatch()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
        VATGroupSubmissionStatus: Codeunit "VAT Group Submission Status";
    begin
        // [GIVEN] Tables that are populated only with test values 
        InitVATReportSetupTable();
        InitVATTables();

        // [GIVEN] A wrong GET URL included in the batch request
        VATReportSetup.FindFirst();
        VATReportSetup."Group Representative Company" := 'ErrTestCompany';
        VATReportSetup.Modify();
        Commit();

        // [WHEN] Calling the procedure UpdateAllVATReportStatus
        VATGroupSubmissionStatus.UpdateAllVATReportStatus();

        // [THEN] All the Status are not updated because all the GET requests inside the batch are failing
        // but all the "VAT Group Status" should be "Cannot update"

        // "No.": MEMBER_CODE_1 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_1');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_1');
        Assert.AreEqual('Cannot update', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Cannot update for the row with No. = MEMBER_CODE_1');

        // "No.": MEMBER_CODE_2 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_2');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Accepted for the row with No. = MEMBER_CODE_2');
        Assert.AreEqual('Cannot update', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Cannot update for the row with No. = MEMBER_CODE_2');

        // "No.": MEMBER_CODE_3 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_3');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_3');
        Assert.AreEqual('Cannot update', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Cannot update for the row with No. = MEMBER_CODE_3');

        // "No.": MEMBER_CODE_4 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_4');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Rejected for the row with No. = MEMBER_CODE_4');
        Assert.AreEqual('Cannot update', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Cannot update for the row with No. = MEMBER_CODE_4');

        // "No.": MEMBER_CODE_5 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_5');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Rejected for the row with No. = MEMBER_CODE_5');
        Assert.AreEqual('Cannot update', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Cannot update for the row with No. = MEMBER_CODE_5');

        // "No.": MEMBER_CODE_6 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_6');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Rejected for the row with No. = MEMBER_CODE_6');
        Assert.AreEqual('Cannot update', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Cannot update for the row with No. = MEMBER_CODE_6');

        // "No.": MEMBER_CODE_7 - "Group Member Id": randomId (no match)
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_7');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_7');
        Assert.AreEqual('Cannot update', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Cannot update for the row with No. = MEMBER_CODE_7');

        // "No.": MEMBER_CODE_8 - "Group Member Id": 00000000-0000-0000-0000-000000000000 - no match because "VAT Report Config. Code" = "EC Sales List" in master (should be "VAT Return")
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_8');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_8');
        Assert.AreEqual('Cannot update', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Cannot update for the row with No. = MEMBER_CODE_8');

        // "No.": MEMBER_CODE_9 - "Group Member Id": 00000000-0000-0000-0000-000000000000 match with VAT_CODE_10 (not VAT_CODE_9 because this one has older date)
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_9');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_9');
        Assert.AreEqual('Cannot update', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Cannot update for the row with No. = MEMBER_CODE_9');
    end;

    [Test]
    procedure TestUpdateSingleVATReportStatus()
    var
        VATReportHeader: Record "VAT Report Header";
        VATGroupSubmissionStatus: Codeunit "VAT Group Submission Status";
    begin
        // [GIVEN] The VAT Group Role setup to Master (otherwise the API Query will not return results)
        InitVATReportSetupTable();
        InitVATTables();

        // [THEN] All the values that need to be updated are successfully updated using the procedure UpdateSingleVATReportStatus

        // "No.": MEMBER_CODE_1 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATGroupSubmissionStatus.UpdateSingleVATReportStatus('MEMBER_CODE_1');
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_1');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_1');
        Assert.AreEqual('Closed', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Closed for the row with No. = MEMBER_CODE_1');

        // "No.": MEMBER_CODE_2 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATGroupSubmissionStatus.UpdateSingleVATReportStatus('MEMBER_CODE_2');
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_2');
        Assert.AreEqual(VATReportHeader.Status::Accepted, VATReportHeader.Status, 'The field "Status" should be Accepted for the row with No. = MEMBER_CODE_2');
        Assert.AreEqual('Accepted', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Accepted for the row with No. = MEMBER_CODE_2');

        // "No.": MEMBER_CODE_3 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATGroupSubmissionStatus.UpdateSingleVATReportStatus('MEMBER_CODE_3');
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_3');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_3');
        Assert.AreEqual('Canceled', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Canceled for the row with No. = MEMBER_CODE_3');

        // "No.": MEMBER_CODE_4 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATGroupSubmissionStatus.UpdateSingleVATReportStatus('MEMBER_CODE_4');
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_4');
        Assert.AreEqual(VATReportHeader.Status::Rejected, VATReportHeader.Status, 'The field "Status" should be Rejected for the row with No. = MEMBER_CODE_4');
        Assert.AreEqual('Rejected', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Rejected for the row with No. = MEMBER_CODE_4');

        // "No.": MEMBER_CODE_5 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATGroupSubmissionStatus.UpdateSingleVATReportStatus('MEMBER_CODE_5');
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_5');
        Assert.AreEqual(VATReportHeader.Status::Rejected, VATReportHeader.Status, 'The field "Status" should be Rejected for the row with No. = MEMBER_CODE_5');
        Assert.AreEqual('Rejected', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Rejected for the row with No. = MEMBER_CODE_5');


        // "No.": MEMBER_CODE_6 - "Group Member Id": 00000000-0000-0000-0000-000000000000
        VATGroupSubmissionStatus.UpdateSingleVATReportStatus('MEMBER_CODE_6');
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_6');
        Assert.AreEqual(VATReportHeader.Status::Rejected, VATReportHeader.Status, 'The field "Status" should be Rejected for the row with No. = MEMBER_CODE_6');
        Assert.AreEqual('Rejected', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Rejected for the row with No. = MEMBER_CODE_6');

        // "No.": MEMBER_CODE_7 - "Group Member Id": randomId (no match)
        VATGroupSubmissionStatus.UpdateSingleVATReportStatus('MEMBER_CODE_7');
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_7');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_7');
        Assert.AreEqual('Pending', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Pending for the row with No. = MEMBER_CODE_7');

        // "No.": MEMBER_CODE_8 - "Group Member Id": 00000000-0000-0000-0000-000000000000 - no match because "VAT Report Config. Code" = "EC Sales List" in master (should be "VAT Return")
        VATGroupSubmissionStatus.UpdateSingleVATReportStatus('MEMBER_CODE_8');
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_8');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_8');
        Assert.AreEqual('Pending', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Pending for the row with No. = MEMBER_CODE_8');

        // "No.": MEMBER_CODE_9 - "Group Member Id": 00000000-0000-0000-0000-000000000000 match with VAT_CODE_10 (not VAT_CODE_9 because this one has older date)
        VATGroupSubmissionStatus.UpdateSingleVATReportStatus('MEMBER_CODE_9');
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_9');
        Assert.AreEqual(VATReportHeader.Status::Submitted, VATReportHeader.Status, 'The field "Status" should be Submitted for the row with No. = MEMBER_CODE_9');
        Assert.AreEqual('Canceled', VATReportHeader."VAT Group Status", 'The field "VAT Group Status" should be Canceled for the row with No. = MEMBER_CODE_9');
    end;

    [Test]
    procedure TestUpdateSingleVATReportStatusInvalidVATReport()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATGroupSubmissionStatus: Codeunit "VAT Group Submission Status";
    begin
        // [GIVEN] The table without the configuration for the endpoint
        VATReportSetup.DeleteAll();
        Commit();

        // [GIVEN] The table with value that should not be checked for status
        InitVATTablesNoStatusToCheck();

        // [WHEN] Calling the procedure UpdateSingleVATReportStatus with the No of the VAT report with the status that should not be updated
        asserterror VATGroupSubmissionStatus.UpdateSingleVATReportStatus('VAT_CODE_1');

        // [THEN] Error will be thrown about missing setup table
        Assert.ExpectedError('The VAT Report Setup does not exist. Identification fields and values: Primary key=''''');
    end;

    [Test]
    procedure TestUpdateSingleVATReportStatusError()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATGroupSubmissionStatus: Codeunit "VAT Group Submission Status";
        TmpURL: Text;
    begin
        // [GIVEN] The VAT Group Role setup to Master (otherwise the API Query will not return results)
        InitVATReportSetupTable();
        InitVATTables();

        // [ GIVEN] A wrong Query API endpoint
        TmpURL := LibraryGraphMgt.CreateQueryTargetURL(Query::"VAT Group Submission Status", '');
        VATReportSetup.FindFirst();
        VATReportSetup."Group Representative API URL" := CopyStr(TmpURL, 1, StrPos(TmpURL, 'NAV') - 1);
        VATReportSetup.Modify();
        Commit();

        // [WHEN] Calling the procedure UpdateSingleVATReportStatus
        asserterror VATGroupSubmissionStatus.UpdateSingleVATReportStatus('MEMBER_CODE_1');

        // [THEN] The error is handled by the codeunit, a specific message is returned
        Assert.ExpectedError('Not Found: cannot locate the requested resource.');
    end;

    [Test]
    procedure TestVisibilityEnabledForButtonUpdateStatusVATReportPage()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        // [SCENARIO] Check that the button to update the VAT report is visible

        // [GIVEN] Tables that are populated only with test values
        CreateVATReportConfiguration();
        InitVATReportSetupTable();
        InitVATTables();

        // [WHEN] Checking if the button to update the VAT report status is enabled
        // [THEN] The button should be enabled
        CheckButtonPageVisibility(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_1', true);
        CheckButtonPageVisibility(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_2', true);
        CheckButtonPageVisibility(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_3', true);
        CheckButtonPageVisibility(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_4', true);
        CheckButtonPageVisibility(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_6', true);
    end;

    [Test]
    procedure TestVisibilityDisabledForButtonUpdateStatusVATReportPage()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        // [SCENARIO] Check that the button to update the VAT report is not visible

        // [GIVEN] Tables that are populated only with test values
        CreateVATReportConfiguration();
        InitVATTablesNoStatusToCheck();

        // [WHEN] Checking if the button to update the VAT report status is disabled
        // [THEN] The button should be disabled
        CheckButtonPageVisibility(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'VAT_CODE_2', false);
        CheckButtonPageVisibility(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'VAT_CODE_4', false);
    end;

    [Test]
    procedure TestButtonUpdateStatusVATReportPage()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: Page "VAT Report";
        VATReportTestPage: TestPage "VAT Report";
    begin
        // [SCENARIO] Check that the button to update the VAT report status successfully updates the value

        // [GIVEN] Tables that are populated only with test values
        CreateVATReportConfiguration();
        InitVATReportSetupTable();
        InitVATTables();

        // [WHEN] Clicking the button to update the status
        VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", 'MEMBER_CODE_1');
        VATReportPage.SetRecord(VATReportHeader);
        VATReportTestPage.Trap();
        VATReportPage.Run();

        VATReportTestPage.UpdateStatus.Invoke();
        // [THEN] The status is successfully updated
        Assert.AreEqual('Closed', Format(VATReportTestPage."VAT Group Status"), 'The field "VAT Group Status" should be Closed for the row with No. = MEMBER_CODE_1');

        VATReportPage.Close();
        VATReportTestPage.Close();
    end;

    local procedure InitVATTables()
    var
        VATReportHeader: Record "VAT Report Header";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
        VATReportSetup: Record "VAT Report Setup";
        MemberId: Text;
    begin
        VATReportHeader.DeleteAll();
        VATGroupSubmissionHeader.DeleteAll();

        VATReportSetup.FindFirst();
        MemberId := DelChr(VATReportSetup."Group Member Id", '=', '{|}');

        // member
        InsertIntoVATReportHeader('MEMBER_CODE_1', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Submitted, 'VATGROUP', 'Submitted');
        // representative
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0001-100890ABCDEA', 'MEMBER_CODE_1', 'VAT_CODE_1', MemberId, CreateDateTime(20200127D, 120000T));
        InsertIntoVATReportHeader('VAT_CODE_1', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Closed, 'VATGROUP', 'Closed');

        // member
        InsertIntoVATReportHeader('MEMBER_CODE_2', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Submitted, 'VATGROUP', 'Open');
        // representative
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0002-100890ABCDEA', 'MEMBER_CODE_2', 'VAT_CODE_2', MemberId, CreateDateTime(20200127D, 120000T));
        InsertIntoVATReportHeader('VAT_CODE_2', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Accepted, 'VATGROUP', 'Accepted');

        // member
        InsertIntoVATReportHeader('MEMBER_CODE_3', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Submitted, 'VATGROUP', 'Released');
        // representative
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0003-100890ABCDEA', 'MEMBER_CODE_3', 'VAT_CODE_3', MemberId, CreateDateTime(20200127D, 120000T));
        InsertIntoVATReportHeader('VAT_CODE_3', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Canceled, 'VATGROUP', 'Canceled');

        // member
        InsertIntoVATReportHeader('MEMBER_CODE_4', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Submitted, 'VATGROUP', 'Pending');
        // representative
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0004-100890ABCDEA', 'MEMBER_CODE_4', 'VAT_CODE_4', MemberId, CreateDateTime(20200127D, 120000T));
        InsertIntoVATReportHeader('VAT_CODE_4', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Rejected, 'VATGROUP', 'Rejected');

        // member
        InsertIntoVATReportHeader('MEMBER_CODE_5', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Submitted, 'VATGROUP', 'Cannot update');
        // representative
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0005-100890ABCDEA', 'MEMBER_CODE_5', 'VAT_CODE_5', MemberId, CreateDateTime(20200127D, 120000T));
        InsertIntoVATReportHeader('VAT_CODE_5', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Rejected, 'VATGROUP', 'Rejected');

        // member
        InsertIntoVATReportHeader('MEMBER_CODE_6', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Submitted, 'VATGROUP', '');
        // representative
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0006-100890ABCDEA', 'MEMBER_CODE_6', 'VAT_CODE_6', MemberId, CreateDateTime(20200127D, 120000T));
        InsertIntoVATReportHeader('VAT_CODE_6', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Rejected, 'VATGROUP', 'Rejected');

        // member
        InsertIntoVATReportHeader('MEMBER_CODE_7', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Submitted, 'VATGROUP', 'Submitted');
        // representative
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0007-100890ABCDEA', 'MEMBER_CODE_7', 'VAT_CODE_7', CreateGuid(), CreateDateTime(20200127D, 120000T));
        InsertIntoVATReportHeader('VAT_CODE_7', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Open, 'VATGROUP', 'Open');

        // member
        InsertIntoVATReportHeader('MEMBER_CODE_8', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Submitted, 'VATGROUP', 'Submitted');
        // representative
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0008-100890ABCDEA', 'MEMBER_CODE_8', 'VAT_CODE_8', MemberId, CreateDateTime(20200127D, 120000T));
        InsertIntoVATReportHeader('VAT_CODE_8', VATReportHeader."VAT Report Config. Code"::"EC Sales List", VATReportHeader.Status::Open, 'VATGROUP', 'Open');

        // member
        InsertIntoVATReportHeader('MEMBER_CODE_9', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Submitted, 'VATGROUP', '');
        // representative
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0009-100890ABCDEA', 'MEMBER_CODE_9', 'VAT_CODE_9', MemberId, CreateDateTime(20200127D, 120000T));
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0009-200890ABCDEA', 'MEMBER_CODE_9', 'VAT_CODE_10', MemberId, CreateDateTime(20200628D, 120000T));
        InsertIntoVATReportHeader('VAT_CODE_9', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Rejected, 'VATGROUP', 'Rejected');
        InsertIntoVATReportHeader('VAT_CODE_10', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Canceled, 'VATGROUP', 'Canceled');

        Commit();
    end;

    local procedure CreateVATReportConfiguration()
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        VATReportsConfiguration.DeleteAll();

        VATReportsConfiguration."VAT Report Type" := VATReportsConfiguration."VAT Report Type"::"VAT Return";
        VATReportsConfiguration."VAT Report Version" := 'VATGROUP';
        VATReportsConfiguration.Insert();
        Commit();
    end;

    local procedure InitVATReportSetupTable()
    var
        VATReportSetup: Record "VAT Report Setup";
        TmpURL: Text;
    begin
        TmpURL := LibraryGraphMgt.CreateQueryTargetURL(Query::"VAT Group Submission Status", '');

        VATReportSetup.DeleteAll();
        VATReportSetup."Primary key" := '';
        VATReportSetup."Group Representative API URL" := CopyStr(TmpURL, 1, StrPos(TmpURL, '/api/') - 1);
        VATReportSetup."Group Representative Company" := CompanyName();
        VATReportSetup."VAT Group Role" := VATReportSetup."VAT Group Role"::Representative;
        VATReportSetup."Authentication Type" := VATReportSetup."Authentication Type"::WindowsAuthentication;
        VATReportSetup.Insert();
    end;

    local procedure ChangeVATGroupRole(VATGroupRole: Enum "VAT Group Role")
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup."VAT Group Role" := VATGroupRole;
        VATReportSetup.Modify();
        Commit();
    end;

    local procedure InitVATTablesNoStatusToCheck()
    var
        VATReportHeader: Record "VAT Report Header";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
    begin
        VATReportHeader.DeleteAll();
        VATGroupSubmissionHeader.DeleteAll();

        InsertIntoVATReportHeader('VAT_CODE_1', VATReportHeader."VAT Report Config. Code"::"EC Sales List", VATReportHeader.Status::Submitted, 'VATGROUP', 'Submitted');
        InsertIntoVATReportHeader('VAT_CODE_2', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Closed, 'VATGROUP', 'Submitted');
        InsertIntoVATReportHeader('VAT_CODE_3', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Submitted, 'TEST', 'Submitted');
        InsertIntoVATReportHeader('VAT_CODE_4', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Submitted, 'VATGROUP', 'Closed');

        Commit();
    end;

    local procedure InitVATTablesAPIEndpoint()
    var
        VATReportHeader: Record "VAT Report Header";
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
    begin
        VATReportHeader.DeleteAll();
        VATGroupSubmissionHeader.DeleteAll();

        // match with VAT_CODE_2 because of the date (from "VAT Group Submission Header" the row with the newest date is taken)
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0001-100890ABCDEA', 'TEST_NO_1', 'VAT_CODE_1', '00000000-0000-0000-0000-000000000000', CreateDateTime(20200117D, 120000T));
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0001-200890ABCDEA', 'TEST_NO_1', 'VAT_CODE_2', '00000000-0000-0000-0000-000000000000', CreateDateTime(20200127D, 120000T));
        InsertIntoVATReportHeader('VAT_CODE_1', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Submitted, 'VATGROUP', 'Submitted');
        InsertIntoVATReportHeader('VAT_CODE_2', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Rejected, 'VATGROUP', 'Rejected');

        // match with VAT_CODE_3 because even if the newest date is VAT_CODE_4, there is no match for it in the "VAT Report Header" table
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0002-100890ABCDEA', 'TEST_NO_2', 'VAT_CODE_3', '00000000-0000-0000-0000-000000000000', CreateDateTime(20200117D, 120000T));
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0002-200890ABCDEA', 'TEST_NO_2', 'VAT_CODE_4', '00000000-0000-0000-0000-000000000000', CreateDateTime(20200127D, 120000T));
        InsertIntoVATReportHeader('VAT_CODE_3', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Canceled, 'VATGROUP', 'Canceled');

        // no match in "VAT Report Header"
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0003-100890ABCDEA', 'TEST_NO_3', 'VAT_CODE_5', '00000000-0000-0000-0000-000000000000', CreateDateTime(20200117D, 120000T));

        // no match in "VAT Report Header" because "VAT Report Config. Code" = "EC Sales List" (it should be "VAT Return" to have a match)
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0004-100890ABCDEA', 'TEST_NO_4', 'VAT_CODE_6', '00000000-0000-0000-0000-000000000000', CreateDateTime(20200117D, 120000T));
        InsertIntoVATReportHeader('VAT_CODE_6', VATReportHeader."VAT Report Config. Code"::"EC Sales List", VATReportHeader.Status::Closed, 'VATGROUP', 'Closed');

        // different "Group Member Id", there is a match for 00000000-0000-0000-0000-000000000001 but not for 00000000-0000-0000-0000-000000000000
        InsertIntoVATGroupSubmissionHeader('CDEF7890-ABCD-0123-0005-100890ABCDEA', 'TEST_NO_5', 'VAT_CODE_7', '00000000-0000-0000-0000-000000000001', CreateDateTime(20200127D, 120000T));
        InsertIntoVATReportHeader('VAT_CODE_7', VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader.Status::Submitted, 'VATGROUP', 'Submitted');

        Commit();
    end;

    local procedure CheckButtonPageVisibility(VATReportConfigCode: Option; No: Code[20]; ShouldBeEnabled: Boolean)
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: Page "VAT Report";
        VATReportTestPage: TestPage "VAT Report";
        Error: Text;
    begin
        if ShouldBeEnabled then
            Error := 'The button "Update Status" should be enabled'
        else
            Error := 'The button "Update Status" should not be enabled';

        VATReportHeader.Get(VATReportConfigCode, No);
        VATReportPage.SetRecord(VATReportHeader);
        VATReportTestPage.Trap();
        VATReportPage.Run();
        Assert.AreEqual(ShouldBeEnabled, VATReportTestPage.UpdateStatus.Visible(), Error);

        VATReportPage.Close();
        VATReportTestPage.Close();
    end;

    local procedure InsertIntoVATGroupSubmissionHeader(Id: Guid; No: Code[20]; VATGroupReturnNo: Code[20]; GroupMemberId: Guid; SubmittedOn: DateTime)
    var
        VATGroupSubmissionHeader: Record "VAT Group Submission Header";
    begin
        VATGroupSubmissionHeader.Id := Id;
        VATGroupSubmissionHeader."No." := No;
        VATGroupSubmissionHeader."VAT Group Return No." := VATGroupReturnNo;
        VATGroupSubmissionHeader."Group Member Id" := GroupMemberId;
        VATGroupSubmissionHeader."Submitted On" := SubmittedOn;
        VATGroupSubmissionHeader.Insert();
    end;

    local procedure InsertIntoVATReportHeader(VATGroupReturnNo: Code[20]; VATReportConfigCode: Option; Status: Option; VATReportVersion: Code[10]; VATGroupStatus: Text[20])
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VATReportHeader."No." := VATGroupReturnNo;
        VATReportHeader."VAT Report Config. Code" := VATReportConfigCode;
        VATReportHeader."Status" := Status;
        VATReportHeader."VAT Report Version" := VATReportVersion;
        VATReportHeader."VAT Group Status" := VATGroupStatus;
        VATReportHeader.Insert();
    end;
}