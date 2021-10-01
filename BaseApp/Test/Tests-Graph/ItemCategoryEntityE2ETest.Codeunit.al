#if not CLEAN18
codeunit 135508 "Item Category Entity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Item Category]
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'itemCategories';
        ItemCategoryPrefixTxt: Label 'GRAPHITEMCAT';
        EmptyJSONErr: Label 'The JSON should not be blank.';
        WrongPropertyValueErr: Label 'Incorrect property value for %1.';

    [Test]
    [Scope('OnPrem')]
    procedure TestGetItemCategories()
    var
        ItemCategoryCode: array[2] of Text;
        ItemCategoryJSON: array[2] of Text;
        ResponseText: Text;
        TargetURL: Text;
        "Count": Integer;
    begin
        // [SCENARIO] User can retrieve all Item Category records from the Item Categories API.
        Initialize;

        // [GIVEN] 2 item categories in the Item Category Table
        for Count := 1 to 2 do
            ItemCategoryCode[Count] := CreateItemCategory;

        // [WHEN] A GET request is made to the Item Categories API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Item Categories Entity", ServiceNameTxt);

        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 item categories should exist in the response
        for Count := 1 to 2 do
            GetAndVerifyIDFromJSON(ResponseText, ItemCategoryCode[Count], ItemCategoryJSON[Count]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateItemCategory()
    var
        ItemCategory: Record "Item Category";
        TempItemCategory: Record "Item Category" temporary;
        ItemCategoryJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create an item category through a POST method and check if it was created
        Initialize;

        // [GIVEN] The user has constructed an item category JSON object to send to the service.
        ItemCategoryJSON := GetItemCategoryJSON(TempItemCategory);

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Item Categories Entity", ServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, ItemCategoryJSON, ResponseText);

        // [THEN] The response text contains the Item Category information.
        VerifyItemCategoryProperties(ResponseText, TempItemCategory);

        // [THEN] The Item Category has been created in the database.
        ItemCategory.Get(TempItemCategory.Code);
        VerifyItemCategoryProperties(ResponseText, ItemCategory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyItemCategory()
    var
        ItemCategory: Record "Item Category";
        RequestBody: Text;
        ResponseText: Text;
        TargetURL: Text;
        ItemCategoryCode: Text;
    begin
        // [SCENARIO] User can modify an item category through a PATCH request.
        Initialize;

        // [GIVEN] An Item Category exists.
        ItemCategoryCode := CreateItemCategory;
        ItemCategory.Get(ItemCategoryCode);
        ItemCategory.Description := LibraryUtility.GenerateGUID;
        RequestBody := GetItemCategoryJSON(ItemCategory);

        // [WHEN] The user makes a patch request to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL(ItemCategory.SystemId, PAGE::"Item Categories Entity", ServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, RequestBody, ResponseText);

        // [THEN] The response text contains the new values.
        VerifyItemCategoryProperties(ResponseText, ItemCategory);

        // [THEN] The record in the database contains the new values.
        ItemCategory.Get(ItemCategory.Code);
        VerifyItemCategoryProperties(ResponseText, ItemCategory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteItemCategory()
    var
        ItemCategory: Record "Item Category";
        ItemCategoryCode: Text;
        TargetURL: Text;
        Responsetext: Text;
    begin
        // [SCENARIO] User can delete an item category by making a DELETE request.
        Initialize;

        // [GIVEN] An item category exists.
        ItemCategoryCode := CreateItemCategory;
        ItemCategory.Get(ItemCategoryCode);

        // [WHEN] The user makes a DELETE request to the endpoint for the item category.
        TargetURL := LibraryGraphMgt.CreateTargetURL(ItemCategory.SystemId, PAGE::"Item Categories Entity", ServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', Responsetext);

        // [THEN] The response is empty.
        Assert.AreEqual('', Responsetext, 'DELETE response should be empty.');

        // [THEN] The item category is no longer in the database.
        Assert.IsFalse(ItemCategory.Get(ItemCategoryCode), 'Item Category should be deleted.');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure CreateItemCategory(): Text
    var
        ItemCategory: Record "Item Category";
    begin
        LibraryInventory.CreateItemCategory(ItemCategory);
        Commit();

        exit(ItemCategory.Code);
    end;

    local procedure GetAndVerifyIDFromJSON(ResponseText: Text; ItemCategoryCode: Text; ItemCategoryJSON: Text)
    begin
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(ResponseText, 'code', ItemCategoryCode, ItemCategoryCode,
            ItemCategoryJSON, ItemCategoryJSON), 'Could not find the item category in JSON');
        LibraryGraphMgt.VerifyIDInJson(ItemCategoryJSON);
    end;

    local procedure GetNextItemCategoryID(): Code[20]
    var
        ItemCategory: Record "Item Category";
    begin
        ItemCategory.SetFilter(Code, StrSubstNo('%1*', ItemCategoryPrefixTxt));
        if ItemCategory.FindLast then
            exit(IncStr(ItemCategory.Code));

        exit(CopyStr(ItemCategoryPrefixTxt + '00001', 1, 20));
    end;

    local procedure GetItemCategoryJSON(var ItemCategory: Record "Item Category") ItemCategoryJSON: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);
        if ItemCategory.Code = '' then
            ItemCategory.Code := GetNextItemCategoryID;
        if ItemCategory.Description = '' then
            ItemCategory.Description := LibraryUtility.GenerateGUID;
        JSONManagement.AddJPropertyToJObject(JsonObject, 'code', ItemCategory.Code);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'displayName', ItemCategory.Description);
        ItemCategoryJSON := JSONManagement.WriteObjectToString;
    end;

    local procedure VerifyPropertyInJSON(JSON: Text; PropertyName: Text; ExpectedValue: Text)
    var
        PropertyValue: Text;
    begin
        LibraryGraphMgt.GetObjectIDFromJSON(JSON, PropertyName, PropertyValue);
        Assert.AreEqual(ExpectedValue, PropertyValue, StrSubstNo(WrongPropertyValueErr, PropertyName));
    end;

    local procedure VerifyItemCategoryProperties(ItemCategoryJSON: Text; ItemCategory: Record "Item Category")
    begin
        Assert.AreNotEqual('', ItemCategoryJSON, EmptyJSONErr);
        LibraryGraphMgt.VerifyIDInJson(ItemCategoryJSON);
        VerifyPropertyInJSON(ItemCategoryJSON, 'code', ItemCategory.Code);
        VerifyPropertyInJSON(ItemCategoryJSON, 'displayName', ItemCategory.Description);
    end;
}
#endif
