table 2190 "O365 Sales Graph"
{
    Caption = 'O365 Sales Graph';
    ReplicateData = false;
    TableType = MicrosoftGraph;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; Component; Text[60])
        {
            Caption = 'Component';
            ExternalName = 'component';
            ExternalType = 'Edm.String';
        }
        field(2; Type; Text[60])
        {
            Caption = 'Type';
            ExternalName = 'type';
            ExternalType = 'Edm.String';
        }
        field(3; "Schema"; Text[60])
        {
            Caption = 'Schema';
            ExternalName = 'schema';
            ExternalType = 'Edm.String';
        }
        field(4; Details; BLOB)
        {
            Caption = 'Details';
            ExternalName = 'details';
            ExternalType = 'Edm.Json';
            SubType = Json;
        }
        field(5; InvoiceId; Text[60])
        {
            Caption = 'InvoiceId';
            ExternalName = 'invoiceId';
            ExternalType = 'Edm.String';
        }
        field(6; EmployeeId; Text[250])
        {
            Caption = 'EmployeeId';
            ExternalName = 'employeeId';
            ExternalType = 'Edm.String';
        }
        field(7; ContactId; Text[250])
        {
            Caption = 'ContactId';
            ExternalName = 'customerId';
            ExternalType = 'Edm.String';
        }
        field(8; ActivityDate; Text[60])
        {
            Caption = 'ActivityDate';
            ExternalName = 'activityDate';
            ExternalType = 'Edm.String';
        }
        field(9; Kind; Text[60])
        {
            Caption = 'Kind';
            ExternalName = 'kind';
            ExternalType = 'Edm.String';
        }
        field(10; EstimateId; Text[60])
        {
            Caption = 'EstimateId';
            ExternalName = 'EstimateId';
            ExternalType = 'Edm.String';
        }
    }

    keys
    {
        key(Key1; Component)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
#if not CLEAN21

    var
        InvalidComponentErr: Label 'Component should be Invoice.';
        InvalidSchemaErr: Label 'An unsupported schema was specified.';
        InvalidTypeErr: Label 'The specified type is not valid for the request.';
        NotInvoicingErr: Label 'The specified tenant is not an Invoicing tenant.';
        SupportedSchemaTxt: Label 'InvoiceV1', Locked = true;
        ComponentTxt: Label 'Invoice', Locked = true;
        RefreshTypeTxt: Label 'Refresh', Locked = true;

    procedure Initialize()
    begin
        Init();
        Component := ComponentTxt;
        Schema := SupportedSchemaTxt;
        ActivityDate := Format(CurrentDateTime, 0, 9);
    end;

    [Scope('OnPrem')]
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure SetEmployeeIdToCurrentUser()
    var
        AzureADGraphUser: Codeunit "Azure AD Graph User";
    begin
        EmployeeId := AzureADGraphUser.GetObjectId(UserSecurityId());
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure ParseRefresh()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        if UpperCase(Component) <> UpperCase(ComponentTxt) then
            Error(InvalidComponentErr);

        if UpperCase(Schema) <> UpperCase(SupportedSchemaTxt) then
            Error(InvalidSchemaErr);

        if UpperCase(Type) <> UpperCase(RefreshTypeTxt) then
            Error(InvalidTypeErr);

        if (not O365SalesInitialSetup.Get()) or (not O365SalesInitialSetup."Is initialized") then
            Error(NotInvoicingErr);

        TASKSCHEDULER.CreateTask(CODEUNIT::"O365 Sales Web Service", 0, true, CompanyName, CurrentDateTime + 10000); // Add 10s
    end;
#endif
}

