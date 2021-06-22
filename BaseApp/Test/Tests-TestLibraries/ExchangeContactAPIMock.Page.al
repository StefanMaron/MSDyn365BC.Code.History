page 130650 "Exchange Contact API Mock"
{
    Caption = 'contacts', Locked = true;
    DelayedInsert = true;
    EntityName = 'exchangeContact';
    EntitySetName = 'exchangeContacts';
    PageType = API;
    SourceTable = ExchangeContactMock;
    ODataKeyFields = SystemId;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Id; Rec.SystemId)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Id', Locked = true;
                }
                field(CreatedDateTime; CreatedDateTime)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'CreatedDateTime', Locked = true;
                }
                field(LastModifiedDateTime; LastModifiedDateTime)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LastModifiedDateTime', Locked = true;
                }
                field(Categories; CategoriesText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Categories', Locked = true;
                    ODataEDMType = 'Collection(Edm.String)';

                    trigger OnValidate()
                    begin
                        SetCategoriesString(CategoriesText);
                    end;
                }
                field(ParentFolderId; ParentFolderId)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ParentFolderId', Locked = true;
                }
                field(Birthday; Birthday)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Birthday', Locked = true;
                }
                field(FileAs; FileAs)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'FileAs', Locked = true;
                }
                field(DisplayName; DisplayName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'DisplayName', Locked = true;

                    trigger OnValidate()
                    begin
                        // Simplified logic here to simulate some processing that Exchange does
                        GivenName := DisplayName;
                    end;
                }
                field(GivenName; GivenName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'GivenName', Locked = true;

                    trigger OnValidate()
                    begin
                        // Simplified logic here to simulate some processing that Exchange does
                        DisplayName := GivenName;
                    end;
                }
                field(Initials; Initials)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Initials', Locked = true;
                }
                field(MiddleName; MiddleName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'MiddleName', Locked = true;
                }
                field(NickName; NickName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'NickName', Locked = true;
                }
                field(Surname; Surname)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Surname', Locked = true;
                }
                field(Title; Title)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Title', Locked = true;
                }
                field(YomiGivenName; YomiGivenNameText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'YomiGivenName', Locked = true;

                    trigger OnValidate()
                    begin
                        SetYomiGivenName(YomiGivenNameText);
                    end;
                }
                field(YomiSurname; YomiSurnameText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'YomiSurname', Locked = true;

                    trigger OnValidate()
                    begin
                        SetYomiSurname(YomiSurnameText);
                    end;
                }
                field(YomiCompanyName; YomiCompanyNameText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'YomiCompanyName', Locked = true;

                    trigger OnValidate()
                    begin
                        SetYomiCompanyName(YomiCompanyNameText);
                    end;
                }
                field(Generation; GenerationText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Generation', Locked = true;

                    trigger OnValidate()
                    begin
                        SetGeneration(GenerationText);
                    end;
                }
                field(EmailAddresses; EmailAddressesText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'EmailAddresses', Locked = true;
                    ODataEDMType = 'Collection(OUTLOOKEMAILADDRESS)';

                    trigger OnValidate()
                    begin
                        SetEmailAddressesString(EmailAddressesText);
                    end;
                }
                field(Websites; WebsitesText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Websites', Locked = true;
                    ODataEDMType = 'Collection(OUTLOOKWEBSITE)';

                    trigger OnValidate()
                    begin
                        SetWebsitesString(WebsitesText);
                    end;
                }
                field(ImAddresses; ImAddressesText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ImAddresses', Locked = true;
                    ODataEDMType = 'Collection(Edm.String)';

                    trigger OnValidate()
                    begin
                        SetImAddressesString(ImAddressesText);
                    end;
                }
                field(JobTitle; JobTitleText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'JobTitle', Locked = true;

                    trigger OnValidate()
                    begin
                        SetJobTitle(JobTitleText);
                    end;
                }
                field(CompanyName; CompanyName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'CompanyName', Locked = true;
                }
                field(Department; DepartmentText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Department', Locked = true;

                    trigger OnValidate()
                    begin
                        SetDepartment(DepartmentText);
                    end;
                }
                field(OfficeLocation; OfficeLocationText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OfficeLocation', Locked = true;

                    trigger OnValidate()
                    begin
                        SetOfficeLocation(OfficeLocationText);
                    end;
                }
                field(Profession; ProfessionText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profession', Locked = true;

                    trigger OnValidate()
                    begin
                        SetProfession(ProfessionText);
                    end;
                }
                field(AssistantName; AssistantNameText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'AssistantName', Locked = true;

                    trigger OnValidate()
                    begin
                        SetAssistantName(AssistantNameText);
                    end;
                }
                field(Manager; ManagerText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Manager', Locked = true;

                    trigger OnValidate()
                    begin
                        SetManager(ManagerText);
                    end;
                }
                field(Phones; PhonesText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Phones', Locked = true;
                    ODataEDMType = 'Collection(OUTLOOKPHONE)';

                    trigger OnValidate()
                    begin
                        SetPhonesString(PhonesText);
                    end;
                }
                field(PostalAddresses; PostalAddressesText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'PostalAddresses', Locked = true;
                    ODataEDMType = 'Collection(OUTLOOKPHYSICALADDRESS)';

                    trigger OnValidate()
                    begin
                        SetPostalAddressesString(PostalAddressesText);
                    end;
                }
                field(SpouseName; SpouseNameText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SpouseName', Locked = true;

                    trigger OnValidate()
                    begin
                        SetSpouseName(SpouseNameText);
                    end;
                }
                field(PersonalNotes; PersonalNotesText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'PersonalNotes', Locked = true;

                    trigger OnValidate()
                    begin
                        SetPersonalNotesString(PersonalNotesText);
                    end;
                }
                field(Children; ChildrenText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Children', Locked = true;
                    ODataEDMType = 'Collection(Edm.String)';

                    trigger OnValidate()
                    begin
                        SetChildrenString(ChildrenText);
                    end;
                }
                field(WeddingAnniversary; WeddingAnniversary)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'WeddingAnniversary', Locked = true;
                }
                field(Gender; Gender)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gender', Locked = true;
                }
                field(IsFavorite; IsFavorite)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'IsFavorite', Locked = true;
                }
                field(Flag; FlagText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Flag', Locked = true;
                    ODataEDMType = 'Collection(Edm.String)';

                    trigger OnValidate()
                    begin
                        SetFlagString(FlagText);
                    end;
                }
                field(DeltaToken; DeltaToken)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'DeltaToken', Locked = true;
                }
                field(SingleValueExtendedProperties; SingleValueExtendedPropertiesText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SingleValueExtendedProperties', Locked = true;
                    ODataEDMType = 'Collection(SINGLEVALUEEXTPROP)';

                    trigger OnValidate()
                    begin
                        SetSingleValueExtPropString(SingleValueExtendedPropertiesText);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        LoadCollections;
    end;

    trigger OnClosePage()
    begin
        if IsGet then
            LibraryGraphMock.IncrementGetCount;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        IsGet := false;
        LibraryGraphMock.IncrementDeleteCount;

        LibraryGraphMock.SendContactDeleteWebhook(Rec);
    end;

    trigger OnInit()
    begin
        IsGet := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        IsGet := false;
        LibraryGraphMock.IncrementInsertCount;

        if Id = '' then begin
            Id := LibraryUtility.GenerateGUID;
            while not Insert(true) do
                Id := LibraryUtility.GenerateGUID;
        end else
            Insert(true);

        Commit();

        LibraryGraphMock.SendContactInsertWebhook(Rec);
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        IsGet := false;
        LibraryGraphMock.IncrementModifyCount;

        // Prevent a modify (and preseve the etag/changekey) if we don't really have any changes
        if not IsRecordChanged then
            exit(false);

        Modify(true);
        Commit();

        LibraryGraphMock.SendContactUpdateWebhook(Rec);
        exit(false);
    end;

    var
        LibraryGraphMock: Codeunit "Library - Graph Mock";
        CategoriesText: Text;
        YomiGivenNameText: Text;
        YomiSurnameText: Text;
        YomiCompanyNameText: Text;
        GenerationText: Text;
        EmailAddressesText: Text;
        WebsitesText: Text;
        ImAddressesText: Text;
        JobTitleText: Text;
        DepartmentText: Text;
        OfficeLocationText: Text;
        ProfessionText: Text;
        AssistantNameText: Text;
        ManagerText: Text;
        PhonesText: Text;
        PostalAddressesText: Text;
        SpouseNameText: Text;
        PersonalNotesText: Text;
        ChildrenText: Text;
        FlagText: Text;
        SingleValueExtendedPropertiesText: Text;
        IsGet: Boolean;

    local procedure LoadCollections()
    begin
        CategoriesText := GetCategoriesString;
        YomiGivenNameText := GetYomiGivenName;
        YomiSurnameText := GetYomiSurname;
        YomiCompanyNameText := GetYomiCompanyName;
        GenerationText := GetGeneration;
        EmailAddressesText := GetEmailAddressesString;
        WebsitesText := GetWebsitesString;
        ImAddressesText := GetImAddressesString;
        JobTitleText := GetJobTitle;
        DepartmentText := GetDepartment;
        OfficeLocationText := GetOfficeLocation;
        ProfessionText := GetProfession;
        AssistantNameText := GetAssistantName;
        ManagerText := GetManager;
        PhonesText := GetPhonesString;
        PostalAddressesText := GetPostalAddressesString;
        SpouseNameText := GetSpouseName;
        PersonalNotesText := GetPersonalNotesString;
        ChildrenText := GetChildrenString;
        FlagText := GetFlagString;
        SingleValueExtendedPropertiesText := GetSingleValueExtPropString;
    end;

    local procedure IsRecordChanged(): Boolean
    var
        RecRef: RecordRef;
        xRecRef: RecordRef;
        RecFieldRef: FieldRef;
        xRecFieldRef: FieldRef;
        i: Integer;
    begin
        RecRef.GetTable(Rec);
        xRecRef.GetTable(xRec);

        for i := 1 to RecRef.FieldCount do begin
            RecFieldRef := RecRef.FieldIndex(i);
            xRecFieldRef := xRecRef.FieldIndex(i);
            if RecFieldRef.Value <> xRecFieldRef.Value then
                exit(true);
        end;
        exit(false);
    end;
}

