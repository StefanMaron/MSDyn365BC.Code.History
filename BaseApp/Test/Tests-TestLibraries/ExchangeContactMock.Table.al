table 130650 ExchangeContactMock
{

    fields
    {
        field(1; Id; Text[250])
        {
            Caption = 'Id', Locked = true;
        }
        field(2; CreatedDateTime; DateTime)
        {
            Caption = 'CreatedDateTime', Locked = true;
        }
        field(3; LastModifiedDateTime; DateTime)
        {
            Caption = 'LastModifiedDateTime', Locked = true;
        }
        field(4; ChangeKey; Text[250])
        {
            Caption = 'ChangeKey', Locked = true;
        }
        field(5; Categories; BLOB)
        {
            Caption = 'Categories', Locked = true;
            SubType = Json;
        }
        field(6; ParentFolderId; Text[250])
        {
            Caption = 'ParentFolderId', Locked = true;
        }
        field(7; Birthday; DateTime)
        {
            Caption = 'Birthday', Locked = true;
        }
        field(8; FileAs; Text[250])
        {
            Caption = 'FileAs', Locked = true;
        }
        field(9; DisplayName; Text[250])
        {
            Caption = 'DisplayName', Locked = true;
        }
        field(10; GivenName; Text[250])
        {
            Caption = 'GivenName', Locked = true;
            Description = 'GivenName is mandatory. InitValue must be a space (=[ ] in the .txt format)';
        }
        field(11; Initials; Text[250])
        {
            Caption = 'Initials', Locked = true;
        }
        field(12; MiddleName; Text[250])
        {
            Caption = 'MiddleName', Locked = true;
        }
        field(13; NickName; Text[250])
        {
            Caption = 'NickName', Locked = true;
        }
        field(14; Surname; Text[250])
        {
            Caption = 'Surname', Locked = true;
        }
        field(15; Title; Text[250])
        {
            Caption = 'Title', Locked = true;
        }
        field(16; YomiGivenName; BLOB)
        {
            Caption = 'YomiGivenName', Locked = true;
            SubType = Json;
        }
        field(17; YomiSurname; BLOB)
        {
            Caption = 'YomiSurname', Locked = true;
            SubType = Json;
        }
        field(18; YomiCompanyName; BLOB)
        {
            Caption = 'YomiCompanyName', Locked = true;
            SubType = Json;
        }
        field(19; Generation; BLOB)
        {
            Caption = 'Generation', Locked = true;
            SubType = Json;
        }
        field(20; EmailAddresses; BLOB)
        {
            Caption = 'EmailAddresses', Locked = true;
            SubType = Json;
        }
        field(21; Websites; BLOB)
        {
            Caption = 'Websites', Locked = true;
            SubType = Json;
        }
        field(22; ImAddresses; BLOB)
        {
            Caption = 'ImAddresses', Locked = true;
            SubType = Json;
        }
        field(23; JobTitle; BLOB)
        {
            Caption = 'JobTitle', Locked = true;
            SubType = Json;
        }
        field(24; CompanyName; Text[250])
        {
            Caption = 'CompanyName', Locked = true;
        }
        field(25; Department; BLOB)
        {
            Caption = 'Department', Locked = true;
            SubType = Json;
        }
        field(26; OfficeLocation; BLOB)
        {
            Caption = 'OfficeLocation', Locked = true;
            SubType = Json;
        }
        field(27; Profession; BLOB)
        {
            Caption = 'Profession', Locked = true;
            SubType = Json;
        }
        field(28; AssistantName; BLOB)
        {
            Caption = 'AssistantName', Locked = true;
            SubType = Json;
        }
        field(29; Manager; BLOB)
        {
            Caption = 'Manager', Locked = true;
            SubType = Json;
        }
        field(30; Phones; BLOB)
        {
            Caption = 'Phones', Locked = true;
            SubType = Json;
        }
        field(31; PostalAddresses; BLOB)
        {
            Caption = 'PostalAddresses', Locked = true;
            SubType = Json;
        }
        field(32; SpouseName; BLOB)
        {
            Caption = 'SpouseName', Locked = true;
            SubType = Json;
        }
        field(33; PersonalNotes; BLOB)
        {
            Caption = 'PersonalNotes', Locked = true;
            SubType = Json;
        }
        field(34; Children; BLOB)
        {
            Caption = 'Children', Locked = true;
            SubType = Json;
        }
        field(35; WeddingAnniversary; DateTime)
        {
            Caption = 'WeddingAnniversary', Locked = true;
        }
        field(36; Gender; Text[250])
        {
            Caption = 'Gender', Locked = true;
        }
        field(37; IsFavorite; Boolean)
        {
            Caption = 'IsFavorite', Locked = true;
        }
        field(38; Flag; BLOB)
        {
            Caption = 'Flag', Locked = true;
            SubType = Json;
        }
        field(40; DeltaToken; Text[250])
        {
            Caption = 'DeltaToken', Locked = true;
        }
        field(51; SingleValueExtendedProperties; BLOB)
        {
            SubType = Json;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CreatedDateTime := CurrentDateTime;
        LastModifiedDateTime := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        LastModifiedDateTime := CurrentDateTime;
    end;

    [Scope('OnPrem')]
    procedure GetCategoriesString(): Text
    begin
        exit(GetBlobString(FieldNo(Categories)));
    end;

    [Scope('OnPrem')]
    procedure SetCategoriesString(CategoriesString: Text)
    begin
        SetBlobString(FieldNo(Categories), CategoriesString);
    end;

    [Scope('OnPrem')]
    procedure GetEmailAddressesString(): Text
    begin
        exit(GetBlobString(FieldNo(EmailAddresses)));
    end;

    [Scope('OnPrem')]
    procedure SetEmailAddressesString(EmailAddressesString: Text)
    begin
        SetBlobString(FieldNo(EmailAddresses), EmailAddressesString);
    end;

    [Scope('OnPrem')]
    procedure GetWebsitesString(): Text
    begin
        exit(GetBlobString(FieldNo(Websites)));
    end;

    [Scope('OnPrem')]
    procedure SetWebsitesString(WebsitesString: Text)
    begin
        SetBlobString(FieldNo(Websites), WebsitesString);
    end;

    [Scope('OnPrem')]
    procedure GetImAddressesString(): Text
    begin
        exit(GetBlobString(FieldNo(ImAddresses)));
    end;

    [Scope('OnPrem')]
    procedure SetImAddressesString(ImAddressesString: Text)
    begin
        SetBlobString(FieldNo(ImAddresses), ImAddressesString);
    end;

    [Scope('OnPrem')]
    procedure GetPhonesString(): Text
    begin
        exit(GetBlobString(FieldNo(Phones)));
    end;

    [Scope('OnPrem')]
    procedure SetPhonesString(PhonesString: Text)
    begin
        SetBlobString(FieldNo(Phones), PhonesString);
    end;

    [Scope('OnPrem')]
    procedure GetPostalAddressesString(): Text
    begin
        exit(GetBlobString(FieldNo(PostalAddresses)));
    end;

    [Scope('OnPrem')]
    procedure SetPostalAddressesString(PostalAddressesString: Text)
    begin
        SetBlobString(FieldNo(PostalAddresses), PostalAddressesString);
    end;

    [Scope('OnPrem')]
    procedure GetPersonalNotesString(): Text
    begin
        exit(GetBlobString(FieldNo(PersonalNotes)));
    end;

    [Scope('OnPrem')]
    procedure SetPersonalNotesString(PersonalNotesString: Text)
    begin
        SetBlobString(FieldNo(PersonalNotes), PersonalNotesString);
    end;

    [Scope('OnPrem')]
    procedure GetChildrenString(): Text
    begin
        exit(GetBlobString(FieldNo(Children)));
    end;

    [Scope('OnPrem')]
    procedure SetChildrenString(ChildrenString: Text)
    begin
        SetBlobString(FieldNo(Children), ChildrenString);
    end;

    [Scope('OnPrem')]
    procedure GetFlagString(): Text
    begin
        exit(GetBlobString(FieldNo(Flag)));
    end;

    [Scope('OnPrem')]
    procedure SetFlagString(FlagString: Text)
    begin
        SetBlobString(FieldNo(Flag), FlagString);
    end;

    [Scope('OnPrem')]
    procedure GetSingleValueExtPropString(): Text
    begin
        exit(GetBlobString(FieldNo(SingleValueExtendedProperties)));
    end;

    [Scope('OnPrem')]
    procedure SetSingleValueExtPropString(SingleValueExtPropText: Text)
    begin
        SetBlobString(FieldNo(SingleValueExtendedProperties), SingleValueExtPropText);
    end;

    [Scope('OnPrem')]
    procedure GetSpouseName(): Text
    begin
        exit(GetBlobString(FieldNo(SpouseName)));
    end;

    [Scope('OnPrem')]
    procedure SetSpouseName(SpouseNameText: Text)
    begin
        SetBlobString(FieldNo(SpouseName), SpouseNameText);
    end;

    [Scope('OnPrem')]
    procedure GetManager(): Text
    begin
        exit(GetBlobString(FieldNo(Manager)));
    end;

    [Scope('OnPrem')]
    procedure SetManager(ManagerText: Text)
    begin
        SetBlobString(FieldNo(Manager), ManagerText);
    end;

    [Scope('OnPrem')]
    procedure GetAssistantName(): Text
    begin
        exit(GetBlobString(FieldNo(AssistantName)));
    end;

    [Scope('OnPrem')]
    procedure SetAssistantName(AssistantNameText: Text)
    begin
        SetBlobString(FieldNo(AssistantName), AssistantNameText);
    end;

    [Scope('OnPrem')]
    procedure GetProfession(): Text
    begin
        exit(GetBlobString(FieldNo(Profession)));
    end;

    [Scope('OnPrem')]
    procedure SetProfession(ProfessionText: Text)
    begin
        SetBlobString(FieldNo(Profession), ProfessionText);
    end;

    [Scope('OnPrem')]
    procedure GetOfficeLocation(): Text
    begin
        exit(GetBlobString(FieldNo(OfficeLocation)));
    end;

    [Scope('OnPrem')]
    procedure SetOfficeLocation(OfficeLocationText: Text)
    begin
        SetBlobString(FieldNo(OfficeLocation), OfficeLocationText);
    end;

    [Scope('OnPrem')]
    procedure GetDepartment(): Text
    begin
        exit(GetBlobString(FieldNo(Department)));
    end;

    [Scope('OnPrem')]
    procedure SetDepartment(DepartmentText: Text)
    begin
        SetBlobString(FieldNo(Department), DepartmentText);
    end;

    [Scope('OnPrem')]
    procedure GetJobTitle(): Text
    begin
        exit(GetBlobString(FieldNo(JobTitle)));
    end;

    [Scope('OnPrem')]
    procedure SetJobTitle(JobTitleText: Text)
    begin
        SetBlobString(FieldNo(JobTitle), JobTitleText);
    end;

    [Scope('OnPrem')]
    procedure GetGeneration(): Text
    begin
        exit(GetBlobString(FieldNo(Generation)));
    end;

    [Scope('OnPrem')]
    procedure SetGeneration(GenerationText: Text)
    begin
        SetBlobString(FieldNo(Generation), GenerationText);
    end;

    [Scope('OnPrem')]
    procedure GetYomiCompanyName(): Text
    begin
        exit(GetBlobString(FieldNo(YomiCompanyName)));
    end;

    [Scope('OnPrem')]
    procedure SetYomiCompanyName(YomiCompanyNameText: Text)
    begin
        SetBlobString(FieldNo(YomiCompanyName), YomiCompanyNameText);
    end;

    [Scope('OnPrem')]
    procedure GetYomiSurname(): Text
    begin
        exit(GetBlobString(FieldNo(YomiSurname)));
    end;

    [Scope('OnPrem')]
    procedure SetYomiSurname(YomiSurnameText: Text)
    begin
        SetBlobString(FieldNo(YomiSurname), YomiSurnameText);
    end;

    [Scope('OnPrem')]
    procedure GetYomiGivenName(): Text
    begin
        exit(GetBlobString(FieldNo(YomiGivenName)));
    end;

    [Scope('OnPrem')]
    procedure SetYomiGivenName(YomiGivenNameText: Text)
    begin
        SetBlobString(FieldNo(YomiGivenName), YomiGivenNameText);
    end;

    local procedure GetBlobString(FieldNo: Integer) Content: Text
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        TempBlob.FromRecord(Rec, FieldNo);
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        InStream.Read(Content);
    end;

    local procedure SetBlobString(FieldNo: Integer; NewContent: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        OutStream: OutStream;
    begin
        RecordRef.GetTable(Rec);
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.Write(NewContent);
        TempBlob.ToRecordRef(RecordRef, FieldNo);
        RecordRef.SetTable(Rec);
    end;

    [Scope('OnPrem')]
    procedure SetBusinessType(Type: Text)
    begin
        AddOrReplaceExtendedProperty('String {bdba944b-fc2b-47a1-8ba4-cafc4ae13ea2} Name BusinessType', Type);
    end;

    [Scope('OnPrem')]
    procedure SetIsContact(IsContact: Boolean)
    var
        Value: Text;
    begin
        Value := '0';
        if IsContact then
            Value := '1';

        AddOrReplaceExtendedProperty('Integer {f4be2302-782e-483d-8ba4-26fb6535f665} Name IsContact', Value);
    end;

    [Scope('OnPrem')]
    procedure SetIsNavCreated(IsNavCreated: Boolean)
    var
        Value: Text;
    begin
        Value := '0';
        if IsNavCreated then
            Value := '1';

        AddOrReplaceExtendedProperty('Integer {6023a623-3b6c-492d-9ef5-811850c088ac} Name IsNavCreated', Value);
    end;

    [Scope('OnPrem')]
    procedure SetNavIntegrationId(IntegrationId: Guid)
    begin
        AddOrReplaceExtendedProperty('String {d048f561-4dd0-443c-a8d8-f397fb74f1df} Name NavIntegrationId', IntegrationId);
    end;

    local procedure AddOrReplaceExtendedProperty(PropertyId: Text; Value: Text)
    var
        ObjectJSONManagement: Codeunit "JSON Management";
        ArrayJSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
    begin
        ArrayJSONManagement.InitializeCollection(GetSingleValueExtPropString);
        ObjectJSONManagement.InitializeEmptyObject;
        ObjectJSONManagement.GetJSONObject(JObject);
        ObjectJSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'PropertyId', PropertyId);
        ObjectJSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'Value', Value);

        ArrayJSONManagement.AddJObjectToCollection(JObject);
        SetSingleValueExtPropString(ArrayJSONManagement.WriteCollectionToString);
    end;
}

