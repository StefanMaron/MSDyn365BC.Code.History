codeunit 18077 "Library GST"
{
    procedure CreateInitialSetup(): Code[10]
    var
        StateCode: Code[10];
    begin
        if IsTaxAccountingPeriodEmpty() then
            CreateGSTAccountingPeriod();
        StateCode := CreateGSTStateCode();
        exit(StateCode);
    end;

    local procedure CreateGSTAccountingPeriod()
    var
        TaxAccPeriodSetup: Record "Tax Acc. Period Setup";
        TaxAccPeriod: Record "Tax Accounting Period";
        TaxTypeSetup: Record "Tax Type Setup";
        WorkdateMonth: Integer;
        WorkDateYear: Integer;
        AccPeriodStartDate: Date;
        AccPeriodEndDate: Date;
        FinancialYear: Code[10];
        Cnt: Integer;
    begin
        TaxTypeSetup.Get();
        if not TaxAccPeriodSetup.Get(TaxTypeSetup.Code) then begin
            TaxAccPeriodSetup.Init();
            TaxAccPeriodSetup.Code := TaxTypeSetup.Code;
            TaxAccPeriodSetup.Description := 'GST Accounting Periods';
            TaxAccPeriodSetup.Insert(true);
        end;

        GetTaxAccountingDate(AccPeriodStartDate, AccPeriodEndDate, FinancialYear);

        TaxAccPeriod.Reset();
        TaxAccPeriod.SetRange("Tax Type Code", TaxTypeSetup.Code);
        TaxAccPeriod.SetRange("Starting Date", AccPeriodStartDate);
        if not TaxAccPeriod.FindFirst() then
            for Cnt := 1 to 12 do begin
                TaxAccPeriod.Init();
                TaxAccPeriod."Tax Type Code" := TaxTypeSetup.Code;
                TaxAccPeriod.Validate("Starting Date", AccPeriodStartDate);
                TaxAccPeriod.Validate("Ending Date", CalcDate('<CM>', TaxAccPeriod."Starting Date"));
                TaxAccPeriod.Validate("Credit Memo Locking Date", CALCDATE('<6M>', AccPeriodEndDate));
                TaxAccPeriod.Validate("Annual Return Filed Date", CALCDATE('<6M>', AccPeriodEndDate));
                TaxAccPeriod."Financial Year" := FinancialYear;
                if cnt = 1 then begin
                    TaxAccPeriod.Validate("New Fiscal Year", true);
                    TaxAccPeriod."Date Locked" := true;
                end;
                TaxAccPeriod.Quarter := GetTaxAccPeriodQuarter(Cnt);
                TaxAccPeriod.Insert();
                AccPeriodStartDate := CalcDate('<1M>', AccPeriodStartDate);
            end else begin
            TaxAccPeriod.Validate("Credit Memo Locking Date", CALCDATE('<6M>', AccPeriodEndDate));
            TaxAccPeriod.Validate("Annual Return Filed Date", CALCDATE('<6M>', AccPeriodEndDate));
            TaxAccPeriod.Modify();
            for Cnt := 1 to 12 do begin
                TaxAccPeriod.Init();
                TaxAccPeriod."Tax Type Code" := TaxTypeSetup.Code;
                TaxAccPeriod.Validate("Starting Date", CalcDate('<CM+1D>', AccPeriodStartDate));
                TaxAccPeriod.Validate("Ending Date", CalcDate('<CM>', TaxAccPeriod."Starting Date"));
                TaxAccPeriod.Validate("Credit Memo Locking Date", CALCDATE('<6M>', AccPeriodEndDate));
                TaxAccPeriod.Validate("Annual Return Filed Date", CALCDATE('<6M>', AccPeriodEndDate));
                TaxAccPeriod."Financial Year" := FinancialYear;
                if cnt = 1 then begin
                    TaxAccPeriod.validate("New Fiscal Year", true);
                    TaxAccPeriod."Date Locked" := true;
                end;
                TaxAccPeriod.Quarter := GetTaxAccPeriodQuarter(Cnt);
                TaxAccPeriod.Insert();
                AccPeriodStartDate := TaxAccPeriod."Starting Date";
            end;
        end;
    end;

    local procedure IsTaxAccountingPeriodEmpty(): Boolean
    var
        TaxTypeSetup: Record "Tax Type Setup";
        TaxType: Record "Tax Type";
        TaxAccountingPeriod: Record "Tax Accounting Period";
        AccPeriodEndDate: Date;
        AccPeriodStartDate: Date;
    begin
        if TaxTypeSetup.Get() then
            TaxTypeSetup.TestField(TaxTypeSetup.Code);

        TaxType.Get(TaxTypeSetup.Code);

        TaxAccountingPeriod.Reset();
        TaxAccountingPeriod.SetRange("Tax Type Code", TaxType."Accounting Period");
        TaxAccountingPeriod.SetFilter("Starting Date", '<=%1', WorkDate());
        TaxAccountingPeriod.SetFilter("Ending Date", '>=%1', WorkDate());
        if TaxAccountingPeriod.FindSet() then begin
            GetTaxAccountingDate(AccPeriodStartDate, AccPeriodEndDate, '');
            repeat
                TaxAccountingPeriod.Validate("Credit Memo Locking Date", CALCDATE('<6M>', AccPeriodEndDate));
                TaxAccountingPeriod.Validate("Annual Return Filed Date", CALCDATE('<6M>', AccPeriodEndDate));
                TaxAccountingPeriod.Modify(true);
            until TaxAccountingPeriod.Next() = 0;
        end else
            exit(true);
    end;

    local procedure GetTaxAccPeriodQuarter(Cnt: Integer): Code[2]
    var
        Quarter: Code[2];
    begin
        case cnt of
            1 .. 3:
                Quarter := 'Q1';
            4 .. 6:
                Quarter := 'Q2';
            7 .. 9:
                Quarter := 'Q3';
            10 .. 12:
                Quarter := 'Q4';
        end;
        exit(Quarter);
    end;

    procedure CreateGSTStateCode(): Code[10]
    var
        State: Record State;
        State1: Record State;
        StateGSTRegNo: Code[10];
        GSTRegNo: Integer;
    begin
        GSTRegNo := LibraryRandom.RandIntInRange(10, 90);
        StateGSTRegNo := Format(GSTRegNo);
        State1.Reset();
        State1.SETCURRENTKEY("State Code (GST Reg. No.)");
        State1.SetFilter("State Code (GST Reg. No.)", '%1', StateGSTRegNo);
        if Not State1.FindFirst() then begin
            CreateState(State);
            State.Validate(Description, State.Code);
            State.Validate("State Code (GST Reg. No.)", StateGSTRegNo);
            State.Modify(true);
            exit(State.Code);
        end else
            exit(State1.Code)
    end;

    procedure CreateCustomerGSTStateCode(LocationState: Code[10]): Code[10]
    var
        State: Record State;
        State1: Record State;
        StateGSTRegNo: Code[10];
    begin
        State1.Reset();
        State1.SETCURRENTKEY("State Code (GST Reg. No.)");
        State1.SetFilter(Code, '<>%1', LocationState);
        State1.SetFilter("State Code (GST Reg. No.)", '%1..%2', '10', '99');
        if State1.FindSet() then
            State1.DeleteAll(true);

        StateGSTRegNo := FORMAT(LibraryRandom.RandIntInRange(10, 80));

        State1.Reset();
        State1.SETCURRENTKEY("State Code (GST Reg. No.)");
        State1.SetFilter(Code, '<>%1', LocationState);
        State1.FindFirst();
        if State1."State Code (GST Reg. No.)" = StateGSTRegNo then
            StateGSTRegNo := StateGSTRegNo + format(1);

        State.Reset();
        CreateState(State);
        State.Validate(Description, State.Code);
        State.Validate("State Code (GST Reg. No.)", StateGSTRegNo);
        State.Modify(true);
        exit(State.Code);
    end;

    procedure CreateState(var State: Record State)
    begin
        State.Init();
        State.Validate(Code,
          COPYSTR(LibraryUtility.GenerateRandomCode(State.FIELDNO(Code), DATABASE::State),
            1, LibraryUtility.GetFieldLength(DATABASE::State, State.FIELDNO(Code))));
        State.Insert(true);
    end;

    procedure CreateGSTRegistrationNos(StateCode: Code[10]; Pan: Code[20]): Code[15]
    var
        GSTRegistrationNos: Record "GST Registration Nos.";
        State: Record State;
        GSTRegistrationNo: Code[20];
    begin
        State.Get(StateCode);
        GSTRegistrationNo := GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Pan);
        GSTRegistrationNos.Reset();
        GSTRegistrationNos.SetRange(code, GSTRegistrationNo);
        if GSTRegistrationNos.IsEmpty() then begin
            GSTRegistrationNos.Init();
            GSTRegistrationNos.Validate("State Code", StateCode);
            GSTRegistrationNos.Validate(Code, GSTRegistrationNo);
            GSTRegistrationNos.Insert();
            exit(GSTRegistrationNos.Code);
        end Else
            exit(GSTRegistrationNo);
    end;

    procedure CreateGSTRegistrationNoForISD(StateCode: Code[10]; Pan: Code[20]; InputServiceDistributor: Boolean): Code[20]
    var
        GSTRegistrationNos: Record "GST Registration Nos.";
        State: Record State;
    begin
        GSTRegistrationNos.Init();
        GSTRegistrationNos.Validate("State Code", StateCode);
        State.Get(StateCode);
        GSTRegistrationNos.Validate(Code, GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Pan));
        if InputServiceDistributor then
            GSTRegistrationNos.Validate("Input Service Distributor", true)
        else
            GSTRegistrationNos.Validate("Input Service Distributor", false);
        GSTRegistrationNos.Insert();
        exit(GSTRegistrationNos.Code);
    end;

    procedure GenerateGSTRegistrationNo(StatecodeGSTReg: Code[10]; Pan: Code[20]): Code[15]
    var
        GSTRegNo1: Code[20];
        GSTRegNo: Code[15];
    begin
        Evaluate(GSTRegNo1, (StatecodeGSTReg + Pan));
        GSTRegNo1 := GSTRegNo1 + FORMAT(LibraryRandom.RandIntInRange(0, 9));
        GSTRegNo1 := GSTRegNo1 + 'Z';
        GSTRegNo1 := GSTRegNo1 + COPYSTR(LibraryUtility.GenerateRandomAlphabeticText(1, 0), 1, 1);
        GSTRegNo := COPYSTR(GSTRegNo1, 1, 15);
        exit(GSTRegNo);
    end;

    procedure CreateLocationSetup(StateCode: Code[10]; GSTRegNo: Code[15]; GSTInputServiceDistribution: Boolean): Code[10]
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        Location.Validate(Code, LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location));
        Location.Validate("State Code", StateCode);
        Location.Validate("GST Registration No.", GSTRegNo);
        Location."GST Input Service Distributor" := GSTInputServiceDistribution;
        Location.Modify(true);
        exit(location.Code);
    end;

    procedure UpdateLocationWithISD(LocationCode: Code[10]; GSTInputServiceDistribution: Boolean)
    var
        GSTRegistrationNos: Record "GST Registration Nos.";
        Location: Record Location;
    begin

        Location.Get(LocationCode);

        GSTRegistrationNos.Get(Location."GST Registration No.");
        GSTRegistrationNos.Validate("Input Service Distributor", GSTInputServiceDistribution);
        GSTRegistrationNos.Modify();

        Location.Get(LocationCode);
        Location.Validate("GST Registration No.");
        Location.Validate("Input Service Distributor", GSTInputServiceDistribution);
        Location.Modify();
    end;

    procedure CreateVendorSetup(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
        VendorNo: Code[20];
    begin
        CreateZeroVATPostingSetup(VATPostingSetup);
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        CreateGeneralPostingSetup(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);

        VendorNo := LibraryPurchase.CreateVendorNo();
        Vendor.Get(VendorNo);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    procedure CreateCustomerSetup(): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        LibrarySales: Codeunit "Library - Sales";
        CustomerNo: Code[20];
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, 0);
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        CreateGeneralPostingSetup(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);

        CustomerNo := LibrarySales.CreateCustomerNo();

        Customer.Get(CustomerNo);
        Customer.Validate(Address, CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Customer.Address)));
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    procedure CreatePANNos(): Code[20]
    var
        PanNo: Code[20];
    begin
        PanNo := COPYSTR(LibraryUtility.GenerateRandomAlphabeticText(5, 0), 1, 5);
        PanNo := PanNo + FORMAT(LibraryRandom.RandIntInRange(1000, 9999));
        Evaluate(PanNo, (PanNo + COPYSTR(LibraryUtility.GenerateRandomAlphabeticText(1, 0), 1, 1)));
        EXIT(PanNo);
    end;

    procedure CreateGeneralPostingSetup(GenBusinessPostingGroup: Code[20]; GenProductPostingGroup: Code[20]);
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.SetRange("Gen. Bus. Posting Group", GenBusinessPostingGroup);
        GeneralPostingSetup.SetRange("Gen. Prod. Posting Group", GenProductPostingGroup);
        if not GeneralPostingSetup.FindFirst() then begin
            GeneralPostingSetup.Init();
            GeneralPostingSetup.validate("Gen. Bus. Posting Group", GenBusinessPostingGroup);
            GeneralPostingSetup.Validate("Gen. Prod. Posting Group", GenProductPostingGroup);
            GeneralPostingSetup.Insert(true);
            GeneralPostingSetup.Validate("Sales Account", CreateGLAccountNo(GenBusinessPostingGroup, GenProductPostingGroup));
            GeneralPostingSetup.Validate("Purch. Account", CreateGLAccountNo(GenBusinessPostingGroup, GenProductPostingGroup));
            GeneralPostingSetup.Validate("COGS Account", CreateGLAccountNo(GenBusinessPostingGroup, GenProductPostingGroup));
            GeneralPostingSetup.Validate("Inventory Adjmt. Account", CreateGLAccountNo(GenBusinessPostingGroup, GenProductPostingGroup));
            GeneralPostingSetup.Validate("Direct Cost Applied Account", CreateGLAccountNo(GenBusinessPostingGroup, GenProductPostingGroup));
            GeneralPostingSetup.Validate("Purch. Line Disc. Account", CreateGLAccountNo(GenBusinessPostingGroup, GenProductPostingGroup));
            GeneralPostingSetup.Validate("Purch. Credit Memo Account", CreateGLAccountNo(GenBusinessPostingGroup, GenProductPostingGroup));
            GeneralPostingSetup.Validate("Sales Credit Memo Account", CreateGLAccountNo(GenBusinessPostingGroup, GenProductPostingGroup));
            GeneralPostingSetup.Modify(true);
        end;
    end;

    procedure CreateGLAccountNo(GenBusinessPostingGroup: Code[20]; GenProductPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateZeroVATPostingSetup(VATPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.validate("Gen. Bus. Posting Group", GenBusinessPostingGroup);
        GLAccount.validate("Gen. Prod. Posting Group", GenProductPostingGroup);
        GLAccount.validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    procedure CreateGSTGroup(VAR GSTGroup: Record "GST Group"; GSTGroupType: Enum "GST Group Type"; GSTPlaceOfSupply: Enum "GST Place Of Supply"; ReverseCharge: Boolean): Code[20]
    begin
        GSTGroup.Init();
        GSTGroup.Validate(Code, LibraryUtility.GenerateRandomCode(GSTGroup.FIELDNO(Code), DATABASE::"GST Group"));
        GSTGroup.Validate("GST Group Type", GSTGroupType);
        GSTGroup.Validate("GST Place Of Supply", GSTPlaceOfSupply);
        GSTGroup.Validate(Description, GSTGroup.Code);
        if ReverseCharge then
            GSTGroup.Validate("Reverse Charge", ReverseCharge);
        GSTGroup.Insert(true);
        exit(GSTGroup.Code);
    end;

    procedure UpdateGSTGroupCodeWithReversCharge(GSTGroupCode: Code[10]; ReverseCharge: Boolean)
    var
        GSTGroup: Record "GST Group";
    begin
        if GSTGroup.get(GSTGroupCode) then begin
            GSTGroup.Validate("Reverse Charge", ReverseCharge);
            GSTGroup.Modify();
        end;
    end;

    procedure CreateHSNSACCode(var HSNSAC: Record "HSN/SAC"; GSTGroupCode: Code[20]; HSNSACType: Enum "GST Goods And Services Type"): Code[10]
    begin
        HsnSac.Init();
        HsnSac.Validate("GST Group Code", GSTGroupCode);
        HsnSac.Validate(Code, LibraryUtility.GenerateRandomCode(HsnSac.FIELDNO(Code), DATABASE::"HSN/SAC"));
        HsnSac.Validate(Description, HsnSac.Code);
        HsnSac.Validate(Type, HSNSACType);
        HsnSac.Insert(true);
        exit(HsnSac.Code);
    end;

    procedure CreateGSTComponent(var GSTComponent: Record "Tax Component"; GSTcomponentCode: Text[30])
    var
        TaxTypeSetup: Record "Tax Type Setup";
    begin
        TaxTypeSetup.Get();
        GSTComponent.Reset();
        GSTComponent.SetRange("Tax Type", TaxTypeSetup.Code);
        GSTComponent.SetRange(Name, GSTcomponentCode);
        if not GSTComponent.FindFirst() then begin
            GSTComponent.Init();
            GSTComponent."Tax Type" := TaxTypeSetup.Code;
            GSTComponent.Name := GSTcomponentCode;
            GSTComponent.Type := GSTComponent.Type::Decimal;
            GSTComponent."Rounding Precision" := 0.01;
            GSTComponent.Direction := GSTComponent.Direction::Nearest;
            GSTComponent.Insert(true);
        end;
    end;

    procedure CreateGSTPostingSetup(var GSTComponent: Record "Tax Component"; StateCode: Code[10])
    var
        GSTPostingSetup: Record "GST Posting Setup";
    begin
        if not GSTPostingSetup.Get(StateCode, GSTComponent.ID) then begin
            GSTPostingSetup.Init();
            GSTPostingSetup.Validate("State Code", StateCode);
            GSTPostingSetup.Validate("Component ID", GSTComponent.ID);
            GSTPostingSetup.Validate("Receivable Account", CreateGLAccountNo(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code));
            GSTPostingSetup.Validate("Payable Account", CreateGLAccountNo(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code));
            GSTPostingSetup.Validate("Receivable Account (Interim)", CreateGLAccountNo(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code));
            GSTPostingSetup.Validate("Payables Account (Interim)", CreateGLAccountNo(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code));
            GSTPostingSetup.Validate("Expense Account", CreateGLAccountNo(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code));
            GSTPostingSetup.Validate("Refund Account", CreateGLAccountNo(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code));
            GSTPostingSetup.Validate("Receivable Acc. Interim (Dist)", CreateGLAccountNo(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code));
            GSTPostingSetup.Validate("Receivable Acc. (Dist)", CreateGLAccountNo(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code));
            GSTPostingSetup.Validate("IGST Payable A/c (Import)", CreateGLAccountNo(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code));
            GSTPostingSetup.Insert(true);
        end;
    end;

    procedure UpdateLineDiscAccInGeneralPostingSetup(GenBusinessPostingGroup: Code[20]; GenProductPostingGroup: Code[20]);
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.SetRange("Gen. Bus. Posting Group", GenBusinessPostingGroup);
        GeneralPostingSetup.SetRange("Gen. Prod. Posting Group", GenProductPostingGroup);
        if GeneralPostingSetup.FindFirst() then begin
            GeneralPostingSetup.Validate("Purch. Line Disc. Account", CreateGLAccountNo(GenBusinessPostingGroup, GenProductPostingGroup));
            GeneralPostingSetup.Validate("Sales Line Disc. Account", CreateGLAccountNo(GenBusinessPostingGroup, GenProductPostingGroup));
            GeneralPostingSetup.Modify(true);
        end;
    end;

    procedure CreateItemWithGSTDetails(var VATPostingSetup: Record "VAT Posting Setup"; GSTGroupCode: Code[20]; HSNSACCode: Code[10]; Availment: Boolean; ChargeItemExempted: Boolean): Code[20]
    var
        Item: Record Item;
    begin
        CreateZeroVATPostingSetup(VATPostingSetup);
        LibraryInventory.CreateItem(Item);
        Item.Validate("GST Group Code", GSTGroupCode);
        Item.Validate("HSN/SAC Code", HSNSACCode);
        if Availment then
            Item.Validate("GST Credit", Item."GST Credit"::Availment)
        ELSE
            Item.Validate("GST Credit", Item."GST Credit"::"Non-Availment");
        Item.Validate(Exempted, ChargeItemExempted);
        Item.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    procedure CreateGLAccWithGSTDetails(var VATPostingSetup: Record "VAT Posting Setup"; GSTGroupCode: Code[20]; HSNSACCode: Code[10]; Availment: Boolean; GLExempted: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
        GLAccNo: Code[20];
    begin
        CreateZeroVATPostingSetup(VATPostingSetup);
        GLAccNo := CreateGLAccountNo(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        GLAccount.Get(GLAccNo);
        GLAccount.Validate("GST Group Code", GSTGroupCode);
        GLAccount.Validate("HSN/SAC Code", HSNSACCode);
        if Availment then
            GLAccount.Validate("GST Credit", GLAccount."GST Credit"::Availment)
        ELSE
            GLAccount.Validate("GST Credit", GLAccount."GST Credit"::"Non-Availment");
        GLAccount.Validate(Exempted, GLExempted);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccNo);
    end;

    procedure CreateFixedAssetWithGSTDetails(var VATPostingSetup: Record "VAT Posting Setup"; GSTGroupCode: Code[20]; HSNSACCode: Code[10]; Availment: Boolean; FAExempted: Boolean): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalSetup: Record "FA Journal Setup";
        FASetup: record "FA Setup";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
    begin
        CreateZeroVATPostingSetup(VATPostingSetup);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateDepreciationBook(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset, DepreciationBook.Code);
        CreateAndUpdateFAClassSubclass(FixedAsset);
        FASetup.Get();
        FASetup.Validate("Default Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, CopyStr(UserId, 1, 50));
        UpdateFAPostingGroupGLAccounts(FixedAsset."FA Posting Group");
        FixedAsset.Validate("GST Group Code", GSTGroupCode);
        FixedAsset.Validate("HSN/SAC Code", HSNSACCode);
        if Availment then
            FixedAsset.Validate("GST Credit", FixedAsset."GST Credit"::Availment)
        ELSE
            FixedAsset.Validate("GST Credit", FixedAsset."GST Credit"::"Non-Availment");
        FixedAsset.Validate(Exempted, FAExempted);
        FixedAsset.Modify(true);
        CreateAndPostFAGLJnlforAquisition(FixedAsset."No.", WorkDate());
        CreateAndPostFAGLJnlforDepreciation(FixedAsset."No.", WorkDate());
        exit(FixedAsset."No.");
    end;

    local procedure CreateDepreciationBook(Var DepreciationBook: Record "Depreciation Book")
    var
        FASetup: Record "FA Setup";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("G/L Integration - Write-Down", true);
        DepreciationBook.Validate("G/L Integration - Appreciation", true);
        DepreciationBook.Validate("G/L Integration - Custom 1", true);
        DepreciationBook.Validate("G/L Integration - Custom 2", true);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Validate("G/L Integration - Maintenance", true);
        DepreciationBook.Modify(true);
        FASetup.Get();
        FASetup.Validate("Default Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; var FixedAsset: Record "Fixed Asset"; DepreciationBookCode: Code[10])
    var
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Validate("No. of Depreciation Months", 12);
        FADepreciationBook.Validate("Acquisition Date", WorkDate());
        FADepreciationBook.Validate("G/L Acquisition Date", WorkDate());
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateAndUpdateFAClassSubclass(var FixedAsset: Record "Fixed Asset")
    var
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
    begin
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass, FAClass.Code, FixedAsset."FA Posting Group");
        FixedAsset.Validate("FA Class Code", FAClass.Code);
        FixedAsset.Validate("FA Subclass Code", FASubclass.Code);
        FixedAsset.Validate("FA Location Code", CreateFALocation());
        FixedAsset.Modify(true);
    end;

    local procedure CreateFALocation(): Code[10]
    var
        FALocation: Record "FA Location";
    begin
        FALocation.Validate(Code, LibraryUtility.GenerateRandomCode(FALocation.FieldNo(Code), Database::"FA Location"));
        FALocation.Validate(Name, FALocation.Code);
        FALocation.Insert(true);
        exit(FALocation.Code);
    end;

    local procedure CreateAndPostFAGLJnlforAquisition(FixedAssetNo: Code[20]; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        LibraryJournal: Codeunit "Library - Journals";
    begin
        //Create line for Aquisition Cost
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryJournal.CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
        GenJournalLine."Document Type"::Payment,
        GenJournalLine."Account Type"::"Fixed Asset", FixedAssetNo,
        GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountWithDirectPostingNoVAT(),
        LibraryRandom.RandDecInRange(10000, 20000, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::Sale);
        GenJournalLine.Validate("FA Posting Type", GenJournalLine."FA Posting Type"::"Acquisition Cost");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostFAGLJnlforDepreciation(FixedAssetNo: Code[20]; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        LibraryJournal: Codeunit "Library - Journals";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryJournal.CreateGenJournalLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
        GenJournalLine."Document Type"::Payment,
        GenJournalLine."Account Type"::"Fixed Asset", FixedAssetNo,
        GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountWithDirectPostingNoVAT(),
        -LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::Sale);
        GenJournalLine.Validate("FA Posting Type", GenJournalLine."FA Posting Type"::Depreciation);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGLAccountWithDirectPostingNoVAT(): Code[20]
    var
        GLAccount: Record "G/L Account";

    begin
        GLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        GLAccount.Validate("Gen. Prod. Posting Group", GetGenProdPostingGroup());
        GLAccount.Validate("VAT Prod. Posting Group", GetNOVATProdPostingGroup());
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure GetGenProdPostingGroup(): Code[20]
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProdPostingGroup.FindFirst();
        exit(GenProdPostingGroup.Code);
    end;

    local procedure GetNOVATProdPostingGroup(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT %", 0);
        if VATPostingSetup.FindFirst() then
            exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    procedure UpdateFAPostingGroupGLAccounts(FAPostingGroupCode: Code[20])
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        if FAPostingGroup.Get(FAPostingGroupCode) then begin
            FAPostingGroup.Validate("Acquisition Cost Account", CreateGLAccountNo(GenBusinessPostingGroup.code, GenProductPostingGroup.Code));
            FAPostingGroup.Validate("Acq. Cost Acc. on Disposal", FAPostingGroup."Acquisition Cost Account");
            FAPostingGroup.Validate("Accum. Depreciation Account", LibraryERM.CreateGLAccountNo());
            FAPostingGroup.Validate("Accum. Depr. Acc. on Disposal", FAPostingGroup."Accum. Depreciation Account");
            FAPostingGroup.Validate("Depreciation Expense Acc.", LibraryERM.CreateGLAccountNo());
            FAPostingGroup.Validate("Gains Acc. on Disposal", LibraryERM.CreateGLAccountNo());
            FAPostingGroup.Validate("Losses Acc. on Disposal", LibraryERM.CreateGLAccountNo());
            FAPostingGroup.Validate("Sales Bal. Acc.", CreateGLAccountNo(GenBusinessPostingGroup.code, GenProductPostingGroup.Code));
            FAPostingGroup.Modify(true);
        end;
    end;

    procedure CreateZeroVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, 0);
    end;

    procedure VerifyGLEntries(GLDocType: Enum "Purchase Document Type"; PostedDocumentNo: Code[20]; GLCount: Integer)
    begin
        VerifyGLEntryforGST(GLDocType, PostedDocumentNo, GLCount);
    end;

    local procedure VerifyGLEntryforGST(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        DummyGLEntry: Record "G/L Entry";
        LibraryAssert: Codeunit "Library Assert";
    begin
        DummyGLEntry.SETRANGE("Document Type", DocumentType);
        DummyGLEntry.SETRANGE("Document No.", DocumentNo);
        if DummyGLEntry.FindFirst() Then
            LibraryAssert.RecordCount(DummyGLEntry, ExpectedCount);
    end;

    procedure CreateCurrencyCode(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 100, LibraryRandom.RandDecInDecimalRange(70, 80, 2));
        exit(Currency.Code);
    end;

    procedure GSTLedgerEntryCount(DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        GSTLedgerEntry: Record "GST Ledger Entry";
        Assert: Codeunit Assert;
    begin
        GSTLedgerEntry.SETRANGE("Document No.", DocumentNo);
        if GSTLedgerEntry.FindFirst() then;
        Assert.RecordCount(GSTLedgerEntry, ExpectedCount);
    end;

    procedure VerifyGLEntry(JnlBatchName: Code[10]): code[20]
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SETRANGE("Journal Batch Name", JnlBatchName);
        GLEntry.FindFirst();
        exit(GLEntry."Document No.");
    end;

    procedure VerifyTaxTransactionForPurchase(PONo: Code[20]; DocType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
        TaxTransactionValue: Record "Tax Transaction Value";
        Assert: Codeunit Assert;
    begin
        PurchaseLine.SetRange("Document Type", DocType);
        PurchaseLine.SetRange("Document No.", PONo);
        PurchaseLine.FindFirst();
        TaxTransactionValue.Reset();
        TaxTransactionValue.SetRange("Tax Record ID", PurchaseLine.RecordId);
        TaxTransactionValue.SetFilter(Percent, '<>%1', 0);
        TaxTransactionValue.SetFilter(Amount, '<>%1', 0);
        TaxTransactionValue.FindFirst();
        Assert.RecordIsNotEmpty(TaxTransactionValue);
    end;

    procedure VerifyTaxTransactionForSales(SONo: Code[20])
    var
        SalesLine: Record "Sales Line";
        TaxTransactionValue: Record "Tax Transaction Value";
        Assert: Codeunit Assert;
    begin
        SalesLine.SetRange("Document No.", SONo);
        SalesLine.FindFirst();
        TaxTransactionValue.Reset();
        TaxTransactionValue.SetRange("Tax Record ID", SalesLine.RecordId);
        TaxTransactionValue.SetFilter(Percent, '<>%1', 0);
        TaxTransactionValue.SetFilter(Amount, '<>%1', 0);
        TaxTransactionValue.FindFirst();
        Assert.RecordIsNotEmpty(TaxTransactionValue);
    end;

    local procedure GetTaxAccountingDate(var AccPeriodStartDate: Date; var AccPeriodEndDate: Date; FinancialYear: Code[10])
    var
        WorkdateMonth: Integer;
        WorkDateYear: Integer;
    begin
        WorkdateMonth := Date2DMY(WorkDate(), 2);
        WorkDateYear := Date2DMY(WorkDate(), 3);
        case WorkdateMonth of
            1 .. 3:
                begin
                    AccPeriodStartDate := DMY2Date(1, 4, (WorkDateYear - 1));
                    AccPeriodEndDate := DMY2Date(31, 3, WorkDateYear);
                    FinancialYear := Format((WorkDateYear - 1)) + '-' + Format(WorkDateYear);
                end;
            4 .. 12:
                begin
                    AccPeriodStartDate := DMY2Date(1, 4, WorkDateYear);
                    AccPeriodEndDate := DMY2Date(31, 3, (WorkDateYear + 1));
                    FinancialYear := Format(WorkDateYear) + '-' + Format(WorkDateYear + 1);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Dimension", 'OnGetLocalTablesWithDimSetIDValidationIgnored', '', false, false)]
    local procedure IgoneDimensionCount(var CountOfTablesIgnored: Integer)
    var
        TempAllObj: Record AllObj temporary;
        "Field": Record "Field";
    begin
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(Enabled, true);
        Field.SetRange(RelationTableNo, DATABASE::"Dimension Set Entry");
        Field.SetFilter(TableNo, '%1..%2', 18000, 18999); //Excluding IN tables
        if Field.FindSet() then begin
            TempAllObj."Object Type" := TempAllObj."Object Type"::Table;
            repeat
                TempAllObj."Object ID" := Field.TableNo;
                if TempAllObj.Insert() then;
            until Field.Next() = 0;
            CountOfTablesIgnored += TempAllObj.Count();
        end;
    end;

    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
}