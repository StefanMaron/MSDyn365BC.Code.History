codeunit 135506 "ShipmentMethod Entity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Shipment Method]
    end;

    var
        ServiceNameTxt: Label 'shipmentMethods';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        DescriptionTxt: Label 'My description.';

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVerifyIDandLastDateModified()
    var
        ShipmentMethod: Record "Shipment Method";
        IntegrationRecord: Record "Integration Record";
        ShipmentMethodCode: Code[10];
        ShipmentMethodId: Guid;
    begin
        // [SCENARIO] Create a Shipment Method and verify it has Id and Last Modified Date Time
        // [GIVEN] a modified Shipment Method record
        Initialize;
        CreateShipmentMethod(ShipmentMethod);
        ShipmentMethodCode := ShipmentMethod.Code;
        Commit;

        // [WHEN] we retrieve the Shipment Method from the database
        ShipmentMethod.Reset;
        ShipmentMethod.Get(ShipmentMethodCode);
        ShipmentMethodId := ShipmentMethod.Id;

        // [THEN] the Shipment Method should have an integration id and last date time modified
        IntegrationRecord.Get(ShipmentMethodId);
        IntegrationRecord.TestField("Integration ID");
        ShipmentMethod.TestField("Last Modified Date Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetShipmentMethods()
    var
        ShipmentMethod: Record "Shipment Method";
        ShipmentMethodCode: array[2] of Code[10];
        ShipmentMethodJSON: array[2] of Text;
        TargetURL: Text;
        ResponseText: Text;
        "Count": Integer;
    begin
        // [SCENARIO] Create Shipment Methods and use a GET method to retrieve them
        // [GIVEN] 2 Shipment Methods in the Shipment Method Table
        Initialize;
        for Count := 1 to 2 do begin
            CreateShipmentMethod(ShipmentMethod);
            ShipmentMethodCode[Count] := ShipmentMethod.Code;
        end;
        Commit;

        // [WHEN] we GET all the payment terms from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Shipment Method Entity", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 payment terms should exist in the response
        for Count := 1 to 2 do
            GetAndVerifyIDFromJSON(ResponseText, ShipmentMethodCode[Count], ShipmentMethodJSON[Count]);
    end;

    [Normal]
    local procedure GetAndVerifyIDFromJSON(ResponseText: Text; ShipmentMethodCode: Text; var ShipmentMethodJSON: Text)
    begin
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(
            ResponseText, 'code', ShipmentMethodCode, ShipmentMethodCode, ShipmentMethodJSON, ShipmentMethodJSON),
          'Could not find the Shipment Method in JSON');
        LibraryGraphMgt.VerifyIDInJson(ShipmentMethodJSON);
    end;

    local procedure CreateShipmentMethod(var ShipmentMethod: Record "Shipment Method")
    begin
        with ShipmentMethod do begin
            Init;
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Shipment Method");
            Description := DescriptionTxt;
            Insert(true);
        end;
    end;
}

