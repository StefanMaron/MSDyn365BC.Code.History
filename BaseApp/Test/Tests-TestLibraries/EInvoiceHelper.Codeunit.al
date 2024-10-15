codeunit 143003 "E-Invoice Helper"
{

    trigger OnRun()
    begin
    end;

    var
        TempPredefinedCustomer: Record Customer temporary;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        TestValueTxt: Label 'Test Value';
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";

    [Scope('OnPrem')]
    procedure ClearCustomer()
    begin
        TempPredefinedCustomer.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        with Customer do begin
            GLN := TestValueTxt;
            "Account Code" := TestValueTxt;

            if not TempPredefinedCustomer.IsEmpty() then begin
                Address := TempPredefinedCustomer.Address;
                "Address 2" := TempPredefinedCustomer."Address 2";
                Validate("Country/Region Code", TempPredefinedCustomer."Country/Region Code");
                City := TempPredefinedCustomer.City;
                "Post Code" := TempPredefinedCustomer."Post Code";
                Name := TempPredefinedCustomer.Name;
                "Phone No." := TempPredefinedCustomer."Phone No.";
                "Fax No." := TempPredefinedCustomer."Fax No.";
                "E-Mail" := TempPredefinedCustomer."E-Mail";
                TempPredefinedCustomer."No." := "No.";
                "Currency Code" := TempPredefinedCustomer."Currency Code";
                "VAT Registration No." := TempPredefinedCustomer."VAT Registration No.";
                Validate("E-Invoice", TempPredefinedCustomer."E-Invoice");
            end else begin
                Address := TestValueTxt;
                "Address 2" := TestValueTxt;
                Validate("Country/Region Code", 'NO');
                City := TestValueTxt;
                "Post Code" := TestValueTxt;
                "VAT Registration No." := '123456785';
                Validate("E-Invoice", true);
            end;

            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateExchangeRate(StartingDate: Date): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Init();
        Currency.Validate(Code, CopyStr(LibraryUtility.GenerateGUID, 8, 3)); // Currency code must be exactly 3 characters long.
        Currency.Insert(true);
        LibraryERM.CreateExchangeRate(Currency.Code, StartingDate, LibraryRandom.RandInt(1000), LibraryRandom.RandInt(1000));
        exit(Currency.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateItem(VATProdPostGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        with Item do begin
            LibraryInventory.CreateItem(Item);

            Description := TestValueTxt;
            Validate("VAT Prod. Posting Group", VATProdPostGroupCode);
            Validate("Unit Price", LibraryRandom.RandInt(100));
            Modify(true);
        end;

        with UnitOfMeasure do begin
            Get(Item."Sales Unit of Measure");
            "International Standard Code" := DefaultUNECERec20Code;
            Modify(true);
        end;

        ItemUnitOfMeasure.Get(Item."No.", UnitOfMeasure.Code);
        ItemUnitOfMeasure."Qty. per Unit of Measure" := LibraryRandom.RandInt(10);
        ItemUnitOfMeasure.Modify();

        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure DefaultUNECERec20Code(): Text[3]
    begin
        exit('NMP');
    end;

    [Scope('OnPrem')]
    procedure GetTempPath(): Text[250]
    begin
        exit(TemporaryPath);
    end;

    [Scope('OnPrem')]
    procedure InitExpectedCustomerInfo(var TempExpectedCustomerInfo: Record Customer temporary)
    begin
        with TempExpectedCustomerInfo do begin
            Init;
            Address := 'Kanalvej 1';
            "Address 2" := 'Kanalvej 42';
            City := 'Kongens Lyngby';
            "Post Code" := 'DK-2800';
            "Country/Region Code" := 'DK';
            Name := 'New Domicile';
            "Phone No." := '45870000';
            "Fax No." := '45870001';
            "E-Mail" := 'mdcc@mdcc.dk';
            "VAT Registration No." := '987654321';
            "E-Invoice" := true;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetCustomer(TempNewCustomer: Record Customer temporary)
    begin
        TempPredefinedCustomer.Init();
        TempPredefinedCustomer.TransferFields(TempNewCustomer);
        TempPredefinedCustomer.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure SetupEInvoiceForSales(Path: Text[250])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        with SalesReceivablesSetup do begin
            Get;
            Validate("E-Invoice Sales Invoice Path", Path);
            Validate("E-Invoice Sales Cr. Memo Path", Path);
            Validate("E-Invoice Reminder Path", Path);
            Validate("E-Invoice Fin. Charge Path", Path);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure KIDSetup(NewKIDSetup: Option; DocNoLength: Integer; CustNoLength: Integer)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        with SalesReceivablesSetup do begin
            Get;
            Validate("KID Setup", NewKIDSetup);
            "Document No. length" := DocNoLength;
            "Customer No. length" := CustNoLength;
            Modify(true);
        end;
    end;
}

