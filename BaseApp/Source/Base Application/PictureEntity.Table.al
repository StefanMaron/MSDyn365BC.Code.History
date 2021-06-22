table 5468 "Picture Entity"
{
    Caption = 'Picture Entity';

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(11; Width; Integer)
        {
            Caption = 'Width';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(12; Height; Integer)
        {
            Caption = 'Height';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(13; "Mime Type"; Text[100])
        {
            Caption = 'Mime Type';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; Content; BLOB)
        {
            Caption = 'Content';
            DataClassification = SystemMetadata;
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

    var
        IdNotProvidedErr: Label 'You must specify a resource ID to get the picture.', Locked = true;
        RequestedRecordDoesNotExistErr: Label 'No resource with the specified ID exists.', Locked = true;
        RequestedRecordIsNotSupportedErr: Label 'Images are not supported for requested entity - %1.', Locked = true;

    [Scope('OnPrem')]
    procedure LoadData(IdFilter: Text)
    var
        IntegrationRecord: Record "Integration Record";
        MediaID: Guid;
    begin
        FindIntegrationRecordFromFilter(IntegrationRecord, IdFilter);
        Id := IntegrationRecord."Integration ID";

        MediaID := GetMediaID(IntegrationRecord);
        SetValuesFromMediaID(MediaID);
    end;

    [Scope('OnPrem')]
    procedure SavePicture()
    var
        IntegrationRecord: Record "Integration Record";
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        ImageInStream: InStream;
        IsHandled: Boolean;
    begin
        FindIntegrationRecordFromFilter(IntegrationRecord, StrSubstNo('=%1', Id));
        Content.CreateInStream(ImageInStream);

        case IntegrationRecord."Table ID" of
            DATABASE::Item:
                begin
                    Item.Get(IntegrationRecord."Record ID");
                    Clear(Item.Picture);
                    Item.Picture.ImportStream(ImageInStream, GetDefaultMediaDescription(Item));
                    Item.Modify(true);
                end;
            DATABASE::Customer:
                begin
                    Customer.Get(IntegrationRecord."Record ID");
                    Clear(Customer.Image);
                    Customer.Image.ImportStream(ImageInStream, GetDefaultMediaDescription(Customer));
                    Customer.Modify(true);
                end;
            DATABASE::Vendor:
                begin
                    Vendor.Get(IntegrationRecord."Record ID");
                    Clear(Vendor.Image);
                    Vendor.Image.ImportStream(ImageInStream, GetDefaultMediaDescription(Vendor));
                    Vendor.Modify(true);
                end;
            DATABASE::Employee:
                begin
                    Employee.Get(IntegrationRecord."Record ID");
                    Clear(Employee.Image);
                    Employee.Image.ImportStream(
                      ImageInStream, GetDefaultMediaDescription(Employee));
                    Employee.Modify(true);
                end;
            else begin
                    OnSavePictureElseCase(IntegrationRecord, IsHandled);
                    if not IsHandled then
                        ThrowEntityNotSupportedError(IntegrationRecord);
                end;
        end;

        LoadData(StrSubstNo('=%1', Id));
    end;

    procedure DeletePicture()
    var
        IntegrationRecord: Record "Integration Record";
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        IsHandled: Boolean;
    begin
        FindIntegrationRecordFromFilter(IntegrationRecord, StrSubstNo('=%1', Id));

        case IntegrationRecord."Table ID" of
            DATABASE::Item:
                begin
                    Item.Get(IntegrationRecord."Record ID");
                    Clear(Item.Picture);
                    Item.Modify(true);
                end;
            DATABASE::Customer:
                begin
                    Customer.Get(IntegrationRecord."Record ID");
                    Clear(Customer.Image);
                    Customer.Modify(true);
                end;
            DATABASE::Vendor:
                begin
                    Vendor.Get(IntegrationRecord."Record ID");
                    Clear(Vendor.Image);
                    Vendor.Modify(true);
                end;
            DATABASE::Employee:
                begin
                    Employee.Get(IntegrationRecord."Record ID");
                    Clear(Employee.Image);
                    Employee.Modify(true);
                end;
            else begin
                    IsHandled := false;
                    OnDeletePictureElseCase(IntegrationRecord, IsHandled);
                    if not IsHandled then
                        ThrowEntityNotSupportedError(IntegrationRecord);
                end;
        end;

        Clear(Rec);
        Id := IntegrationRecord."Integration ID";
    end;

    local procedure GetMediaID(var IntegrationRecord: Record "Integration Record"): Guid
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Employee: Record Employee;
        MediaID: Guid;
        IsHandled: Boolean;
    begin
        case IntegrationRecord."Table ID" of
            DATABASE::Item:
                begin
                    Item.Get(IntegrationRecord."Record ID");
                    if Item.Picture.Count > 0 then
                        MediaID := Item.Picture.Item(1);
                end;
            DATABASE::Customer:
                begin
                    Customer.Get(IntegrationRecord."Record ID");
                    MediaID := Customer.Image.MediaId;
                end;
            DATABASE::Vendor:
                begin
                    Vendor.Get(IntegrationRecord."Record ID");
                    MediaID := Vendor.Image.MediaId;
                end;
            DATABASE::Employee:
                begin
                    Employee.Get(IntegrationRecord."Record ID");
                    MediaID := Employee.Image.MediaId;
                end;
            else begin
                    IsHandled := false;
                    OnGetMediaIDElseCase(IntegrationRecord, MediaID, IsHandled);
                    if not IsHandled then
                        ThrowEntityNotSupportedError(IntegrationRecord);
                end;
        end;

        exit(MediaID);
    end;

    local procedure SetValuesFromMediaID(MediaID: Guid)
    var
        TenantMedia: Record "Tenant Media";
    begin
        // TODO: This code should be replaced once we get a proper platform support
        // We should not build dependencies to TenantMedia table
        if IsNullGuid(MediaID) then
            exit;

        TenantMedia.SetAutoCalcFields(Content);
        if not TenantMedia.Get(MediaID) then
            exit;

        "Mime Type" := TenantMedia."Mime Type";
        Width := TenantMedia.Width;
        Height := TenantMedia.Height;

        Content := TenantMedia.Content;
    end;

    local procedure FindIntegrationRecordFromFilter(var IntegrationRecord: Record "Integration Record"; IDFilter: Text)
    begin
        if IDFilter = '' then
            Error(IdNotProvidedErr);

        IntegrationRecord.SetFilter("Integration ID", IDFilter);
        if not IntegrationRecord.FindFirst then
            Error(RequestedRecordDoesNotExistErr);
    end;

    local procedure ThrowEntityNotSupportedError(var IntegrationRecord: Record "Integration Record")
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", IntegrationRecord."Table ID");
        if AllObjWithCaption.FindFirst then;
        Error(StrSubstNo(RequestedRecordIsNotSupportedErr, AllObjWithCaption."Object Caption"));
    end;

    procedure GetDefaultMediaDescription(ParentRecord: Variant): Text
    var
        Item: Record Item;
        Customer: Record Customer;
        Employee: Record Employee;
        Vendor: Record Vendor;
        ParentRecordRef: RecordRef;
        MediaDescription: Text;
        IsHandled: Boolean;
    begin
        ParentRecordRef.GetTable(ParentRecord);

        case ParentRecordRef.Number of
            DATABASE::Item:
                begin
                    ParentRecordRef.SetTable(Item);
                    MediaDescription := StrSubstNo('%1 %2.%3', Item."No.", Item.Description, GetDefaultExtension);
                end;
            DATABASE::Customer:
                begin
                    ParentRecordRef.SetTable(Customer);
                    MediaDescription := StrSubstNo('%1 %2.%3', Customer."No.", Customer.Name, GetDefaultExtension);
                end;
            DATABASE::Vendor:
                begin
                    ParentRecordRef.SetTable(Vendor);
                    MediaDescription := StrSubstNo('%1 %2.%3', Vendor."No.", Vendor.Name, GetDefaultExtension);
                end;
            DATABASE::Employee:
                begin
                    ParentRecordRef.SetTable(Employee);
                    MediaDescription :=
                      StrSubstNo('%1 %2 %3.%4', Employee."No.", Employee."First Name", Employee."Last Name", GetDefaultExtension);
                end;
            else begin
                    IsHandled := false;
                    OnGetDefaultMediaDescriptionElseCase(ParentRecordRef, MediaDescription, IsHandled);
                    if not IsHandled then
                        exit('');
                end;
        end;

        exit(MediaDescription);
    end;

    procedure GetDefaultExtension(): Text
    begin
        exit('jpg');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeletePictureElseCase(IntegrationRecord: Record "Integration Record"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDefaultMediaDescriptionElseCase(ParentRecordRef: RecordRef; var MediaDescription: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetMediaIDElseCase(IntegrationRecord: Record "Integration Record"; var MediaID: Guid; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSavePictureElseCase(IntegrationRecord: Record "Integration Record"; var IsHandled: Boolean)
    begin
    end;
}

