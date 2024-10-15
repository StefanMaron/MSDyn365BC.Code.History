codeunit 28000 "Post Code Check"
{

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Country: Record "Country/Region";
        HadGLSetup: Boolean;
        Text001: Label '%1 must be Post Code & City in %2.';

    procedure ValidateCity(CurrFieldNumber: Integer; TableNo: Integer; TableKey: Text[1024]; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; var Name: Text[100]; var Name2: Text[90]; var Contact: Text[100]; var Address: Text[100]; var Address2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10])
    var
        PostCodeRec: Record "Post Code";
        RecCount: Integer;
    begin
        if (City = '') or (CurrFieldNumber = 0) or (GuiAllowed = false) then
            exit;
        GetAddressValidationSetup(CountryCode);
        case Country."Address Validation" of
            Country."Address Validation"::"Post Code & City":
                begin
                    PostCodeRec.Reset();
                    PostCodeRec.SetCurrentKey("Search City");
                    PostCodeRec.SetFilter("Search City", UpperCase(City));
                    PostCodeRec.FindFirst;
                    RecCount := PostCodeRec.Count();
                    case true of
                        RecCount = 1:
                            begin
                                PostCode := PostCodeRec.Code;
                                City := PostCodeRec.City;
                                County := PostCodeRec.County;
                                CountryCode := PostCodeRec."Country/Region Code";
                            end;
                        RecCount > 1:
                            begin
                                if PAGE.RunModal(
                                     PAGE::"Post Codes", PostCodeRec, PostCodeRec.Code) = ACTION::LookupOK
                                then begin
                                    PostCode := PostCodeRec.Code;
                                    City := PostCodeRec.City;
                                    County := PostCodeRec.County;
                                    CountryCode := PostCodeRec."Country/Region Code";
                                end else
                                    Error('');
                            end;
                    end;
                end;
            Country."Address Validation"::"Entire Address",
          Country."Address Validation"::"Address ID":
                RunExternalValidation(
                  TableNo, TableKey, AddressType, 2,
                  Name, Name2, Contact, Address, Address2, City, PostCode, County, CountryCode);
        end;
    end;

    procedure ValidatePostCode(CurrFieldNumber: Integer; TableNo: Integer; TableKey: Text[1024]; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; var Name: Text[100]; var Name2: Text[90]; var Contact: Text[100]; var Address: Text[100]; var Address2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10])
    var
        PostCodeRec: Record "Post Code";
        RecCount: Integer;
    begin
        if (PostCode = '') or (CurrFieldNumber = 0) or (GuiAllowed = false) then
            exit;
        GetAddressValidationSetup(CountryCode);
        case Country."Address Validation" of
            Country."Address Validation"::"Post Code & City":
                begin
                    PostCodeRec.Reset();
                    PostCodeRec.SetFilter(Code, PostCode);
                    PostCodeRec.FindFirst;
                    RecCount := PostCodeRec.Count();
                    case true of
                        RecCount = 1:
                            begin
                                PostCode := PostCodeRec.Code;
                                City := PostCodeRec.City;
                                County := PostCodeRec.County;
                                CountryCode := PostCodeRec."Country/Region Code";
                            end;
                        RecCount > 1:
                            begin
                                if PAGE.RunModal(
                                     PAGE::"Post Codes", PostCodeRec, PostCodeRec.City) = ACTION::LookupOK
                                then begin
                                    PostCode := PostCodeRec.Code;
                                    City := PostCodeRec.City;
                                    County := PostCodeRec.County;
                                    CountryCode := PostCodeRec."Country/Region Code";
                                end else
                                    Error('');
                            end;
                    end;
                end;
            Country."Address Validation"::"Entire Address",
          Country."Address Validation"::"Address ID":
                RunExternalValidation(
                  TableNo, TableKey, AddressType, 2,
                  Name, Name2, Contact, Address, Address2, City, PostCode, County, CountryCode);
        end;
    end;

    procedure LookUpCity(CurrFieldNumber: Integer; TableNo: Integer; TableKey: Text[1024]; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; var Name: Text[100]; var Name2: Text[90]; var Contact: Text[100]; var Address: Text[100]; var Address2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10]; ReturnValues: Boolean)
    var
        PostCodeRec: Record "Post Code";
    begin
        if not GuiAllowed then
            exit;
        GetAddressValidationSetup(CountryCode);
        case Country."Address Validation" of
            Country."Address Validation"::"Post Code & City":
                begin
                    PostCodeRec.Reset();
                    PostCodeRec.SetCurrentKey("Search City");
                    PostCodeRec."Search City" := UpperCase(City);
                    if (PAGE.RunModal(
                          PAGE::"Post Codes", PostCodeRec, PostCodeRec.City) = ACTION::LookupOK) and ReturnValues
                    then begin
                        PostCode := PostCodeRec.Code;
                        City := PostCodeRec.City;
                        County := PostCodeRec.County;
                        CountryCode := PostCodeRec."Country/Region Code";
                    end;
                end;
            Country."Address Validation"::"Entire Address",
          Country."Address Validation"::"Address ID":
                RunExternalValidation(
                  TableNo, TableKey, AddressType, 1,
                  Name, Name2, Contact, Address, Address2, City, PostCode, County, CountryCode);
        end;
    end;

    procedure LookUpPostCode(CurrFieldNumber: Integer; TableNo: Integer; TableKey: Text[1024]; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; var Name: Text[100]; var Name2: Text[90]; var Contact: Text[100]; var Address: Text[100]; var Address2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10]; ReturnValues: Boolean)
    var
        PostCodeRec: Record "Post Code";
    begin
        if not GuiAllowed then
            exit;
        GetAddressValidationSetup(CountryCode);
        case Country."Address Validation" of
            Country."Address Validation"::"Post Code & City":
                begin
                    PostCodeRec.Reset();
                    PostCodeRec.Code := PostCode;
                    if (PAGE.RunModal(
                          PAGE::"Post Codes", PostCodeRec, PostCodeRec.Code) = ACTION::LookupOK) and ReturnValues
                    then begin
                        PostCode := PostCodeRec.Code;
                        City := PostCodeRec.City;
                        County := PostCodeRec.County;
                        CountryCode := PostCodeRec."Country/Region Code";
                    end;
                end;
            Country."Address Validation"::"Entire Address",
          Country."Address Validation"::"Address ID":
                RunExternalValidation(
                  TableNo, TableKey, AddressType, 1,
                  Name, Name2, Contact, Address, Address2, City, PostCode, County, CountryCode);
        end;
    end;

    procedure ValidateAddress(CurrFieldNumber: Integer; TableNo: Integer; TableKey: Text[1024]; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; var Name: Text[100]; var Name2: Text[90]; var Contact: Text[100]; var Address: Text[100]; var Address2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10])
    begin
        if (PostCode = '') or (City = '') or (CurrFieldNumber = 0) or (GuiAllowed = false) then
            exit;
        GetAddressValidationSetup(CountryCode);
        case Country."Address Validation" of
            Country."Address Validation"::"Entire Address",
          Country."Address Validation"::"Address ID":
                RunExternalValidation(
                  TableNo, TableKey, AddressType, 3,
                  Name, Name2, Contact, Address, Address2, City, PostCode, County, CountryCode);
        end;
    end;

    local procedure RunExternalValidation(TableNo: Integer; TableKey: Text[1024]; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; ValidationType: Option " ","GUI Only","GUI Optional","No GUI"; var Name: Text[100]; var Name2: Text[90]; var Contact: Text[100]; var Address: Text[100]; var Address2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10])
    var
        AddressID: Record "Address ID";
        TempAddressBuffer: Record "Address Buffer" temporary;
    begin
        Country.TestField("AMAS Software");
        TempAddressBuffer.Init();
        TempAddressBuffer.Name := Name;
        TempAddressBuffer."Name 2" := Name2;
        TempAddressBuffer.Contact := Contact;
        TempAddressBuffer.Address := Address;
        TempAddressBuffer."Address 2" := Address2;
        TempAddressBuffer.City := City;
        TempAddressBuffer."Post Code" := PostCode;
        TempAddressBuffer.County := County;
        TempAddressBuffer."Country/Region Code" := CountryCode;
        TempAddressBuffer."Validation Type" := ValidationType;
        TempAddressBuffer.Insert();
        CODEUNIT.Run(Country."AMAS Software", TempAddressBuffer);
        if (TempAddressBuffer."Address ID" <> '') or
           (TempAddressBuffer."Bar Code" <> '') or
           (TempAddressBuffer."Error Flag No." <> '')
        then begin
            if not AddressID.Get(TableNo, TableKey, AddressType) then begin
                AddressID.Init();
                AddressID."Table No." := TableNo;
                AddressID."Table Key" := TableKey;
                AddressID."Address Type" := AddressType;
                AddressID.Validate("Address ID", TempAddressBuffer."Address ID");
                AddressID."Address Sort Plan" := TempAddressBuffer."Address Sort Plan";
                AddressID."Error Flag No." := TempAddressBuffer."Error Flag No.";
                AddressID."Bar Code System" := TempAddressBuffer."Bar Code System";
                AddressID.Insert();
            end else begin
                AddressID.Validate("Address ID", TempAddressBuffer."Address ID");
                AddressID."Address Sort Plan" := TempAddressBuffer."Address Sort Plan";
                AddressID."Error Flag No." := TempAddressBuffer."Error Flag No.";
                AddressID."Bar Code System" := TempAddressBuffer."Bar Code System";
                AddressID.Modify();
            end;
        end;
        if Country."Address Validation" =
           Country."Address Validation"::"Entire Address"
        then begin
            Name := CopyStr(TempAddressBuffer.Name, 1, 30);
            Name2 := CopyStr(TempAddressBuffer."Name 2", 1, 30);
            Contact := CopyStr(TempAddressBuffer.Contact, 1, 30);
            Address := CopyStr(TempAddressBuffer.Address, 1, 30);
            Address2 := CopyStr(TempAddressBuffer."Address 2", 1, 30);
            City := CopyStr(TempAddressBuffer.City, 1, 30);
            PostCode := CopyStr(TempAddressBuffer."Post Code", 1, 20);
            County := CopyStr(TempAddressBuffer.County, 1, 30);
            CountryCode := CopyStr(TempAddressBuffer."Country/Region Code", 1, 10);
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteAddressID(TableNo: Integer; TableKey: Text[1024]; AddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to")
    var
        AddressID: Record "Address ID";
    begin
        AddressID.SetRange("Table No.", TableNo);
        AddressID.SetRange("Table Key", TableKey);
        AddressID.SetRange("Address Type", AddressType);
        AddressID.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure DeleteAllAddressID(TableNo: Integer; TableKey: Text[1024])
    var
        AddressID: Record "Address ID";
    begin
        AddressID.SetRange("Table No.", TableNo);
        AddressID.SetRange("Table Key", TableKey);
        AddressID.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CopyAddressID(FromTableNo: Integer; FromTableKey: Text[1024]; FromAddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; ToTableNo: Integer; ToTableKey: Text[1024]; ToAddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to")
    var
        FromAddressID: Record "Address ID";
        ToAddressID: Record "Address ID";
    begin
        if FromAddressID.Get(FromTableNo, FromTableKey, FromAddressType) then begin
            if not ToAddressID.Get(ToTableNo, ToTableKey, ToAddressType) then begin
                ToAddressID.Init();
                ToAddressID := FromAddressID;
                ToAddressID."Table No." := ToTableNo;
                ToAddressID."Table Key" := ToTableKey;
                ToAddressID."Address Type" := ToAddressType;
                ToAddressID.Insert();
            end else begin
                ToAddressID."Address ID" := FromAddressID."Address ID";
                ToAddressID."Address Sort Plan" := FromAddressID."Address Sort Plan";
                ToAddressID."Bar Code" := FromAddressID."Bar Code";
                ToAddressID."Bar Code System" := FromAddressID."Bar Code System";
                ToAddressID."Error Flag No." := FromAddressID."Error Flag No.";
                ToAddressID."Address ID Check Date" := FromAddressID."Address ID Check Date";
                ToAddressID.Modify();
            end;
        end else
            if ToAddressID.Get(ToTableNo, ToTableKey, ToAddressType) then
                ToAddressID.Delete();
    end;

    [Scope('OnPrem')]
    procedure CopyAllAddressID(FromTableNo: Integer; FromTableKey: Text[1024]; ToTableNo: Integer; ToTableKey: Text[1024])
    var
        FromAddressID: Record "Address ID";
        ToAddressID: Record "Address ID";
    begin
        FromAddressID.SetRange("Table No.", FromTableNo);
        FromAddressID.SetRange("Table Key", FromTableKey);
        ToAddressID.SetRange("Table No.", ToTableNo);
        ToAddressID.SetRange("Table Key", ToTableKey);
        ToAddressID.DeleteAll();
        if FromAddressID.Find('-') then
            repeat
                ToAddressID.Init();
                ToAddressID := FromAddressID;
                ToAddressID."Table No." := ToTableNo;
                ToAddressID."Table Key" := ToTableKey;
                ToAddressID.Insert();
            until FromAddressID.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure MoveAddressID(FromTableNo: Integer; FromTableKey: Text[1024]; FromAddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to"; ToTableNo: Integer; ToTableKey: Text[1024]; ToAddressType: Option Main,"Bill-to","Ship-to","Sell-to","Pay-to","Buy-from","Transfer-from","Transfer-to")
    var
        FromAddressID: Record "Address ID";
        ToAddressID: Record "Address ID";
    begin
        if FromAddressID.Get(FromTableNo, FromTableKey, FromAddressType) then begin
            if not ToAddressID.Get(ToTableNo, ToTableKey, ToAddressType) then begin
                ToAddressID.Init();
                ToAddressID := FromAddressID;
                ToAddressID."Table No." := ToTableNo;
                ToAddressID."Table Key" := ToTableKey;
                ToAddressID."Address Type" := ToAddressType;
                ToAddressID.Insert();
            end else begin
                ToAddressID := FromAddressID;
                ToAddressID."Table No." := ToTableNo;
                ToAddressID."Table Key" := ToTableKey;
                ToAddressID."Address Type" := ToAddressType;
                ToAddressID.Modify();
            end;
            FromAddressID.Delete();
        end else
            if ToAddressID.Get(ToTableNo, ToTableKey, ToAddressType) then
                ToAddressID.Delete();
    end;

    [Scope('OnPrem')]
    procedure MoveAllAddressID(FromTableNo: Integer; FromTableKey: Text[1024]; ToTableNo: Integer; ToTableKey: Text[1024])
    var
        FromAddressID: Record "Address ID";
        ToAddressID: Record "Address ID";
    begin
        FromAddressID.SetRange("Table No.", FromTableNo);
        FromAddressID.SetRange("Table Key", FromTableKey);
        ToAddressID.SetRange("Table No.", ToTableNo);
        ToAddressID.SetRange("Table Key", ToTableKey);
        ToAddressID.DeleteAll();
        if FromAddressID.Find('-') then
            repeat
                ToAddressID.Init();
                ToAddressID := FromAddressID;
                ToAddressID."Table No." := ToTableNo;
                ToAddressID."Table Key" := ToTableKey;
                ToAddressID.Insert();
            until FromAddressID.Next = 0;

        FromAddressID.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure TextToArray(OutputText: Text[1024]; var ArrayOutputText: array[100] of Text[1024]) ReturnInformation: Text[1024]
    var
        i: Integer;
        j: Integer;
    begin
        i := 1;
        j := 1;
        while (OutputText[i] <> 0) and (j < 100) do begin
            if Format(OutputText[i]) <> ',' then
                ArrayOutputText[j] := ArrayOutputText[j] + Format(OutputText[i])
            else
                j := j + 1;
            i := i + 1;
        end;
    end;

    [Scope('OnPrem')]
    procedure ApplicationNotInstalled()
    var
        Text001: Label 'The external component is not installed.';
    begin
        Message(Text001);
    end;

    local procedure GetAddressValidationSetup(CountryCode: Code[10])
    begin
        if CountryCode = '' then begin
            GetGLSetup;
            Clear(Country);
            Country."Address Validation" := GLSetup."Address Validation";
            Country."AMAS Software" := GLSetup."AMAS Software";
        end else
            Country.Get(CountryCode);
    end;

    local procedure GetGLSetup()
    begin
        if not HadGLSetup then begin
            GLSetup.Get();
            HadGLSetup := true;
        end;
    end;

    [Scope('OnPrem')]
    procedure AddressValIsPostCodeCity()
    begin
        GetGLSetup;
        if GLSetup."Address Validation" <> GLSetup."Address Validation"::"Post Code & City" then
            Error(
              Text001,
              GLSetup.FieldCaption("Address Validation"),
              GLSetup.TableCaption);
    end;
}

