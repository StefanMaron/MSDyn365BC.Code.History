codeunit 135516 "UofM E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Unit of Measure]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        WrongPropertyValueErr: Label 'Incorrect property value for %1';
        LibraryUtility: Codeunit "Library - Utility";
        ServiceNameTxt: Label 'unitsOfMeasure';

    [Test]
    [Scope('OnPrem')]
    procedure TestGetUnitOfMeasure()
    var
        UnitOfMeasure: Record "Unit of Measure";
        Response: Text;
    begin
        // [SCENARIO] User can get the units of measure.

        // [GIVEN] Units of measure.
        GenerateUnitsOfMeasure(UnitOfMeasure, 5);

        // [WHEN] A GET request is made of the service.
        LibraryGraphMgt.GetFromWebService(Response, GetServiceUrlForEntity(UnitOfMeasure.SystemId));

        // [THEN] The response contains the entity requested.
        ValidateUnitOfMeasure(UnitOfMeasure, Response);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyUnitOfMeasure()
    var
        UnitOfMeasure: Record "Unit of Measure";
        Request: Text;
        Response: Text;
        OldDescription: Text;
    begin
        // [SCENARIO] User can update a unit of measure.

        // [GIVEN] Units of measure.
        GenerateUnitsOfMeasure(UnitOfMeasure, 5);

        // [GIVEN] One is modified with a new description.
        OldDescription := UnitOfMeasure.Description;
        Request := CreateModifyUnitOfMeasureRequest(UnitOfMeasure);

        // [GIVEN] The request contains a different description from the original Unit of Measure.
        Assert.AreNotEqual(UnitOfMeasure.Description, OldDescription, StrSubstNo(WrongPropertyValueErr, 'displayName'));

        // [WHEN] A PATCH is made against the entity.
        LibraryGraphMgt.PatchToWebService(GetServiceUrlForEntity(UnitOfMeasure.SystemId), Request, Response);

        // [THEN] The response matches the data given in the request.
        ValidateUnitOfMeasure(UnitOfMeasure, Response);

        // [THEN] The response matches the latest data in the database.
        UnitOfMeasure.Get(UnitOfMeasure.Code);
        ValidateUnitOfMeasure(UnitOfMeasure, Response);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteUnitOfMeasure()
    var
        UnitOfMeasure: Record "Unit of Measure";
        Response: Text;
    begin
        // [SCENARIO] User can delete a unit of measure.

        // [GIVEN] Units of measure.
        GenerateUnitsOfMeasure(UnitOfMeasure, 5);

        // [WHEN] A DEELTE is made against an entity.
        LibraryGraphMgt.DeleteFromWebService(GetServiceUrlForEntity(UnitOfMeasure.SystemId), '', Response);

        // [THEN] The response is empty and the data is no longer in the table.
        Assert.AreEqual('', Response, 'Expected empty response for DELETE.');
        Assert.IsFalse(UnitOfMeasure.Get, 'Expected data in table to be missing.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertUnitOfMeasure()
    var
        UnitOfMeasure: Record "Unit of Measure";
        Response: Text;
        Request: Text;
        "Code": Text;
    begin
        // [SCENARIO] User can insert a unit of measure.

        // [GIVEN] A new unit of measure.
        GenerateUnitOfMeasure(UnitOfMeasure);
        Request := CreateInsertUnitOfMeasureRequest(UnitOfMeasure);

        // [WHEN] A POST is made against an entity.
        LibraryGraphMgt.PostToWebService(GetServiceUrl, Request, Response);

        // [THEN] The entity is in the table.
        UnitOfMeasure.Init();
        LibraryGraphMgt.GetObjectIDFromJSON(Response, 'code', Code);
        UnitOfMeasure.Get(Code);

        ValidateUnitOfMeasure(UnitOfMeasure, Response);
    end;

    local procedure GenerateUnitsOfMeasure(var UnitOfMeasure: Record "Unit of Measure"; "Count": Integer)
    var
        i: Integer;
    begin
        for i := 0 to Count do begin
            GenerateUnitOfMeasure(UnitOfMeasure);
            UnitOfMeasure.Insert(true);
        end;
        Commit();
    end;

    local procedure GenerateUnitOfMeasure(var UnitOfMeasure: Record "Unit of Measure")
    begin
        UnitOfMeasure.Init();
        UnitOfMeasure.Validate(Code, LibraryUtility.GenerateRandomCode(UnitOfMeasure.FieldNo(Code), DATABASE::"Unit of Measure"));
        UnitOfMeasure.Validate(Description, LibraryUtility.GenerateRandomAlphabeticText(10, 1));
        UnitOfMeasure.Validate(
          "International Standard Code",
          LibraryUtility.GenerateRandomCode(UnitOfMeasure.FieldNo("International Standard Code"), DATABASE::"Unit of Measure"));
        UnitOfMeasure.Validate(Symbol, LibraryUtility.GenerateRandomCode(UnitOfMeasure.FieldNo(Symbol), DATABASE::"Unit of Measure"));
    end;

    local procedure CreateModifyUnitOfMeasureRequest(var UnitOfMeasure: Record "Unit of Measure") RequestJSON: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JSONObject: DotNet JObject;
        NewName: Text[10];
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JSONObject);

        NewName := Format(LibraryUtility.GenerateRandomAlphabeticText(10, 1), 10);
        JSONManagement.AddJPropertyToJObject(JSONObject, 'id', UnitOfMeasure.SystemId);
        JSONManagement.AddJPropertyToJObject(JSONObject, 'displayName', NewName);

        UnitOfMeasure.Validate(Description, NewName);

        RequestJSON := JSONManagement.WriteObjectToString;
    end;

    local procedure CreateInsertUnitOfMeasureRequest(var UnitOfMeasure: Record "Unit of Measure") RequestJSON: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JSONObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JSONObject);

        JSONManagement.AddJPropertyToJObject(JSONObject, 'displayName', UnitOfMeasure.Description);
        JSONManagement.AddJPropertyToJObject(JSONObject, 'code', UnitOfMeasure.Code);
        JSONManagement.AddJPropertyToJObject(JSONObject, 'internationalStandardCode', UnitOfMeasure."International Standard Code");

        RequestJSON := JSONManagement.WriteObjectToString;
    end;

    local procedure GetServiceUrlForEntity(Id: Guid) Url: Text
    begin
        Url := LibraryGraphMgt.CreateTargetURL(Id, PAGE::"Units of Measure Entity", ServiceNameTxt);
    end;

    local procedure GetServiceUrl() Url: Text
    begin
        Url := LibraryGraphMgt.GetODataTargetURL(ObjectType::Page, PAGE::"Units of Measure Entity")
    end;

    local procedure ValidateUnitOfMeasure(var UnitOfMeasure: Record "Unit of Measure"; Response: Text)
    var
        Id: Text;
    begin
        LibraryGraphMgt.GetObjectIDFromJSON(Response, 'id', Id);
        Assert.AreNotEqual('00000000-0000-0000-000000000000', Id, StrSubstNo(WrongPropertyValueErr, 'id'));
        ValidateUserSettableProperties(UnitOfMeasure, Response);
    end;

    local procedure ValidateUserSettableProperties(var UnitOfMeasure: Record "Unit of Measure"; Response: Text)
    var
        "Code": Text;
        DisplayName: Text;
        InternationalStandardCode: Text;
    begin
        LibraryGraphMgt.GetObjectIDFromJSON(Response, 'code', Code);
        LibraryGraphMgt.GetObjectIDFromJSON(Response, 'displayName', DisplayName);
        LibraryGraphMgt.GetObjectIDFromJSON(Response, 'internationalStandardCode', InternationalStandardCode);

        Assert.AreEqual(Format(UnitOfMeasure.Code), Code, StrSubstNo(WrongPropertyValueErr, 'code'));
        Assert.AreEqual(Format(UnitOfMeasure.Description), DisplayName, StrSubstNo(WrongPropertyValueErr, 'displayName'));
        Assert.AreEqual(
          Format(UnitOfMeasure."International Standard Code"), InternationalStandardCode,
          StrSubstNo(WrongPropertyValueErr, 'internationalStandardCode'));
    end;
}

