page 2803 "Native - Contact"
{
    Caption = 'Native - Contact';
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = Contact;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'number', Locked = true;
                }
                field(xrmId; "Xrm Id")
                {
                    ApplicationArea = All;
                    Caption = 'xrmId', Locked = true;
                }
                field(displayName; Name)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                }
                field(phoneNumber; "Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'phoneNumber', Locked = true;
                }
                field(email; "E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'email', Locked = true;
                }
                field(customerId; CustomerID)
                {
                    ApplicationArea = All;
                    Caption = 'customerId', Locked = true;
                    ToolTip = 'Specifies the Customer Id.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ClearCalculatedFields;
        SetXrmID;
        SetCustomerID;
    end;

    trigger OnOpenPage()
    begin
        SetFilterForGETStatement;
        SelectLatestVersion;
    end;

    var
        CustomerID: Guid;
        CannotCreateCustomerErr: Label 'Cannot create a customer from the contact.';

    local procedure SetXrmID()
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationRecord: Record "Integration Record";
        GraphID: Text[250];
    begin
        if not GraphIntegrationRecord.FindIDFromRecordID(RecordId, GraphID) then
            exit;

        IntegrationRecord.SetRange("Record ID", RecordId);
        if not IntegrationRecord.FindFirst then
            exit;

        if not GraphIntegrationRecord.Get(GraphID, IntegrationRecord."Integration ID") then
            exit;

        "Xrm Id" := GraphIntegrationRecord.XRMId;
    end;

    local procedure SetCustomerID()
    var
        Customer: Record Customer;
        GraphIntContact: Codeunit "Graph Int. - Contact";
    begin
        if not GraphIntContact.FindCustomerFromContact(Customer, Rec) then
            exit;

        CustomerID := Customer.Id;
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(CustomerID);
        Clear("Xrm Id");
    end;

    local procedure SetFilterForGETStatement()
    var
        Contact: Record Contact;
        GraphIntContact: Codeunit "Graph Int. - Contact";
        xrmIDFilter: Text[250];
    begin
        xrmIDFilter := CopyStr(GetFilter("Xrm Id"), 1, MaxStrLen(xrmIDFilter));
        if xrmIDFilter = '' then
            exit;

        if not GraphIntContact.FindContactFromGraphId(xrmIDFilter, Contact) then
            SetFilter("No.", '<>*')
        else
            SetRange("No.", Contact."No.");

        SetRange("Xrm Id");
    end;

    [ServiceEnabled]
    procedure MakeCustomer(var ActionContext: DotNet WebServiceActionContext)
    var
        Customer: Record Customer;
        GraphIntContact: Codeunit "Graph Int. - Contact";
    begin
        if not IsNullGuid(CustomerID) then begin
            Customer.SetRange(Id, CustomerID);
            Customer.FindFirst;
        end else
            if not GraphIntContact.FindOrCreateCustomerFromGraphContactSafe("Xrm Id", Customer, Rec) then
                Error(CannotCreateCustomerErr);

        SetActionResponse(ActionContext, Customer);
    end;

    local procedure SetActionResponse(var ActionContext: DotNet WebServiceActionContext; var Customer: Record Customer)
    var
        ODataActionManagement: Codeunit "OData Action Management";
    begin
        ODataActionManagement.AddKey(Customer.FieldNo(Id), Customer.Id);
        ODataActionManagement.SetDeleteResponseLocation(ActionContext, PAGE::"Native - Customer Entity")
    end;
}

