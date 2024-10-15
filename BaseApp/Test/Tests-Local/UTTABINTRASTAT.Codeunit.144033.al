codeunit 144033 "UT TAB INTRASTAT"
{
    // Test for feature - INTRASTAT.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        ShipmentMethodMsg: Label 'The French Intrastat feature requires a Shipment Method Code of 3 letters and 1 number.';
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('ShipmentMethodMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCodeWithExceededLimitShipmentMethod()
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        // Purpose of this test is to validate Trigger OnValidate of Code for Table ID 10 - Shipment Method.

        // Setup.
        // Exercise & Verify: Verify Message in ShipmentMethodMessageHandler.
        ShipmentMethod.Validate(Code, LibraryUTUtility.GetNewCode10);  // Code length more than 4 Char.
    end;

    [Test]
    [HandlerFunctions('ShipmentMethodMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCodeWithNumberShipmentMethod()
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        // Purpose of this test is to validate Trigger OnValidate of Code for Table ID 10 - Shipment Method.

        // Setup.
        // Exercise & Verify: Verify Message in ShipmentMethodMessageHandler.
        ShipmentMethod.Validate(Code, Format(LibraryRandom.RandIntInRange(1000, 9999)));  // Code length 4 Char - all are numeric value.
    end;

    [Test]
    [HandlerFunctions('ShipmentMethodMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCodeWithLetterShipmentMethod()
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        // Purpose of this test is to validate Trigger OnValidate of Code for Table ID 10 - Shipment Method.

        // Setup.
        // Exercise & Verify: Verify Message in ShipmentMethodMessageHandler.
        ShipmentMethod.Validate(Code, ShipmentMethod.FieldCaption(Code));  // Code Caption for 4 Char - all are letters value.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ShipmentMethodMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, ShipmentMethodMsg) > 0, Message);
    end;
}

