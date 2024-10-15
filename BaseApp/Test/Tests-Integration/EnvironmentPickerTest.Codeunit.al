// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 132677 "Environment Picker Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        LibraryAssert: Codeunit "Library Assert";
        FlowServiceManagement: Codeunit "Flow Service Management";
        EnvironmentIdTxt: Label 'environment-id', Locked = true;
        EnvironmentNameTxt: Label 'environment name', Locked = true;

    [Test]
    procedure CheckTheBasicBehaviour()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        EnvironmentId: Text[50];
        EnvironmentName: Text[100];
    begin
        // [START] Check if environment does not exist
        LibraryAssert.isFalse(FlowServiceManagement.HasUserSelectedFlowEnvironment(), 'There are some flows for assigned to this user');

        // [GIVEN] Add some environment 
        EnvironmentId := EnvironmentIdTxt;
        EnvironmentName := EnvironmentNameTxt;
        TempFlowUserEnvironmentBuffer."Environment ID" := EnvironmentId;
        TempFlowUserEnvironmentBuffer."Environment Display Name" := EnvironmentName;
        FlowServiceManagement.SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer);

        // [THEN] The environment is set correctly, check returned values
        LibraryAssert.AreEqual(EnvironmentIdTxt, FlowServiceManagement.GetFlowEnvironmentID(), 'The environment id was set incorrectly');
        LibraryAssert.AreEqual(EnvironmentNameTxt, FlowServiceManagement.GetSelectedFlowEnvironmentName(), 'The environment name was set incorrectly');

    end;

    [Test]
    procedure AdminCanSetForAll()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        EnvironmentId: Text[50];
        EnvironmentName: Text[100];
    begin
        // [WHEN] Admin sets the environment
        EnvironmentId := EnvironmentIdTxt;
        EnvironmentName := EnvironmentNameTxt;
        TempFlowUserEnvironmentBuffer."Environment ID" := EnvironmentId;
        TempFlowUserEnvironmentBuffer."Environment Display Name" := EnvironmentName;
        FlowServiceManagement.SaveFlowEnvironmentSelectionForAll(TempFlowUserEnvironmentBuffer);

        // [THEN] The environment is set correctly, check returned values
        LibraryAssert.AreEqual(EnvironmentIdTxt, FlowServiceManagement.GetFlowEnvironmentID(), 'The environment id was set incorrectly');
        LibraryAssert.AreEqual(EnvironmentNameTxt, FlowServiceManagement.GetSelectedFlowEnvironmentName(), 'The environment name was set incorrectly');

    end;

    [Test]
    procedure CheckAdminCanOverrideForAll()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        EnvironmentId: Text[50];
        EnvironmentName: Text[100];
    begin
        // [START] Add some environment as a user
        TempFlowUserEnvironmentBuffer."Environment ID" := 'user-choice-id';
        TempFlowUserEnvironmentBuffer."Environment Display Name" := 'user-choice-name';
        FlowServiceManagement.SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer);

        // [WHEN] Admin overrides the environment
        EnvironmentId := EnvironmentIdTxt;
        EnvironmentName := EnvironmentNameTxt;
        TempFlowUserEnvironmentBuffer."Environment ID" := EnvironmentId;
        TempFlowUserEnvironmentBuffer."Environment Display Name" := EnvironmentName;
        FlowServiceManagement.SaveFlowEnvironmentSelectionForAll(TempFlowUserEnvironmentBuffer);

        // [THEN] The environment is set correctly, check returned values
        LibraryAssert.AreEqual(EnvironmentIdTxt, FlowServiceManagement.GetFlowEnvironmentID(), 'The environment id was set incorrectly');
        LibraryAssert.AreEqual(EnvironmentNameTxt, FlowServiceManagement.GetSelectedFlowEnvironmentName(), 'The environment name was set incorrectly');

    end;

    [Test]
    procedure CheckUserCanOverrideDefaultChoice()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        EnvironmentId: Text[50];
        EnvironmentName: Text[100];
    begin
        // [START] Add some environment as an admin
        TempFlowUserEnvironmentBuffer."Environment ID" := 'default-choice-id';
        TempFlowUserEnvironmentBuffer."Environment Display Name" := 'default-choice-name';
        FlowServiceManagement.SaveFlowEnvironmentSelectionForAll(TempFlowUserEnvironmentBuffer);

        // [WHEN] User overrides the environment
        EnvironmentId := EnvironmentIdTxt;
        EnvironmentName := EnvironmentNameTxt;
        TempFlowUserEnvironmentBuffer."Environment ID" := EnvironmentId;
        TempFlowUserEnvironmentBuffer."Environment Display Name" := EnvironmentName;
        FlowServiceManagement.SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer);

        // [THEN] The environment is set correctly, check returned values
        LibraryAssert.AreEqual(EnvironmentIdTxt, FlowServiceManagement.GetFlowEnvironmentID(), 'The environment id was set incorrectly');
        LibraryAssert.AreEqual(EnvironmentNameTxt, FlowServiceManagement.GetSelectedFlowEnvironmentName(), 'The environment name was set incorrectly');

    end;
}
