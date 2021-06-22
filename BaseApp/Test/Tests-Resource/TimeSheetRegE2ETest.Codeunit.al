codeunit 135930 "Time Sheet Reg. E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Time Sheet] [Time Registration Entity]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryRandom: Codeunit "Library - Random";
        GraphMgtTimeRegistration: Codeunit "Graph Mgt - Time Registration";
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'timeRegistrationEntries';
        xPersonDescriptionTxt: Label 'Resource PERSON';

    local procedure Initialize()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        UserSetup: Record "User Setup";
        FiltersOutStream: OutStream;
    begin
        CleanTableData;
        if IsInitialized then
            exit;

        UserSetup.DeleteAll;
        ConfigTemplateHeader.DeleteAll;
        ConfigTmplSelectionRules.DeleteAll;

        GraphMgtTimeRegistration.InitUserSetup;

        InsertTemplate(ConfigTemplateHeader, xPersonDescriptionTxt, 'SERVICES', 'HOUR');

        ConfigTmplSelectionRules.Validate("Page ID", PAGE::"Time Registration Entity");
        ConfigTmplSelectionRules.Validate("Table ID", DATABASE::Resource);
        ConfigTmplSelectionRules.Validate("Template Code", ConfigTemplateHeader.Code);
        ConfigTmplSelectionRules.Validate(Order, 0);
        ConfigTmplSelectionRules.Insert(true);

        ConfigTmplSelectionRules."Selection Criteria".CreateOutStream(FiltersOutStream);
        FiltersOutStream.WriteText('');
        ConfigTmplSelectionRules.Modify(true);

        IsInitialized := true;
        Commit;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateTimeSheetNewHeader()
    var
        TargetURL: Text;
        ResponseText: Text;
        TimeSheetRegJSON: Text;
        Date: Date;
        AccPeriodStartingDate: Date;
        Employee: Record Employee;
        ResourceNo: Code[20];
        EmployeeTimeRegBuffId: Guid;
    begin
        // [GIVEN] a JSON text with an Employee Time Reg Buffer
        Initialize;

        AccPeriodStartingDate := GetAccountingPeriodStartingDate;
        Date := CalcDate('<CW+1D>', AccPeriodStartingDate);
        ResourceNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ResourceNo));

        CreateResource(ResourceNo);
        CreateEmployee(Employee, ResourceNo);

        TimeSheetRegJSON := CreateMinimalTimeSheetRegJSON(Date, Employee.SystemId);

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Time Registration Entity", '');
        LibraryGraphMgt.PostToWebService(TargetURL, TimeSheetRegJSON, ResponseText);

        // [THEN] the response text should be valid
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');

        EmployeeTimeRegBuffId := VerifyEmployeeTimeRegBuffIdInJson(ResponseText);

        VerifyTimeSheetSync(EmployeeTimeRegBuffId, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateTimeSheetNewLine()
    var
        TimeSheetLine: Record "Time Sheet Line";
        TargetURL: Text;
        ResponseText: Text;
        TimeSheetRegJSON: Text;
        Employee: Record Employee;
        ResourceNo: Code[20];
        Date: Date;
        TimeSheetHeaderNo: Code[20];
        AccPeriodStartingDate: Date;
        EmployeeTimeRegBuffId: Guid;
    begin
        // [GIVEN] a JSON text with an Employee Time Reg Buffer
        Initialize;

        AccPeriodStartingDate := GetAccountingPeriodStartingDate;
        Date := CalcDate('<CW+1D>', AccPeriodStartingDate);
        TimeSheetHeaderNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TimeSheetHeaderNo));
        ResourceNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ResourceNo));

        CreateResource(ResourceNo);
        CreateEmployee(Employee, ResourceNo);

        CreateTimeSheetHeader(TimeSheetHeaderNo, Date, ResourceNo);
        CreateTimeSheetLine(TimeSheetHeaderNo, TimeSheetLine.Type::Job);

        TimeSheetRegJSON := CreateMinimalTimeSheetRegJSON(Date, Employee.SystemId);

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Time Registration Entity", '');
        LibraryGraphMgt.PostToWebService(TargetURL, TimeSheetRegJSON, ResponseText);

        // [THEN] the response text should be valid
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');

        EmployeeTimeRegBuffId := VerifyEmployeeTimeRegBuffIdInJson(ResponseText);

        VerifyTimeSheetSync(EmployeeTimeRegBuffId, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateTimeSheetNewDetail()
    var
        TimeSheetLine: Record "Time Sheet Line";
        Employee: Record Employee;
        ResourceNo: Code[20];
        TargetURL: Text;
        ResponseText: Text;
        TimeSheetRegJSON: Text;
        Date1: Date;
        Date2: Date;
        TimeSheetHeaderNo: Code[20];
        TimeSheetLineNo: Integer;
        AccPeriodStartingDate: Date;
        EmployeeTimeRegBuffId: Guid;
    begin
        // [GIVEN] a JSON text with an Employee Time Reg Buffer
        Initialize;

        AccPeriodStartingDate := GetAccountingPeriodStartingDate;
        Date1 := CalcDate('<CW+1D>', AccPeriodStartingDate);
        Date2 := CalcDate('<CW+2D>', AccPeriodStartingDate);
        TimeSheetHeaderNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TimeSheetHeaderNo));
        ResourceNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ResourceNo));

        CreateResource(ResourceNo);
        CreateEmployee(Employee, ResourceNo);

        CreateTimeSheetHeader(TimeSheetHeaderNo, Date1, ResourceNo);
        TimeSheetLineNo := CreateTimeSheetLine(TimeSheetHeaderNo, TimeSheetLine.Type::Resource);
        CreateTimeSheetDetail(TimeSheetHeaderNo, TimeSheetLineNo, Date1, LibraryRandom.RandDec(255, 2));

        TimeSheetRegJSON := CreateMinimalTimeSheetRegJSON(Date2, Employee.SystemId);

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Time Registration Entity", '');
        LibraryGraphMgt.PostToWebService(TargetURL, TimeSheetRegJSON, ResponseText);

        // [THEN] the response text should be valid
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');

        EmployeeTimeRegBuffId := VerifyEmployeeTimeRegBuffIdInJson(ResponseText);

        VerifyTimeSheetSync(EmployeeTimeRegBuffId, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateTimeSheetDetailAndCheckLineNumber()
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        Employee1: Record Employee;
        Employee2: Record Employee;
        ResourceNo: Code[20];
        TargetURL: Text;
        ResponseText: Text;
        TimeSheetRegJSON: Text;
        Date: Date;
        TimeSheetHeaderNo: Code[20];
        TimeSheetLineNo: Integer;
        AccPeriodStartingDate: Date;
        EmployeeTimeRegBuffId: Text;
    begin
        // [SCENARIO] when time registration entries already exist the new one will have the correct line number
        Initialize;

        // [GIVEN] 2 time sheet details
        AccPeriodStartingDate := GetAccountingPeriodStartingDate;
        Date := CalcDate('<CW+1D>', AccPeriodStartingDate);
        TimeSheetHeaderNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TimeSheetHeaderNo));
        ResourceNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ResourceNo));

        CreateResource(ResourceNo);
        CreateEmployee(Employee1, ResourceNo);

        CreateTimeSheetHeader(TimeSheetHeaderNo, Date, ResourceNo);
        TimeSheetLineNo := CreateTimeSheetLine(TimeSheetHeaderNo, TimeSheetLine.Type::Resource);
        CreateTimeSheetDetail(TimeSheetHeaderNo, TimeSheetLineNo, Date, LibraryRandom.RandDec(255, 2));
        CreateTimeSheetDetail(TimeSheetHeaderNo, TimeSheetLineNo + 10000, Date, LibraryRandom.RandDec(255, 2));

        // [GIVEN] another employee
        CreateEmployee(Employee2, '');

        TimeSheetRegJSON := CreateMinimalTimeSheetRegJSON(Date, Employee2.SystemId);

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Time Registration Entity", '');
        LibraryGraphMgt.PostToWebService(TargetURL, TimeSheetRegJSON, ResponseText);

        // [THEN] the line number should be 10000
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');

        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'id', EmployeeTimeRegBuffId);
        TimeSheetDetail.SetRange(Id, LowerCase(LibraryGraphMgt.StripBrackets(EmployeeTimeRegBuffId)));
        TimeSheetDetail.FindFirst;
        Assert.AreEqual(10000, TimeSheetDetail."Time Sheet Line No.", 'Time Sheet Detail Line Number should be 10000');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateTimeSheetGenerateResource()
    var
        TargetURL: Text;
        ResponseText: Text;
        TimeSheetRegJSON: Text;
        Date: Date;
        AccPeriodStartingDate: Date;
        Employee: Record Employee;
        EmployeeTimeRegBuffId: Guid;
    begin
        // [GIVEN] a JSON text with an Employee Time Reg Buffer
        Initialize;

        AccPeriodStartingDate := GetAccountingPeriodStartingDate;
        Date := CalcDate('<CW+1D>', AccPeriodStartingDate);

        CreateEmployee(Employee, '');

        TimeSheetRegJSON := CreateMinimalTimeSheetRegJSON(Date, Employee.SystemId);

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Time Registration Entity", '');
        LibraryGraphMgt.PostToWebService(TargetURL, TimeSheetRegJSON, ResponseText);

        // [THEN] the response text should be valid
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');

        EmployeeTimeRegBuffId := VerifyEmployeeTimeRegBuffIdInJson(ResponseText);

        VerifyTimeSheetSync(EmployeeTimeRegBuffId, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchTimeSheet()
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetLine: Record "Time Sheet Line";
        Employee: Record Employee;
        ResourceNo: Code[20];
        TargetURL: Text;
        ResponseText: Text;
        TimeSheetRegJSON: Text;
        Date: Date;
        TimeSheetHeaderNo: Code[20];
        TimeSheetLineNo: Integer;
        AccPeriodStartingDate: Date;
        Quantity: Decimal;
        NewQuantity: Decimal;
        TimeSheetDetailId: Guid;
    begin
        // [GIVEN] a JSON text with an Employee Time Reg Buffer
        Initialize;

        AccPeriodStartingDate := GetAccountingPeriodStartingDate;
        Date := CalcDate('<CW+1D>', AccPeriodStartingDate);
        TimeSheetHeaderNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TimeSheetHeaderNo));
        ResourceNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ResourceNo));
        Quantity := LibraryRandom.RandDec(255, 0);
        NewQuantity := LibraryRandom.RandDec(255, 0);

        CreateResource(ResourceNo);
        CreateEmployee(Employee, ResourceNo);

        CreateTimeSheetHeader(TimeSheetHeaderNo, Date, ResourceNo);
        TimeSheetLineNo := CreateTimeSheetLine(TimeSheetHeaderNo, TimeSheetLine.Type::Resource);
        TimeSheetDetailId := CreateTimeSheetDetail(TimeSheetHeaderNo, TimeSheetLineNo, Date, Quantity);

        TimeSheetRegJSON := LibraryGraphMgt.AddPropertytoJSON('', 'quantity', NewQuantity);

        // [WHEN] we PATCH the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(TimeSheetDetailId, PAGE::"Time Registration Entity", ServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, TimeSheetRegJSON, ResponseText);

        // [THEN] the response text should be valid
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');
        VerifyEmployeeTimeRegBuffIdInJson(ResponseText);

        TimeSheetDetail.Reset;
        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetHeaderNo);
        TimeSheetDetail.SetRange("Time Sheet Line No.", TimeSheetLineNo);
        TimeSheetDetail.SetRange(Date, Date);
        TimeSheetDetail.FindFirst;
        Assert.AreEqual(TimeSheetDetail.Quantity, NewQuantity, 'Time Sheet Detail quantity has not been patched correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTimeSheetByTimeSheetDetailId()
    var
        TimeSheetLine: Record "Time Sheet Line";
        Employee: Record Employee;
        ResourceNo: Code[20];
        TargetURL: Text;
        ResponseText: Text;
        Date: Date;
        TimeSheetHeaderNo: Code[20];
        TimeSheetLineNo: Integer;
        AccPeriodStartingDate: Date;
        Quantity: Decimal;
        TimeSheetDetailId: Guid;
    begin
        // [GIVEN] a Time Registration Entry

        Initialize;

        AccPeriodStartingDate := GetAccountingPeriodStartingDate;
        Date := CalcDate('<CW+1D>', AccPeriodStartingDate);
        TimeSheetHeaderNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TimeSheetHeaderNo));
        ResourceNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ResourceNo));
        Quantity := LibraryRandom.RandDec(255, 0);

        CreateResource(ResourceNo);
        CreateEmployee(Employee, ResourceNo);

        CreateTimeSheetHeader(TimeSheetHeaderNo, Date, ResourceNo);
        TimeSheetLineNo := CreateTimeSheetLine(TimeSheetHeaderNo, TimeSheetLine.Type::Resource);
        TimeSheetDetailId := CreateTimeSheetDetail(TimeSheetHeaderNo, TimeSheetLineNo, Date, Quantity);

        // [WHEN] we GET the JSON from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(TimeSheetDetailId, PAGE::"Time Registration Entity", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response text should be valid
        VerifyGetProperties(ResponseText, Employee.SystemId, Date, ResourceNo, TimeSheetDetailId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTimeSheetsWithDateFilter()
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetHeaderNo: array[3] of Code[20];
        TimeSheetLineNo: array[3] of Integer;
        AccPeriodStartingDate: Date;
        TargetURL: Text;
        ResponseText: Text;
        Date: array[3] of Date;
        Employee1: Record Employee;
        Employee2: Record Employee;
        Employee3: Record Employee;
        ResourceNo: array[3] of Code[20];
        TimeSheetRegEntryJSON: array[3] of Text;
        TimeSheetDetailId: array[3] of Guid;
    begin
        // [SCENARIO] User can retrieve a list of the Time Sheet Registration Entries using a Date Filter
        Initialize;

        // [GIVEN] 3 Time Sheet Registration Entries
        AccPeriodStartingDate := GetAccountingPeriodStartingDate;

        ResourceNo[1] := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ResourceNo[1]));
        ResourceNo[2] := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ResourceNo[2]));
        ResourceNo[3] := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ResourceNo[3]));

        TimeSheetHeaderNo[1] := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TimeSheetHeaderNo[1]));
        TimeSheetHeaderNo[2] := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TimeSheetHeaderNo[2]));
        TimeSheetHeaderNo[3] := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TimeSheetHeaderNo[3]));

        Date[1] := CalcDate('<CW+1D>', AccPeriodStartingDate);
        Date[2] := CalcDate('<CW+1D>', AccPeriodStartingDate);
        Date[3] := CalcDate('<CW+2D>', AccPeriodStartingDate);

        CreateResource(ResourceNo[1]);
        CreateResource(ResourceNo[2]);
        CreateResource(ResourceNo[3]);
        CreateEmployee(Employee1, ResourceNo[1]);
        CreateEmployee(Employee2, ResourceNo[2]);
        CreateEmployee(Employee3, ResourceNo[3]);

        CreateTimeSheetHeader(TimeSheetHeaderNo[1], Date[1], ResourceNo[1]);
        TimeSheetLineNo[1] := CreateTimeSheetLine(TimeSheetHeaderNo[1], TimeSheetLine.Type::Resource);
        TimeSheetDetailId[1] := CreateTimeSheetDetail(TimeSheetHeaderNo[1], TimeSheetLineNo[1], Date[1], LibraryRandom.RandDec(255, 0));
        CreateTimeSheetHeader(TimeSheetHeaderNo[2], Date[2], ResourceNo[2]);
        TimeSheetLineNo[2] := CreateTimeSheetLine(TimeSheetHeaderNo[2], TimeSheetLine.Type::Resource);
        TimeSheetDetailId[2] := CreateTimeSheetDetail(TimeSheetHeaderNo[2], TimeSheetLineNo[2], Date[2], LibraryRandom.RandDec(255, 0));
        CreateTimeSheetHeader(TimeSheetHeaderNo[3], Date[3], ResourceNo[3]);
        TimeSheetLineNo[3] := CreateTimeSheetLine(TimeSheetHeaderNo[3], TimeSheetLine.Type::Resource);
        TimeSheetDetailId[3] := CreateTimeSheetDetail(TimeSheetHeaderNo[3], TimeSheetLineNo[3], Date[3], LibraryRandom.RandDec(255, 0));

        // [WHEN] we GET the JSON from the web service

        TargetURL := CreateTimeRegEntriesURLWithDateFilter(Date[1] - 1, Date[1] + 1);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 items should exist in the response and the 3rd shouldn't
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(
            ResponseText, 'id', LowerCase(LibraryGraphMgt.StripBrackets(TimeSheetDetailId[2])),
            LowerCase(LibraryGraphMgt.StripBrackets(TimeSheetDetailId[1])), TimeSheetRegEntryJSON[2], TimeSheetRegEntryJSON[1]),
          'Could not find the time registration entries in JSON');
        VerifyGetProperties(TimeSheetRegEntryJSON[1], Employee1.SystemId, Date[1], ResourceNo[1], TimeSheetDetailId[1]);
        VerifyGetProperties(TimeSheetRegEntryJSON[2], Employee2.SystemId, Date[2], ResourceNo[2], TimeSheetDetailId[2]);

        Assert.IsFalse(
          LibraryGraphMgt.GetObjectsFromJSONResponse(
            ResponseText, 'id', LowerCase(LibraryGraphMgt.StripBrackets(TimeSheetDetailId[3])),
            LowerCase(LibraryGraphMgt.StripBrackets(TimeSheetDetailId[3])), TimeSheetRegEntryJSON[3], TimeSheetRegEntryJSON[3]),
          'The time registration entry that should be out of range is in the response');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTimeSheetsWithEmployeeFilter()
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetHeaderNo: array[3] of Code[20];
        TimeSheetLineNo: array[3] of Integer;
        AccPeriodStartingDate: Date;
        TargetURL: Text;
        ResponseText: Text;
        Date: array[3] of Date;
        Employee1: Record Employee;
        Employee2: Record Employee;
        ResourceNo: array[3] of Code[20];
        TimeSheetRegEntryJSON: array[3] of Text;
        TimeSheetDetailId: array[3] of Guid;
    begin
        // [SCENARIO] User can retrieve a list of the Time Sheet Registration Entries using an Employee Id Filter

        Initialize;

        AccPeriodStartingDate := GetAccountingPeriodStartingDate;

        ResourceNo[1] := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ResourceNo[1]));
        ResourceNo[2] := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ResourceNo[2]));

        TimeSheetHeaderNo[1] := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TimeSheetHeaderNo[1]));
        TimeSheetHeaderNo[2] := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TimeSheetHeaderNo[2]));

        Date[1] := CalcDate('<CW+1D>', AccPeriodStartingDate);
        Date[2] := CalcDate('<CW+1D>', AccPeriodStartingDate);

        CreateResource(ResourceNo[1]);
        CreateResource(ResourceNo[2]);
        CreateEmployee(Employee1, ResourceNo[1]);
        CreateEmployee(Employee2, ResourceNo[2]);

        CreateTimeSheetHeader(TimeSheetHeaderNo[1], Date[1], ResourceNo[1]);
        TimeSheetLineNo[1] := CreateTimeSheetLine(TimeSheetHeaderNo[1], TimeSheetLine.Type::Resource);
        TimeSheetDetailId[1] := CreateTimeSheetDetail(TimeSheetHeaderNo[1], TimeSheetLineNo[1], Date[1], LibraryRandom.RandDec(255, 0));
        CreateTimeSheetHeader(TimeSheetHeaderNo[2], Date[2], ResourceNo[2]);
        TimeSheetLineNo[2] := CreateTimeSheetLine(TimeSheetHeaderNo[2], TimeSheetLine.Type::Resource);
        TimeSheetDetailId[2] := CreateTimeSheetDetail(TimeSheetHeaderNo[2], TimeSheetLineNo[2], Date[2], LibraryRandom.RandDec(255, 0));

        // [WHEN] we GET the JSON from the web service
        TargetURL := CreateTimeRegEntriesURLWithEmployeeFilter(Employee1.SystemId);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the item with the 1st employeeId should exist in the response the 2nd shouldn't
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectFromJSONResponse(ResponseText, TimeSheetRegEntryJSON[1], 1),
          'Could not find the time registration entries in JSON');
        VerifyGetProperties(TimeSheetRegEntryJSON[1], Employee1.SystemId, Date[1], ResourceNo[1], TimeSheetDetailId[1]);

        asserterror LibraryGraphMgt.GetObjectFromJSONResponse(ResponseText, TimeSheetRegEntryJSON[2], 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTimeSheetsWithWrongFilters()
    var
        AccPeriodStartingDate: Date;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] User cannot retrieve entries without filters

        Initialize;

        AccPeriodStartingDate := GetAccountingPeriodStartingDate;
        // [WHEN] we make requests without filters

        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Time Registration Entity", '');

        // [THEN] when we make a GET request without filters it fails
        asserterror LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        TargetURL := CreateTimeRegEntriesURLWithDateFilter(AccPeriodStartingDate - 40, AccPeriodStartingDate + 40);

        // [THEN] when we make a GET request with date filters with range bigger than 70
        asserterror LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteTimeSheet()
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetLine: Record "Time Sheet Line";
        Employee: Record Employee;
        ResourceNo: Code[20];
        TargetURL: Text;
        ResponseText: Text;
        DummyTimeSheetRegJSON: Text;
        Date: Date;
        TimeSheetHeaderNo: Code[20];
        TimeSheetLineNo: Integer;
        AccPeriodStartingDate: Date;
        Quantity: Decimal;
        TimeSheetDetailId: Guid;
    begin
        // [GIVEN] a Time Registration Entry
        Initialize;

        AccPeriodStartingDate := GetAccountingPeriodStartingDate;
        Date := CalcDate('<CW+1D>', AccPeriodStartingDate);
        TimeSheetHeaderNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TimeSheetHeaderNo));
        ResourceNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ResourceNo));
        Quantity := LibraryRandom.RandDec(255, 0);

        CreateResource(ResourceNo);
        CreateEmployee(Employee, ResourceNo);

        CreateTimeSheetHeader(TimeSheetHeaderNo, Date, ResourceNo);
        TimeSheetLineNo := CreateTimeSheetLine(TimeSheetHeaderNo, TimeSheetLine.Type::Resource);
        TimeSheetDetailId := CreateTimeSheetDetail(TimeSheetHeaderNo, TimeSheetLineNo, Date, Quantity);

        // [WHEN] we DELETE the specified Object from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(TimeSheetDetailId, PAGE::"Time Registration Entity", ServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, DummyTimeSheetRegJSON, ResponseText);

        // [THEN] the Time Registration entry should not exist anymore
        Assert.IsFalse(
          TimeSheetDetail.Get(TimeSheetHeaderNo, TimeSheetLineNo, Date), 'Time Sheet Detail quantity has not been deleted correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorOnCreateOrModifyWithReadOnlyFields()
    var
        TimeSheetLine: Record "Time Sheet Line";
        TargetURLPost: Text;
        TargetURLPatch: Text;
        ResponseText: Text;
        TimeSheetRegJSON: Text;
        Date: Date;
        AccPeriodStartingDate: Date;
        Employee1: Record Employee;
        Employee2: Record Employee;
        ResourceNo: Code[20];
        ResourceNo2: Code[20];
        Quantity: Decimal;
        TimeSheetHeaderNo: Code[20];
        TimeSheetLineNo: Integer;
        TimeSheetDetailId: Guid;
    begin
        // [GIVEN] a JSON text with an Employee Time Reg Buffer
        Initialize;

        AccPeriodStartingDate := GetAccountingPeriodStartingDate;
        Date := CalcDate('<CW+1D>', AccPeriodStartingDate);
        TimeSheetHeaderNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TimeSheetHeaderNo));
        ResourceNo := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ResourceNo));
        ResourceNo2 := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(ResourceNo2));
        Quantity := LibraryRandom.RandDec(255, 0);

        CreateResource(ResourceNo);
        CreateEmployee(Employee1, ResourceNo);

        CreateResource(ResourceNo2);
        CreateEmployee(Employee2, ResourceNo2);

        CreateTimeSheetHeader(TimeSheetHeaderNo, Date, ResourceNo);
        TimeSheetLineNo := CreateTimeSheetLine(TimeSheetHeaderNo, TimeSheetLine.Type::Resource);
        TimeSheetDetailId := CreateTimeSheetDetail(TimeSheetHeaderNo, TimeSheetLineNo, Date, Quantity);

        TargetURLPost := LibraryGraphMgt.CreateTargetURL('', PAGE::"Time Registration Entity", '');
        TargetURLPatch := LibraryGraphMgt.CreateTargetURL(TimeSheetDetailId, PAGE::"Time Registration Entity", ServiceNameTxt);

        TimeSheetRegJSON := CreateTimeSheetRegJSONWithExtraProperty(Date, Employee1.SystemId, 'status', 'Submitted');

        // [WHEN] we POST/PATCH the JSON to the web service with a READ-ONLY property
        // [THEN] throw an error
        asserterror LibraryGraphMgt.PostToWebService(TargetURLPost, TimeSheetRegJSON, ResponseText);
        asserterror LibraryGraphMgt.PatchToWebService(TargetURLPatch, LibraryGraphMgt.AddPropertytoJSON('', 'status', 'Submitted'),
            ResponseText);

        TimeSheetRegJSON := CreateTimeSheetRegJSONWithExtraProperty(Date, Employee1.SystemId, 'unitOfMeasureId', CreateGuid);

        // [WHEN] we POST/PATCH the JSON to the web service with a READ-ONLY property
        // [THEN] throw an error
        asserterror LibraryGraphMgt.PostToWebService(TargetURLPost, TimeSheetRegJSON, ResponseText);
        asserterror LibraryGraphMgt.PatchToWebService(TargetURLPatch, LibraryGraphMgt.AddPropertytoJSON('', 'unitOfMeasureId', CreateGuid),
            ResponseText);

        // [WHEN] we POST/PATCH the JSON to the web service with a READ-ONLY property
        // [THEN] throw an error
        asserterror LibraryGraphMgt.PatchToWebService(TargetURLPatch, LibraryGraphMgt.AddPropertytoJSON('', 'employeeId', Employee2.SystemId),
            ResponseText);

        // [WHEN] we POST/PATCH the JSON to the web service with a READ-ONLY property
        // [THEN] throw an error
        asserterror LibraryGraphMgt.PatchToWebService(TargetURLPatch,
            LibraryGraphMgt.AddPropertytoJSON('', 'date', LibraryRandom.RandDate(0)), ResponseText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTemporary()
    var
        EmployeeTimeRegBuffer: Record "Employee Time Reg Buffer";
    begin
        // [GIVEN] an Employee Time Registration Buffer entry
        // [WHEN] trying to insert the value in the temporary table
        // [THEN] throw an error
        asserterror EmployeeTimeRegBuffer.Insert(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmployeeNoAndIdSync()
    var
        Employee: Record Employee;
        TargetURL: Text;
        ResponseText: array[3] of Text;
        TimeSheetRegJSON: array[3] of Text;
        Date: Date;
        AccPeriodStartingDate: Date;
        EmployeeTimeRegBuffId: Text;
    begin
        // [SCENARIO] Create a time reg. entry through a POST method and check if the Employee Id and the Employee No Sync correctly
        Initialize;

        AccPeriodStartingDate := GetAccountingPeriodStartingDate;
        Date := CalcDate('<CW+1D>', AccPeriodStartingDate);

        CreateEmployee(Employee, '');

        // [GIVEN] JSON texts for time reg. entries with and without EmployeeNumber and EmployeeId
        TimeSheetRegJSON[1] := CreateMinimalTimeSheetRegJSON(Date, Employee.SystemId);

        TimeSheetRegJSON[2] := LibraryGraphMgt.AddPropertytoJSON('', 'employeeNumber', Employee."No.");
        TimeSheetRegJSON[2] := LibraryGraphMgt.AddPropertytoJSON(TimeSheetRegJSON[2], 'date', Date);

        TimeSheetRegJSON[3] := CreateMinimalTimeSheetRegJSON(Date, Employee.SystemId);
        TimeSheetRegJSON[3] := LibraryGraphMgt.AddPropertytoJSON(TimeSheetRegJSON[3], 'employeeNumber', Employee."No.");

        Commit;

        // [WHEN] we POST the JSONs to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Time Registration Entity", '');
        LibraryGraphMgt.PostToWebService(TargetURL, TimeSheetRegJSON[2], ResponseText[2]);
        LibraryGraphMgt.PostToWebService(TargetURL, TimeSheetRegJSON[1], ResponseText[1]);
        LibraryGraphMgt.PostToWebService(TargetURL, TimeSheetRegJSON[3], ResponseText[3]);

        // [THEN] the time reg entries created should have the same employee information
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText[1], 'id', EmployeeTimeRegBuffId);
        VerifyEmployee(Employee, LowerCase(LibraryGraphMgt.StripBrackets(EmployeeTimeRegBuffId)));
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText[2], 'id', EmployeeTimeRegBuffId);
        VerifyEmployee(Employee, LowerCase(LibraryGraphMgt.StripBrackets(EmployeeTimeRegBuffId)));
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText[3], 'id', EmployeeTimeRegBuffId);
        VerifyEmployee(Employee, LowerCase(LibraryGraphMgt.StripBrackets(EmployeeTimeRegBuffId)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmployeeNoAndIdSyncThrowsErrors()
    var
        Employee: Record Employee;
        EmployeeId: Guid;
        TargetURL: Text;
        ResponseText: Text;
        TimeSheetRegJSON: array[2] of Text;
        Date: Date;
        AccPeriodStartingDate: Date;
    begin
        // [SCENARIO] Create a time reg. entry through a POST method and check if the Employee Id and the Employee No Sync correctly
        Initialize;

        AccPeriodStartingDate := GetAccountingPeriodStartingDate;
        Date := CalcDate('<CW+1D>', AccPeriodStartingDate);
        EmployeeId := CreateGuid;

        CreateEmployee(Employee, '');
        EmployeeId := Employee.SystemId;
        Employee.Delete;

        // [GIVEN] JSON texts for time reg. entries with and without EmployeeNumber and EmployeeId
        TimeSheetRegJSON[1] := CreateMinimalTimeSheetRegJSON(Date, EmployeeId);

        TimeSheetRegJSON[2] := LibraryGraphMgt.AddPropertytoJSON('', 'employeeNumber', Employee."No.");
        TimeSheetRegJSON[2] := LibraryGraphMgt.AddPropertytoJSON(TimeSheetRegJSON[2], 'date', Date);

        Commit;

        // [WHEN] we POST the JSONs to the web service
        // [THEN] we will get errors because the Employee doesn't exist
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Time Registration Entity", '');
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, TimeSheetRegJSON[1], ResponseText);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, TimeSheetRegJSON[2], ResponseText);
    end;

    local procedure CreateMinimalTimeSheetRegJSON(SampleDate: Date; EmployeeId: Guid): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        Quantity: Decimal;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);

        Quantity := LibraryRandom.RandInt(20);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'employeeId', EmployeeId);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'date', SampleDate);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'quantity', Quantity);
        exit(JSONManagement.WriteObjectToString);
    end;

    local procedure CreateTimeSheetRegJSONWithExtraProperty(SampleDate: Date; EmployeeId: Guid; PropertyName: Text; PropertyValue: Text): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        Quantity: Decimal;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);

        Quantity := LibraryRandom.RandInt(20);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'employeeId', EmployeeId);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'date', SampleDate);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'quantity', Quantity);
        JSONManagement.AddJPropertyToJObject(JsonObject, PropertyName, PropertyValue);
        exit(JSONManagement.WriteObjectToString);
    end;

    local procedure VerifyEmployeeTimeRegBuffIdInJson(JSONTxt: Text): Guid
    var
        EmployeeTimeRegBuffId: Text;
    begin
        Assert.IsTrue(LibraryGraphMgt.GetObjectIDFromJSON(JSONTxt, 'id', EmployeeTimeRegBuffId), 'Could not find Time Registration');
        exit(EmployeeTimeRegBuffId);
    end;

    local procedure CreateTimeSheetHeader(TimeSheetHeaderNo: Code[20]; Date: Date; ResourceNo: Code[20])
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        TimeSheetHeader.Validate("No.", TimeSheetHeaderNo);
        TimeSheetHeader.Validate("Starting Date", Date);
        TimeSheetHeader.Validate("Resource No.", ResourceNo);
        TimeSheetHeader.Validate("Owner User ID", UserId);
        TimeSheetHeader.Validate("Approver User ID", UserId);
        TimeSheetHeader.Insert(true);
        Commit;
    end;

    local procedure CreateTimeSheetLine(TimeSheetHeaderNo: Code[20]; Type: Option): Integer
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        TimeSheetLine.Init;
        TimeSheetLine.Validate("Time Sheet No.", TimeSheetHeaderNo);
        TimeSheetLine.Validate("Line No.", TimeSheetHeader.GetLastLineNo + 10000);
        TimeSheetLine.Validate(Type, Type);
        TimeSheetLine.Validate(Status, TimeSheetLine.Status::Open);
        TimeSheetLine.Insert(true);
        Commit;

        exit(TimeSheetLine."Line No.");
    end;

    local procedure CreateTimeSheetDetail(TimeSheetHeaderNo: Code[20]; TimeSheetLineNo: Integer; Date: Date; Quantity: Decimal): Guid
    var
        TimeSheetDetail: Record "Time Sheet Detail";
    begin
        TimeSheetDetail.Init;
        TimeSheetDetail.Validate("Time Sheet No.", TimeSheetHeaderNo);
        TimeSheetDetail.Validate("Time Sheet Line No.", TimeSheetLineNo);
        TimeSheetDetail.Validate(Date, Date);
        TimeSheetDetail.Validate(Quantity, Quantity);
        TimeSheetDetail.Validate(Status, TimeSheetDetail.Status::Open);
        TimeSheetDetail.Insert(true);
        Commit;

        exit(TimeSheetDetail.Id);
    end;

    local procedure GetAccountingPeriodStartingDate(): Date
    var
        AccountingPeriod: Record "Accounting Period";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
    begin
        // AccountingPeriod.DELETEALL(TRUE);
        LibraryTimeSheet.GetAccountingPeriod(AccountingPeriod);
        Commit;
        exit(AccountingPeriod."Starting Date");
    end;

    local procedure CreateResource(ResourceNo: Code[20])
    var
        Resource: Record Resource;
        UnitOfMeasure: Record "Unit of Measure";
        GraphMgtTimeRegistration: Codeunit "Graph Mgt - Time Registration";
    begin
        Resource.Init;
        Resource.Validate("No.", ResourceNo);
        Resource.Insert;
        if not UnitOfMeasure.Get('HOUR') then begin
            UnitOfMeasure.Validate(Code, 'HOUR');
            UnitOfMeasure.Insert(true);
        end;
        Resource.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Resource.Modify(true);
        GraphMgtTimeRegistration.ModifyResourceToUseTimeSheet(Resource);
        Commit;
    end;

    local procedure CreateEmployee(var Employee: Record Employee; ResourceNo: Code[20])
    begin
        if ResourceNo <> '' then
            Employee.Validate("Resource No.", ResourceNo);
        Employee.Insert(true);
        Commit;
    end;

    local procedure CleanTableData()
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetHeader: Record "Time Sheet Header";
        Employee: Record Employee;
        Resource: Record Resource;
    begin
        TimeSheetDetail.DeleteAll;
        TimeSheetLine.DeleteAll;
        TimeSheetHeader.DeleteAll;
        Employee.DeleteAll;
        Resource.DeleteAll;
    end;

    local procedure VerifyTimeSheetSync(EmployeeTimeRegBuffId: Guid; NewResource: Boolean)
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetHeader: Record "Time Sheet Header";
        Resource: Record Resource;
    begin
        Resource.Reset;
        TimeSheetHeader.Reset;
        TimeSheetLine.Reset;
        TimeSheetDetail.Reset;

        TimeSheetDetail.SetRange(Id, EmployeeTimeRegBuffId);
        Assert.IsTrue(TimeSheetDetail.FindFirst, 'Time Sheet Detail was not created');
        TimeSheetHeader.SetRange("No.", TimeSheetDetail."Time Sheet No.");
        Assert.IsTrue(TimeSheetHeader.FindFirst, 'Time Sheet Header was not created');
        TimeSheetLine.SetRange("Line No.", TimeSheetDetail."Time Sheet Line No.");
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        Assert.IsTrue(TimeSheetLine.FindFirst, 'Time Sheet Line was not created');

        if NewResource then begin
            Resource.Get(TimeSheetHeader."Resource No.");
            Assert.IsTrue((Resource."Gen. Prod. Posting Group" = 'SERVICES') and
              (Resource."Base Unit of Measure" = 'HOUR'), 'Resource Template has not been applied');
        end;
    end;

    local procedure VerifyGetProperties(ResponseText: Text; EmployeeId: Guid; Date: Date; ResourceNo: Code[20]; TimeSheetDetailId: Guid)
    var
        Resource: Record Resource;
        Employee: Record Employee;
        TimeSheetDetail: Record "Time Sheet Detail";
        UnitOfMeasure: Record "Unit of Measure";
        RespEmployeeId: Text;
        RespEmployeeNumber: Text;
        RespDate: Text;
        RespStatus: Text;
        RespUnitOfMeasure: Text;
        RespUnitOfMeasureJSON: Text;
    begin
        Assert.AreNotEqual('', ResponseText, 'JSON Should not be blank');
        VerifyEmployeeTimeRegBuffIdInJson(ResponseText);
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'date', RespDate);
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'employeeId', RespEmployeeId);
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'employeeNumber', RespEmployeeNumber);
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'unitOfMeasureId', RespUnitOfMeasure);
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'unitOfMeasure', RespUnitOfMeasureJSON);
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'status', RespStatus);
        Assert.AreEqual(CopyStr(RespDate, 3), Format(Date, 0, '<Closing><Year,2>-<Month,2>-<Day,2>'), 'Incorrect date');
        Assert.AreEqual(RespEmployeeId, LowerCase(LibraryGraphMgt.StripBrackets(Format(EmployeeId))), 'Incorrect employee ID');

        Employee.Reset;
        Employee.SetRange(Id, RespEmployeeId);
        Employee.FindFirst;
        Assert.AreEqual(RespEmployeeNumber, Employee."No.", 'Incorrect employee number');
        Resource.Get(ResourceNo);
        UnitOfMeasure.Get(Resource."Base Unit of Measure");
        Assert.AreEqual(LowerCase(LibraryGraphMgt.StripBrackets(UnitOfMeasure.Id)), RespUnitOfMeasure, 'Incorrect Unit Of Measure');
        Assert.IsFalse(RespUnitOfMeasureJSON = '', 'Unit of Measure JSON is empty');
        Assert.IsSubstring(RespUnitOfMeasureJSON, Resource."Base Unit of Measure");
        TimeSheetDetail.SetRange(Id, TimeSheetDetailId);
        TimeSheetDetail.FindFirst;
        Assert.AreEqual(Format(TimeSheetDetail.Status), RespStatus, 'Incorrect Status');
    end;

    local procedure VerifyEmployee(Employee: Record Employee; TimeSheetDetailId: Guid)
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetHeader: Record "Time Sheet Header";
        ActualEmployee: Record Employee;
    begin
        TimeSheetDetail.SetRange(Id, TimeSheetDetailId);
        TimeSheetDetail.FindFirst;
        TimeSheetHeader.Get(TimeSheetDetail."Time Sheet No.");
        ActualEmployee.SetRange("Resource No.", TimeSheetHeader."Resource No.");
        ActualEmployee.FindFirst;

        Assert.AreEqual(Employee.Id, ActualEmployee.Id, 'Incorrect Employee');
    end;

    local procedure InsertTemplate(var ConfigTemplateHeader: Record "Config. Template Header"; Description: Text[50]; GenProdGroup: Code[20]; BaseUOM: Code[10])
    var
        Resource: Record Resource;
        ConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        NextLineNo: Integer;
    begin
        ConfigTemplateHeader.Code := ConfigTemplateManagement.GetNextAvailableCode(DATABASE::Resource);
        ConfigTemplateHeader.Description := Description;
        ConfigTemplateHeader."Table ID" := DATABASE::Resource;
        ConfigTemplateHeader.Insert;
        NextLineNo := 10000;
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        if ConfigTemplateLine.FindLast then
            NextLineNo := ConfigTemplateLine."Line No." + 10000;

        ConfigTemplateLine.Init;
        ConfigTemplateLine.Validate("Data Template Code", ConfigTemplateHeader.Code);
        ConfigTemplateLine.Validate("Line No.", NextLineNo);
        ConfigTemplateLine.Validate(Type, ConfigTemplateLine.Type::Field);
        ConfigTemplateLine.Validate("Table ID", ConfigTemplateHeader."Table ID");
        ConfigTemplateLine.Validate("Field ID", Resource.FieldNo("Gen. Prod. Posting Group"));
        ConfigTemplateLine."Default Value" := GenProdGroup;
        ConfigTemplateLine.Insert(true);
        NextLineNo := 10000;
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        if ConfigTemplateLine.FindLast then
            NextLineNo := ConfigTemplateLine."Line No." + 10000;

        ConfigTemplateLine.Init;
        ConfigTemplateLine.Validate("Data Template Code", ConfigTemplateHeader.Code);
        ConfigTemplateLine.Validate("Line No.", NextLineNo);
        ConfigTemplateLine.Validate(Type, ConfigTemplateLine.Type::Field);
        ConfigTemplateLine.Validate("Table ID", ConfigTemplateHeader."Table ID");
        ConfigTemplateLine.Validate("Field ID", Resource.FieldNo("Base Unit of Measure"));
        ConfigTemplateLine."Default Value" := BaseUOM;
        ConfigTemplateLine.Insert(true);
    end;

    local procedure CreateTimeRegEntriesURLWithDateFilter(StartingDate: Date; EndingDate: Date): Text
    var
        TargetURL: Text;
        UrlFilter: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Time Registration Entity", '');

        UrlFilter := '$filter=date gt ' + Format(StartingDate, 0, '<Year4>-<Month,2>-<Day,2>') +
          ' and date lt ' + Format(EndingDate, 0, '<Year4>-<Month,2>-<Day,2>');

        if StrPos(TargetURL, '?') <> 0 then
            TargetURL := TargetURL + '&' + UrlFilter
        else
            TargetURL := TargetURL + '?' + UrlFilter;

        exit(TargetURL);
    end;

    local procedure CreateTimeRegEntriesURLWithEmployeeFilter(EmployeeId: Guid): Text
    var
        TargetURL: Text;
        UrlFilter: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Time Registration Entity", '');

        UrlFilter := '$filter=employeeId eq ' + LowerCase(LibraryGraphMgt.StripBrackets(EmployeeId));

        if StrPos(TargetURL, '?') <> 0 then
            TargetURL := TargetURL + '&' + UrlFilter
        else
            TargetURL := TargetURL + '?' + UrlFilter;

        exit(TargetURL);
    end;
}

