codeunit 2190 "O365 Sales Web Service"
{
    Permissions = TableData "O365 Sales Graph" = rimd;

    trigger OnRun()
    begin
        SendKPI;
    end;

    var
        ActivityRolesTxt: Label 'BusinessSignals-Internal.Read,BusinessSignals-Internal.ReadWrite', Locked = true;
        S2SConnectionStrTemplateTxt: Label '{ENTITYLISTENDPOINT}=https://%1;{EXORESOURCEURI}=https://outlook.office365.com;{EXORESOURCEROLE}=%2', Locked = true;
        UserConnectionStrTemplateTxt: Label '{ENTITYLISTENDPOINT}=https://%1', Locked = true;
        ActivityKindTxt: Label 'Activity', Locked = true;
        KpiKindTxt: Label 'Kpi', Locked = true;
        InvoiceDescTxt: Label 'Invoice %1', Comment = '%1 = The Invoice number';
        EstimateDescTxt: Label 'Estimate %1', Comment = '%1 = the estimate number';
        MissingEndpointErr: Label 'No Graph endpoint has been specified.';
        UpdateKpiTypeTxt: Label 'InvoiceOverviewKPI', Locked = true;
        InvoiceCreatedTypeTxt: Label 'InvoiceSent', Locked = true;
        InvoicePaidTypeTxt: Label 'InvoicePaid', Locked = true;
        InvoiceDraftTypeTxt: Label 'NewInvoice', Locked = true;
        InvoiceOverdueTypeTxt: Label 'InvoiceOverdue', Locked = true;
        InvoiceInactivityTypeTxt: Label 'InvoiceInactivity', Locked = true;
        InvoiceEmailFailedTypeTxt: Label 'InvoiceEmailFailed', Locked = true;
        EstimateSentTypeTxt: Label 'EstimateSent', Locked = true;
        EstimateAcceptedTypeTxt: Label 'EstimateAccepted', Locked = true;
        EstimateExpiryTypeTxt: Label 'EstimateExpiry', Locked = true;
        EstimateEmailFailedTypeTxt: Label 'EstimateEmailFailed', Locked = true;
        C2GraphStatusTxt: Label 'Update C2Graph';
        InvoicePaidTxt: Label 'Invoice Paid';
        InvoiceCreatedTxt: Label 'Invoice Created';
        InvoiceDraftTxt: Label 'Invoice Draft';
        InvoiceOverdueTxt: Label 'Invoice Overdue';
        InvoiceInactivityTxt: Label 'Invoice Inactivity';
        InvoiceEmailFailedTxt: Label 'Invoice Email Failed', Locked = true;
        EstimateSentTxt: Label 'Estimate Sent';
        EstimateAcceptedTxt: Label 'Estimate Accepted';
        EstimateExpiryTxt: Label 'Estimate Expiry';
        EstimateEmailFailedTxt: Label 'Estimate Email Failed', Locked = true;
        C2GraphUpdateActionTxt: Label 'Update KPIs';

    [Scope('OnPrem')]
    procedure SendInvoiceInactivityEvent()
    var
        ActivityLog: Record "Activity Log";
        O365SalesGraph: Record "O365 Sales Graph";
        O365SalesEvent: Record "O365 Sales Event";
        OutStr: OutStream;
        ConnectionId: Text;
    begin
        if not O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Invoicing Inactivity") then
            exit;

        ConnectionId := Format(CreateGuid);
        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId) then
            RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId,
              GetConnectionString);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId, true);

        InitializeO365SalesGraph(O365SalesGraph, InvoiceInactivityTypeTxt);
        O365SalesGraph.Details.CreateOutStream(OutStr, TEXTENCODING::UTF8);
        GetInactivityDetails(OutStr);

        ActivityLog.LogActivity(O365SalesGraph, ActivityLog.Status::Success, InvoiceInactivityTxt, '', '');
        if O365SalesGraph.Insert(true) then;

        UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId);
    end;

    [Scope('OnPrem')]
    procedure SendInvoiceOverdueEvent(InvoiceNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ActivityLog: Record "Activity Log";
        O365SalesGraph: Record "O365 Sales Graph";
        O365SalesEvent: Record "O365 Sales Event";
        OutStr: OutStream;
        ContactGraphId: Text[250];
        ConnectionId: Text;
    begin
        if not O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Invoice Overdue") then
            exit;

        if not SalesInvoiceHeader.Get(InvoiceNo) then
            exit;

        if IsNullGuid(SalesInvoiceHeader.Id) then
            exit;

        if SalesInvoiceHeader."Due Date" > Today then
            exit;

        ContactGraphId := GetGraphIdForContactFromInvoice(SalesInvoiceHeader);

        ConnectionId := Format(CreateGuid);
        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId) then
            RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId,
              GetConnectionString);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId, true);

        InitializeO365SalesGraphForDocuments(O365SalesGraph, InvoiceOverdueTypeTxt, Format(SalesInvoiceHeader.Id), ContactGraphId);
        O365SalesGraph.Details.CreateOutStream(OutStr, TEXTENCODING::UTF8);
        if not GetOverdueDetails(InvoiceNo, OutStr) then
            exit;

        ActivityLog.LogActivity(O365SalesGraph, ActivityLog.Status::Success, InvoiceOverdueTxt, InvoiceNo, '');
        if O365SalesGraph.Insert(true) then;

        UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId);
    end;

    [Scope('OnPrem')]
    procedure SendInvoiceDraftEvent()
    var
        ActivityLog: Record "Activity Log";
        O365SalesGraph: Record "O365 Sales Graph";
        O365SalesEvent: Record "O365 Sales Event";
        OutStr: OutStream;
        ConnectionId: Text;
    begin
        if not O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Draft Reminder") then
            exit;

        ConnectionId := Format(CreateGuid);
        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId) then
            RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId,
              GetConnectionString);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId, true);

        InitializeO365SalesGraph(O365SalesGraph, InvoiceDraftTypeTxt);
        O365SalesGraph.Details.CreateOutStream(OutStr, TEXTENCODING::UTF8);
        if not GetDraftDetails(OutStr) then
            exit;

        ActivityLog.LogActivity(O365SalesGraph, ActivityLog.Status::Success, InvoiceDraftTxt, '', '');
        if O365SalesGraph.Insert(true) then;

        UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId);
    end;

    [Scope('OnPrem')]
    procedure SendInvoiceCreatedEvent(InvoiceNo: Code[20])
    var
        ActivityLog: Record "Activity Log";
        O365SalesGraph: Record "O365 Sales Graph";
        O365SalesEvent: Record "O365 Sales Event";
        OutStr: OutStream;
        ContactGraphId: Text[250];
        ConnectionId: Text;
        SalesInvoiceHeaderId: Text[60];
    begin
        if not O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Invoice Sent") then
            exit;

        if not GetIdsIfValidInvoice(InvoiceNo, ContactGraphId, ConnectionId, SalesInvoiceHeaderId) then
            exit;

        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId) then
            RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId,
              GetConnectionString);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId, true);

        InitializeO365SalesGraphForDocuments(O365SalesGraph, InvoiceCreatedTypeTxt, SalesInvoiceHeaderId, ContactGraphId);
        O365SalesGraph.Details.CreateOutStream(OutStr, TEXTENCODING::UTF8);
        GetInvoiceDetails(InvoiceNo, OutStr, 'Created');

        ActivityLog.LogActivity(O365SalesGraph, ActivityLog.Status::Success, InvoiceCreatedTxt, InvoiceNo, '');
        if O365SalesGraph.Insert(true) then;

        UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId);
    end;

    [Scope('OnPrem')]
    procedure SendInvoicePaidEvent(InvoiceNo: Code[20])
    var
        ActivityLog: Record "Activity Log";
        O365SalesGraph: Record "O365 Sales Graph";
        O365SalesEvent: Record "O365 Sales Event";
        OutStr: OutStream;
        ContactGraphId: Text[250];
        ConnectionId: Text;
        SalesInvoiceHeaderId: Text[60];
    begin
        if not O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Invoice Paid") then
            exit;

        if not GetIdsIfValidInvoice(InvoiceNo, ContactGraphId, ConnectionId, SalesInvoiceHeaderId) then
            exit;

        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId) then
            RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId,
              GetConnectionString);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId, true);

        InitializeO365SalesGraphForDocuments(O365SalesGraph, InvoicePaidTypeTxt, SalesInvoiceHeaderId, ContactGraphId);
        O365SalesGraph.Details.CreateOutStream(OutStr, TEXTENCODING::UTF8);
        if not GetPaidInvoiceDetails(InvoiceNo, OutStr) then
            exit;

        ActivityLog.LogActivity(O365SalesGraph, ActivityLog.Status::Success, InvoicePaidTxt, InvoiceNo, '');
        if O365SalesGraph.Insert(true) then;

        UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId);
    end;

    [Scope('OnPrem')]
    procedure SendInvoiceEmailFailedEvent(InvoiceNo: Code[20])
    var
        ActivityLog: Record "Activity Log";
        O365SalesGraph: Record "O365 Sales Graph";
        O365SalesEvent: Record "O365 Sales Event";
        OutStr: OutStream;
        ContactGraphId: Text[250];
        ConnectionId: Text;
        SalesInvoiceHeaderId: Text[60];
    begin
        if not O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Invoice Email Failed") then
            exit;

        if not GetIdsIfValidInvoice(InvoiceNo, ContactGraphId, ConnectionId, SalesInvoiceHeaderId) then
            exit;

        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId) then
            RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId,
              GetConnectionString);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId, true);

        InitializeO365SalesGraphForDocuments(O365SalesGraph, InvoiceEmailFailedTypeTxt, SalesInvoiceHeaderId, ContactGraphId);
        O365SalesGraph.Details.CreateOutStream(OutStr, TEXTENCODING::UTF8);
        GetInvoiceDetails(InvoiceNo, OutStr, 'EmailFailed');

        ActivityLog.LogActivity(O365SalesGraph, ActivityLog.Status::Success, InvoiceEmailFailedTxt, InvoiceNo, '');
        if O365SalesGraph.Insert(true) then;

        UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId);
    end;

    [Scope('OnPrem')]
    procedure SendEstimateSentEvent(EstimateNo: Code[20])
    var
        ActivityLog: Record "Activity Log";
        O365SalesGraph: Record "O365 Sales Graph";
        O365SalesEvent: Record "O365 Sales Event";
        OutStr: OutStream;
        ContactGraphId: Text[250];
        ConnectionId: Text;
        SalesHeaderId: Text[60];
    begin
        if not O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Estimate Sent") then
            exit;

        if not GetIdsIfValidEstimate(EstimateNo, ContactGraphId, ConnectionId, SalesHeaderId) then
            exit;

        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId) then
            RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId,
              GetConnectionString);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId, true);

        InitializeO365SalesGraphForDocuments(O365SalesGraph, EstimateSentTypeTxt, SalesHeaderId, ContactGraphId);
        O365SalesGraph.Details.CreateOutStream(OutStr, TEXTENCODING::UTF8);
        GetEstimateDetails(EstimateNo, OutStr, 'Sent');

        ActivityLog.LogActivity(O365SalesGraph, ActivityLog.Status::Success, EstimateSentTxt, EstimateNo, '');
        if O365SalesGraph.Insert(true) then;

        UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId);
    end;

    [Scope('OnPrem')]
    procedure SendEstimateAcceptedEvent(EstimateNo: Code[20])
    var
        ActivityLog: Record "Activity Log";
        O365SalesGraph: Record "O365 Sales Graph";
        O365SalesEvent: Record "O365 Sales Event";
        OutStr: OutStream;
        ContactGraphId: Text[250];
        ConnectionId: Text;
        SalesHeaderId: Text[60];
    begin
        if not O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Estimate Accepted") then
            exit;

        if not GetIdsIfValidEstimate(EstimateNo, ContactGraphId, ConnectionId, SalesHeaderId) then
            exit;

        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId) then
            RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId,
              GetConnectionString);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId, true);

        InitializeO365SalesGraphForDocuments(O365SalesGraph, EstimateAcceptedTypeTxt, SalesHeaderId, ContactGraphId);
        O365SalesGraph.Details.CreateOutStream(OutStr, TEXTENCODING::UTF8);
        if not GetAcceptedEstimateDetails(EstimateNo, OutStr) then
            exit;

        ActivityLog.LogActivity(O365SalesGraph, ActivityLog.Status::Success, EstimateAcceptedTxt, EstimateNo, '');
        if O365SalesGraph.Insert(true) then;

        UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId);
    end;

    [Scope('OnPrem')]
    procedure SendEstimateExpiryEvent()
    var
        ActivityLog: Record "Activity Log";
        O365SalesGraph: Record "O365 Sales Graph";
        O365SalesEvent: Record "O365 Sales Event";
        OutStr: OutStream;
        ConnectionId: Text;
    begin
        if not O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Estimate Expiring") then
            exit;

        ConnectionId := Format(CreateGuid);
        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId) then
            RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId,
              GetConnectionString);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId, true);

        InitializeO365SalesGraph(O365SalesGraph, EstimateExpiryTypeTxt);
        O365SalesGraph.Details.CreateOutStream(OutStr, TEXTENCODING::UTF8);
        if not GetExpiringEstimateDetails(OutStr) then
            exit;

        ActivityLog.LogActivity(O365SalesGraph, ActivityLog.Status::Success, EstimateExpiryTxt, '', '');
        if O365SalesGraph.Insert(true) then;

        UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId);
    end;

    [Scope('OnPrem')]
    procedure SendEstimateEmailFailedEvent(EstimateNo: Code[20])
    var
        ActivityLog: Record "Activity Log";
        O365SalesGraph: Record "O365 Sales Graph";
        O365SalesEvent: Record "O365 Sales Event";
        OutStr: OutStream;
        ContactGraphId: Text[250];
        ConnectionId: Text;
        SalesHeaderId: Text[60];
    begin
        if not O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Estimate Email Failed") then
            exit;

        if not GetIdsIfValidEstimate(EstimateNo, ContactGraphId, ConnectionId, SalesHeaderId) then
            exit;

        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId) then
            RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId,
              GetConnectionString);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId, true);

        InitializeO365SalesGraphForDocuments(O365SalesGraph, EstimateEmailFailedTypeTxt, SalesHeaderId, ContactGraphId);
        O365SalesGraph.Details.CreateOutStream(OutStr, TEXTENCODING::UTF8);
        GetEstimateDetails(EstimateNo, OutStr, 'EmailFailed');

        ActivityLog.LogActivity(O365SalesGraph, ActivityLog.Status::Success, EstimateEmailFailedTxt, EstimateNo, '');
        if O365SalesGraph.Insert(true) then;

        UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId);
    end;

    [Scope('OnPrem')]
    procedure SendKPI()
    var
        O365SalesGraph: Record "O365 Sales Graph";
        ActivityLog: Record "Activity Log";
        O365SalesEvent: Record "O365 Sales Event";
        OutStr: OutStream;
        ConnectionId: Text;
    begin
        if not O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"KPI Update") then
            exit;

        ConnectionId := Format(CreateGuid);
        if not HasTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId) then
            RegisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId,
              GetConnectionString);

        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId, true);

        InitializeO365SalesGraphForKPIs(O365SalesGraph, UpdateKpiTypeTxt);
        O365SalesGraph.Details.CreateOutStream(OutStr, TEXTENCODING::UTF8);
        GetKpiDetails(OutStr);

        ActivityLog.LogActivity(O365SalesGraph, ActivityLog.Status::Success, C2GraphStatusTxt, C2GraphUpdateActionTxt, '');
        if O365SalesGraph.Insert(true) then;

        UnregisterTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, ConnectionId);
    end;

    local procedure GetKpiDetails(var Details: OutStream)
    var
        GLSetup: Record "General Ledger Setup";
        JSONManagement: Codeunit "JSON Management";
        ResultJsonObject: DotNet JObject;
        SummaryJsonObject: DotNet JObject;
    begin
        if GLSetup.Get then;

        ResultJsonObject := ResultJsonObject.JObject;
        SummaryJsonObject := SummaryJsonObject.JObject;

        JSONManagement.AddJPropertyToJObject(
          SummaryJsonObject, '@odata.type', '#Microsoft.Griffin.SmallBusiness.SbGraph.Core.InvoiceOverviewKpiV1');
        JSONManagement.AddJPropertyToJObject(SummaryJsonObject, 'monthlySalesTotalAmount', InvoicedThisMonth);
        JSONManagement.AddJPropertyToJObject(SummaryJsonObject, 'yearlySalesTotalAmount', InvoicedYearToDate);
        JSONManagement.AddJPropertyToJObject(SummaryJsonObject, 'outstandingSalesTotalAmount', OutstandingAmount);
        JSONManagement.AddJPropertyToJObject(SummaryJsonObject, 'overdueSalesTotalAmount', OverdueAmount);
        JSONManagement.AddJPropertyToJObject(SummaryJsonObject, 'currencyCode', GLSetup."Local Currency Symbol");

        JSONManagement.AddJObjectToJObject(ResultJsonObject, 'summary', SummaryJsonObject);

        Details.Write(ResultJsonObject.ToString);
    end;

    local procedure GetInactivityDetails(var Details: OutStream)
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        JSONManagement: Codeunit "JSON Management";
        ResultJsonObject: DotNet JObject;
    begin
        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        ResultJsonObject := ResultJsonObject.JObject;

        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'duration', O365C2GraphEventSettings."Inv. Inactivity Duration (Day)");
        Details.Write(ResultJsonObject.ToString);
    end;

    local procedure GetOverdueDetails(DocNo: Code[20]; var Details: OutStream): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        Contact: Record Contact;
        Currency: Record Currency;
        User: Record User;
        JSONManagement: Codeunit "JSON Management";
        ResultJsonObject: DotNet JObject;
        ContactFirstName: Text;
    begin
        SalesInvoiceHeader.Get(DocNo);
        SalesInvoiceHeader.CalcFields("Remaining Amount", "Amount Including VAT");

        if SalesInvoiceHeader."Remaining Amount" <= 0 then
            exit(false);

        if Customer.Get(SalesInvoiceHeader."Sell-to Customer No.") then
            if Contact.Get(Customer."Primary Contact No.") then;

        if User.Get(UserSecurityId) then;

        if (Contact."First Name" = '') and (Contact.Surname = '') then
            ContactFirstName := Customer.Name
        else
            ContactFirstName := Contact."First Name";

        ResultJsonObject := ResultJsonObject.JObject;

        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerFirstName', ContactFirstName);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerLastName', Contact.Surname);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerEmailAddress', Customer."E-Mail");
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'companyName', Customer.Name);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'amount', SalesInvoiceHeader."Amount Including VAT");
        JSONManagement.AddJPropertyToJObject(
          ResultJsonObject, 'currencyCode', Currency.ResolveGLCurrencySymbol(SalesInvoiceHeader."Currency Code"));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'description', StrSubstNo(InvoiceDescTxt, SalesInvoiceHeader."No."));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'externalInvoiceId', SalesInvoiceHeader."No.");
        JSONManagement.AddJPropertyToJObject(
          ResultJsonObject, 'sentDateTime', Format(CreateDateTime(SalesInvoiceHeader."Posting Date", 0T), 0, 9));
        JSONManagement.AddJPropertyToJObject(
          ResultJsonObject, 'dueDateTime', Format(CreateDateTime(SalesInvoiceHeader."Due Date", 0T), 0, 9));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'employeeName', User."Full Name");
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'state', 'Overdue');

        Details.Write(ResultJsonObject.ToString);

        exit(true);
    end;

    local procedure GetDraftDetails(var Details: OutStream): Boolean
    var
        SalesHeader: Record "Sales Header";
        JSONManagement: Codeunit "JSON Management";
        ResultJsonObject: DotNet JObject;
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        if SalesHeader.IsEmpty then
            exit(false);

        ResultJsonObject := ResultJsonObject.JObject;

        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'totalDrafts', SalesHeader.Count);

        Details.Write(ResultJsonObject.ToString);

        exit(true);
    end;

    local procedure GetInvoiceDetails(DocNo: Code[20]; var Details: OutStream; InvoiceState: Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        Contact: Record Contact;
        User: Record User;
        Currency: Record Currency;
        JSONManagement: Codeunit "JSON Management";
        ResultJsonObject: DotNet JObject;
        ContactFirstName: Text;
    begin
        SalesInvoiceHeader.Get(DocNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        if Customer.Get(SalesInvoiceHeader."Sell-to Customer No.") then
            if Contact.Get(Customer."Primary Contact No.") then;

        if User.Get(UserSecurityId) then;

        if (Contact."First Name" = '') and (Contact.Surname = '') then
            ContactFirstName := Customer.Name
        else
            ContactFirstName := Contact."First Name";

        ResultJsonObject := ResultJsonObject.JObject;

        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerFirstName', ContactFirstName);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerLastName', Contact.Surname);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerEmailAddress', Customer."E-Mail");
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'companyName', Customer.Name);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'amount', SalesInvoiceHeader."Amount Including VAT");
        JSONManagement.AddJPropertyToJObject(
          ResultJsonObject, 'currencyCode', Currency.ResolveGLCurrencySymbol(SalesInvoiceHeader."Currency Code"));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'description', StrSubstNo(InvoiceDescTxt, SalesInvoiceHeader."No."));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'externalInvoiceId', SalesInvoiceHeader."No.");
        JSONManagement.AddJPropertyToJObject(
          ResultJsonObject, 'sentDateTime', Format(CreateDateTime(SalesInvoiceHeader."Posting Date", 0T), 0, 9));
        JSONManagement.AddJPropertyToJObject(
          ResultJsonObject, 'dueDateTime', Format(CreateDateTime(SalesInvoiceHeader."Due Date", 0T), 0, 9));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'employeeName', User."Full Name");
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'state', InvoiceState);

        Details.Write(ResultJsonObject.ToString);
    end;

    local procedure GetPaidInvoiceDetails(DocNo: Code[20]; Details: OutStream): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        Contact: Record Contact;
        User: Record User;
        Currency: Record Currency;
        JSONManagement: Codeunit "JSON Management";
        ResultJsonObject: DotNet JObject;
        ContactFirstName: Text;
    begin
        SalesInvoiceHeader.Get(DocNo);
        SalesInvoiceHeader.CalcFields("Remaining Amount", "Amount Including VAT");

        if SalesInvoiceHeader."Remaining Amount" > 0 then
            exit(false);

        if Customer.Get(SalesInvoiceHeader."Sell-to Customer No.") then
            if Contact.Get(Customer."Primary Contact No.") then;

        if User.Get(UserSecurityId) then;

        if (Contact."First Name" = '') and (Contact.Surname = '') then
            ContactFirstName := Customer.Name
        else
            ContactFirstName := Contact."First Name";

        ResultJsonObject := ResultJsonObject.JObject;

        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerFirstName', ContactFirstName);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerLastName', Contact.Surname);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerEmailAddress', Customer."E-Mail");
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'companyName', Customer.Name);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'amount', SalesInvoiceHeader."Amount Including VAT");
        JSONManagement.AddJPropertyToJObject(
          ResultJsonObject, 'currencyCode', Currency.ResolveGLCurrencySymbol(SalesInvoiceHeader."Currency Code"));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'description', StrSubstNo(InvoiceDescTxt, SalesInvoiceHeader."No."));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'externalInvoiceId', SalesInvoiceHeader."No.");
        JSONManagement.AddJPropertyToJObject(
          ResultJsonObject, 'sentDateTime', Format(CreateDateTime(SalesInvoiceHeader."Posting Date", 0T), 0, 9));
        JSONManagement.AddJPropertyToJObject(
          ResultJsonObject, 'dueDateTime', Format(CreateDateTime(SalesInvoiceHeader."Due Date", 0T), 0, 9));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'employeeName', User."Full Name");
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'state', 'Paid');

        Details.Write(ResultJsonObject.ToString);

        exit(true);
    end;

    local procedure GetEstimateDetails(DocNo: Code[20]; var Details: OutStream; EstimateState: Text)
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Contact: Record Contact;
        User: Record User;
        Currency: Record Currency;
        JSONManagement: Codeunit "JSON Management";
        ResultJsonObject: DotNet JObject;
        ContactFirstName: Text;
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Quote, DocNo);
        SalesHeader.CalcFields("Amount Including VAT");

        if User.Get(UserSecurityId) then;

        if Customer.Get(SalesHeader."Sell-to Customer No.") then
            if Contact.Get(Customer."Primary Contact No.") then;

        if (Contact."First Name" = '') and (Contact.Surname = '') then
            ContactFirstName := Customer.Name
        else
            ContactFirstName := Contact."First Name";

        ResultJsonObject := ResultJsonObject.JObject;

        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerFirstName', ContactFirstName);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerLastName', Contact.Surname);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerEmailAddress', Customer."E-Mail");
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'companyName', Customer.Name);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'amount', SalesHeader."Amount Including VAT");
        JSONManagement.AddJPropertyToJObject(
          ResultJsonObject, 'currencyCode', Currency.ResolveGLCurrencySymbol(SalesHeader."Currency Code"));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'description', StrSubstNo(EstimateDescTxt, SalesHeader."No."));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'externalInvoiceId', SalesHeader."No.");
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'sentDateTime', Format(SalesHeader."Quote Sent to Customer", 0, 9));
        JSONManagement.AddJPropertyToJObject(
          ResultJsonObject, 'dueDateTime', Format(CreateDateTime(SalesHeader."Quote Valid Until Date", 0T), 0, 9));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'employeeName', User."Full Name");
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'state', EstimateState);

        Details.Write(ResultJsonObject.ToString);
    end;

    local procedure GetAcceptedEstimateDetails(DocNo: Code[20]; Details: OutStream): Boolean
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Contact: Record Contact;
        User: Record User;
        Currency: Record Currency;
        JSONManagement: Codeunit "JSON Management";
        ResultJsonObject: DotNet JObject;
        ContactFirstName: Text;
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Quote, DocNo);
        SalesHeader.CalcFields("Amount Including VAT");

        if Customer.Get(SalesHeader."Sell-to Customer No.") then
            if Contact.Get(Customer."Primary Contact No.") then;

        if User.Get(UserSecurityId) then;

        if (Contact."First Name" = '') and (Contact.Surname = '') then
            ContactFirstName := Customer.Name
        else
            ContactFirstName := Contact."First Name";

        ResultJsonObject := ResultJsonObject.JObject;

        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerFirstName', ContactFirstName);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerLastName', Contact.Surname);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'customerEmailAddress', Customer."E-Mail");
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'companyName', Customer.Name);
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'amount', SalesHeader."Amount Including VAT");
        JSONManagement.AddJPropertyToJObject(
          ResultJsonObject, 'currencyCode', Currency.ResolveGLCurrencySymbol(SalesHeader."Currency Code"));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'description', StrSubstNo(EstimateDescTxt, SalesHeader."No."));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'externalInvoiceId', SalesHeader."No.");
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'sentDateTime', Format(SalesHeader."Quote Sent to Customer", 0, 9));
        JSONManagement.AddJPropertyToJObject(
          ResultJsonObject, 'dueDateTime', Format(CreateDateTime(SalesHeader."Quote Valid Until Date", 0T), 0, 9));
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'employeeName', User."Full Name");
        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'state', 'Accepted');

        Details.Write(ResultJsonObject.ToString);

        exit(true);
    end;

    local procedure GetExpiringEstimateDetails(var Details: OutStream): Boolean
    var
        SalesHeader: Record "Sales Header";
        JSONManagement: Codeunit "JSON Management";
        ResultJsonObject: DotNet JObject;
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.SetRange("Quote Valid Until Date", Today, CalcDate('<1W>', Today));
        SalesHeader.SetRange("Quote Accepted", false);
        if SalesHeader.IsEmpty then
            exit(false);

        ResultJsonObject := ResultJsonObject.JObject;

        JSONManagement.AddJPropertyToJObject(ResultJsonObject, 'totalExpiringEstimates', SalesHeader.Count);

        Details.Write(ResultJsonObject.ToString);

        exit(true);
    end;

    local procedure OutstandingAmount(): Decimal
    var
        O365SalesCue: Record "O365 Sales Cue";
        DummyText: Text;
    begin
        O365SalesCue.OnOpenActivitiesPage(DummyText);
        O365SalesCue.CalcFields("Sales Invoices Outstanding");
        exit(O365SalesCue."Sales Invoices Outstanding");
    end;

    local procedure OverdueAmount(): Decimal
    var
        O365SalesCue: Record "O365 Sales Cue";
        DummyText: Text;
    begin
        O365SalesCue.OnOpenActivitiesPage(DummyText);
        O365SalesCue.CalcFields("Sales Invoices Overdue");
        exit(O365SalesCue."Sales Invoices Overdue");
    end;

    local procedure InvoicedYearToDate(): Decimal
    var
        O365SalesCue: Record "O365 Sales Cue";
        DummyText: Text;
    begin
        O365SalesCue.OnOpenActivitiesPage(DummyText);
        O365SalesCue.CalcFields("Invoiced YTD");
        exit(O365SalesCue."Invoiced YTD");
    end;

    local procedure InvoicedThisMonth(): Decimal
    var
        O365SalesCue: Record "O365 Sales Cue";
        DummyText: Text;
    begin
        O365SalesCue.OnOpenActivitiesPage(DummyText);
        O365SalesCue.CalcFields("Invoiced CM");
        exit(O365SalesCue."Invoiced CM");
    end;

    local procedure GetConnectionString(): Text
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
    begin
        if GraphConnectionSetup.IsS2SAuthenticationEnabled then
            exit(StrSubstNo(S2SConnectionStrTemplateTxt, GetGraphUrl, ActivityRolesTxt));

        exit(StrSubstNo(UserConnectionStrTemplateTxt, GetGraphUrl));
    end;

    local procedure GetGraphUrl(): Text
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        if O365SalesInitialSetup.Get then
            exit(O365SalesInitialSetup."C2Graph Endpoint");

        Error(MissingEndpointErr);
    end;

    local procedure GetGraphIdForContactFromInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"): Text[250]
    var
        Customer: Record Customer;
        Contact: Record Contact;
        GraphIntegrationRecord: Record "Graph Integration Record";
        ContactBusinessRelation: Record "Contact Business Relation";
        GraphContactId: Text[250];
    begin
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");
        if ContactBusinessRelation.FindFirst then
            if Contact.Get(ContactBusinessRelation."Contact No.") then
                if GraphIntegrationRecord.FindIDFromRecordID(Contact.RecordId, GraphContactId) then
                    exit(GraphContactId);

        exit('');
    end;

    local procedure GetGraphIdForContactFromSalesDoc(SalesHeader: Record "Sales Header"): Text[250]
    var
        Customer: Record Customer;
        Contact: Record Contact;
        GraphIntegrationRecord: Record "Graph Integration Record";
        ContactBusinessRelation: Record "Contact Business Relation";
        GraphContactId: Text[250];
    begin
        Customer.Get(SalesHeader."Sell-to Customer No.");

        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");
        if ContactBusinessRelation.FindFirst then
            if Contact.Get(ContactBusinessRelation."Contact No.") then
                if GraphIntegrationRecord.FindIDFromRecordID(Contact.RecordId, GraphContactId) then
                    exit(GraphContactId);

        exit('');
    end;

    local procedure GetIdsIfValidInvoice(InvoiceNo: Code[20]; var ContactGraphId: Text[250]; var ConnectionId: Text; var SalesInvoiceHeaderId: Text[60]): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if not SalesInvoiceHeader.Get(InvoiceNo) then
            exit(false);

        if IsNullGuid(SalesInvoiceHeader.Id) then
            exit(false);

        ContactGraphId := GetGraphIdForContactFromInvoice(SalesInvoiceHeader);
        ConnectionId := Format(CreateGuid);
        SalesInvoiceHeaderId := Format(SalesInvoiceHeader.Id);

        exit(true);
    end;

    local procedure GetIdsIfValidEstimate(EstimateNo: Code[20]; var ContactGraphId: Text[250]; var ConnectionId: Text; var SalesHeaderId: Text[60]): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        if not SalesHeader.Get(SalesHeader."Document Type"::Quote, EstimateNo) then
            exit(false);

        if IsNullGuid(SalesHeader.Id) then
            exit(false);

        ContactGraphId := GetGraphIdForContactFromSalesDoc(SalesHeader);
        ConnectionId := Format(CreateGuid);
        SalesHeaderId := Format(SalesHeader.Id);

        exit(true);
    end;

    local procedure InitializeO365SalesGraphForDocuments(var O365SalesGraph: Record "O365 Sales Graph"; Type: Text[60]; InvoiceId: Text[60]; ContactId: Text[250])
    begin
        InitializeO365SalesGraph(O365SalesGraph, Type);
        O365SalesGraph.InvoiceId := InvoiceId;
        O365SalesGraph.ContactId := ContactId;
    end;

    local procedure InitializeO365SalesGraphForKPIs(var O365SalesGraph: Record "O365 Sales Graph"; Type: Text[60])
    begin
        O365SalesGraph.Initialize;
        O365SalesGraph.Type := Type;
        O365SalesGraph.Kind := KpiKindTxt;
    end;

    local procedure InitializeO365SalesGraph(var O365SalesGraph: Record "O365 Sales Graph"; Type: Text[60])
    begin
        O365SalesGraph.Initialize;
        O365SalesGraph.Type := Type;
        O365SalesGraph.Kind := ActivityKindTxt;
        O365SalesGraph.SetEmployeeIdToCurrentUser;
    end;
}

