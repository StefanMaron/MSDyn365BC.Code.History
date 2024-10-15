codeunit 145019 "EET UT"
{
    // // [FEATURE] [EET] [UT]

    Subtype = Test;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryEET: Codeunit "Library - EET";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        EntryExistsErr: Label 'You cannot delete %1 %2 because there is at least one EET entry.', Comment = '%1 = Table Caption;%2 = Primary Key';
        ProductionEnvironmentQst: Label 'There are still unprocessed EET Entries.\Entering the URL of the production environment, these entries will be registered in a production environment!\\ Do you want to continue?';
        NonproductionEnvironmentQst: Label 'There are still unprocessed EET Entries.\Entering the URL of the non-production environment, these entries will be registered in a non-production environment!\\ Do you want to continue?';
        EETCashRegisterMustBeDeletedErr: Label 'EET Cash Register must be deleted.';
        ServiceURLMustBeFilledByPGURLErr: Label 'Service URL must be filled by playground URL.';
        ServiceURLMustBeErr: Label 'Service URL must be "%1".';

    [Test]
    [Scope('OnPrem')]
    procedure DeleteEETBusinessPremisesWithEETEntries()
    var
        EETBusinessPremises: Record "EET Business Premises";
    begin
        // [SCENARIO] Delete EET business premises with posted EET entries
        // [GIVEN] Create EET business premises
        // [GIVEN] Create EET entries for created EET business premises
        Initialize;
        CreateEETBusinessPremises(EETBusinessPremises);
        CreateFakeEntries(EETBusinessPremises.Code, '');

        // [WHEN] Delete EET business premises
        asserterror EETBusinessPremises.Delete(true);

        // [THEN] Error occurs
        Assert.ExpectedError(StrSubstNo(EntryExistsErr, EETBusinessPremises.TableCaption, EETBusinessPremises.Code));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteEETBusinessPremises()
    var
        EETBusinessPremises: Record "EET Business Premises";
        EETCashRegister: Record "EET Cash Register";
    begin
        // [SCENARIO] Delete EET business premises without posted EET entries
        // [GIVEN] Create EET business premises
        // [GIVEN] Create EET cash register for created EET business premises
        Initialize;
        CreateEETBusinessPremises(EETBusinessPremises);
        CreateEETCashRegister(EETCashRegister, EETBusinessPremises.Code);

        // [WHEN] Delete EET business premises
        EETBusinessPremises.Delete(true);

        // [THEN] EET cash register must be deleted
        Assert.IsFalse(
          EETCashRegister.Get(EETCashRegister."Business Premises Code", EETCashRegister.Code), EETCashRegisterMustBeDeletedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteEETCashRegisterWithEETEntries()
    var
        EETBusinessPremises: Record "EET Business Premises";
        EETCashRegister: Record "EET Cash Register";
    begin
        // [SCENARIO] Delete EET cash register with posted EET entries
        // [GIVEN] Create EET business premises
        // [GIVEN] Create EET cash register
        // [GIVEN] Create EET entries for created EET cash register
        Initialize;
        CreateEETBusinessPremises(EETBusinessPremises);
        CreateEETCashRegister(EETCashRegister, EETBusinessPremises.Code);
        CreateFakeEntries(EETCashRegister."Business Premises Code", EETCashRegister.Code);

        // [WHEN] Delete EET business premises
        asserterror EETCashRegister.Delete(true);

        // [THEN] Error occurs
        Assert.ExpectedError(StrSubstNo(EntryExistsErr, EETCashRegister.TableCaption, EETCashRegister.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitEETServiceSetup()
    var
        EETServiceSetup: Record "EET Service Setup";
        EETServiceMgt: Codeunit "EET Service Mgt.";
    begin
        // [SCENARIO] Initialize new EET service setup
        // [GIVEN] Delete actual EET service setup
        Initialize;

        EETServiceSetup.Get();
        EETServiceSetup.Delete(true);

        // [WHEN] Insert new EET service setup
        EETServiceSetup.Init();
        EETServiceSetup.Insert(true);

        // [THEN] Service URL must be filled by playground URL from EET Service Mgt.
        Assert.AreEqual(
          EETServiceMgt.GetWebServicePlayGroundURLTxt, EETServiceSetup."Service URL", ServiceURLMustBeFilledByPGURLErr);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SetProductionServiceURLToEETServiceSetup()
    var
        EETServiceMgt: Codeunit "EET Service Mgt.";
    begin
        // [SCENARIO] Set production service URL to EET service setup
        SetURLToServiceSetup(EETServiceMgt.GetWebServiceURLTxt);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SetNonproductionServiceURLToEETServiceSetup()
    var
        EETServiceMgt: Codeunit "EET Service Mgt.";
    begin
        // [SCENARIO] Set nonproduction service URL to EET service setup
        SetURLToServiceSetup(EETServiceMgt.GetWebServicePlayGroundURLTxt);
    end;

    local procedure SetURLToServiceSetup(ServiceURL: Text)
    var
        EETServiceSetup: Record "EET Service Setup";
        EETServiceMgt: Codeunit "EET Service Mgt.";
    begin
        // [GIVEN] Create EET entries in state "Send Pending"
        Initialize;

        CreateFakeEntries('', '');

        // [WHEN] SetURLToDefault is called
        case ServiceURL of
            EETServiceMgt.GetWebServiceURLTxt:
                LibraryVariableStorage.Enqueue(1);
            EETServiceMgt.GetWebServicePlayGroundURLTxt:
                LibraryVariableStorage.Enqueue(2);
        end;

        LibraryVariableStorage.Enqueue(ServiceURL);
        EETServiceSetup.SetURLToDefault(true);

        // [THEN] Service URL is filled as expected
        Assert.AreEqual(ServiceURL, EETServiceSetup."Service URL", StrSubstNo(ServiceURLMustBeErr, ServiceURL));
        // Next checks are in the Confirm Handler
    end;

    local procedure Initialize()
    var
        EETServiceSetup: Record "EET Service Setup";
    begin
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;

        if not EETServiceSetup.Get then begin
            EETServiceSetup.Init();
            EETServiceSetup.Insert(true);
        end;

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"EET Service Setup");
    end;

    local procedure CreateEETBusinessPremises(var EETBusinessPremises: Record "EET Business Premises")
    begin
        LibraryEET.CreateEETBusinessPremises(EETBusinessPremises, LibraryEET.GetDefaultBusinessPremisesIdentification);
    end;

    local procedure CreateEETCashRegister(var EETCashRegister: Record "EET Cash Register"; EETBusinessPremisesCode: Code[10])
    begin
        LibraryEET.CreateEETCashRegister(
          EETCashRegister, EETBusinessPremisesCode, EETCashRegister."Register Type"::"Cash Desk", '');
    end;

    local procedure CreateFakeEntries(BusinessPremisesCode: Code[10]; CashRegisterCode: Code[10])
    var
        EETEntry: Record "EET Entry";
    begin
        EETEntry.DeleteAll();
        EETEntry.Init();
        EETEntry."Business Premises Code" := BusinessPremisesCode;
        EETEntry."Cash Register Code" := CashRegisterCode;
        EETEntry."EET Status" := EETEntry."EET Status"::"Send Pending";
        EETEntry.Insert(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        EETServiceMgt: Codeunit "EET Service Mgt.";
    begin
        case LibraryVariableStorage.DequeueText of
            EETServiceMgt.GetWebServiceURLTxt:
                Assert.AreEqual(ProductionEnvironmentQst, Question, '');
            EETServiceMgt.GetWebServicePlayGroundURLTxt:
                Assert.AreEqual(NonproductionEnvironmentQst, Question, '');
        end;

        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger;
    end;
}

